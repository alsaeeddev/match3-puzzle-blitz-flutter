import 'dart:math';
import 'package:match3_game/core/constants/game_config.dart';
import '../models/board.dart';
import '../models/cell.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../scoring/score_calculator.dart';
import 'deadlock_detector.dart';
import 'gravity_engine.dart';
import 'match_detector.dart';
import 'special_combos.dart';

/// The central execution pipeline for Match-3 Blitz.
///
/// Coordinates player swaps, validations, special combinations, cascade loops,
/// gravity drops, board refills, scoring, booster activations, and win/loss checks.
class CascadeEngine {
  final MatchDetector matchDetector;
  final SpecialCombos specialCombos;
  final GravityEngine gravityEngine;
  final DeadlockDetector deadlockDetector;
  final ScoreCalculator scoreCalculator;
  final Random random;

  const CascadeEngine({
    required this.matchDetector,
    required this.specialCombos,
    required this.gravityEngine,
    required this.deadlockDetector,
    required this.scoreCalculator,
    required this.random,
  });

  /// Processes a player swap attempt between [from] and [to].
  ///
  /// Returns the updated [GameState] and an ordered list of all [GameEvent]s
  /// produced across the entire resulting cascade cycle.
  (GameState, List<GameEvent>) processSwap(
    GameState state,
    Position from,
    Position to,
  ) {
    if (state.isGameOver || state.movesLeft <= 0) {
      return (state, const []);
    }

    // 1. Validate swap
    if (!matchDetector.isValidSwap(state.board, from, to)) {
      return (state, [InvalidSwapEvent(from, to)]);
    }

    final events = <GameEvent>[SwapEvent(from, to)];
    final currentMovesLeft = state.movesLeft - 1;
    var currentBoard = state.board.swapPieces(from, to);
    var currentScore = state.score;
    var currentProgress = Map<String, int>.from(state.goalProgress);

    final pieceFrom = state.board.pieceAt(from);
    final pieceTo = state.board.pieceAt(to);

    // 2. Handle Special Combos (e.g. ColorBomb+ColorBomb, Striped+Wrapped, etc.)
    if (pieceFrom != null &&
        pieceTo != null &&
        specialCombos.isSpecialCombo(pieceFrom.specialType, pieceTo.specialType)) {
      final affected = specialCombos.getAffectedPositions(
        currentBoard,
        from,
        to,
        pieceFrom.specialType,
        pieceTo.specialType,
      );

      final clearedPieces = <Piece>[];
      var clearedJellyCount = 0;

      for (final pos in affected) {
        final cell = currentBoard.cellAt(pos);
        if (cell.content.piece != null) {
          clearedPieces.add(cell.content.piece!);
        }
        if (cell.hasJelly) {
          clearedJellyCount++;
          events.add(ObstacleDamageEvent(pos, 1));
        }

        currentBoard = currentBoard.updateCell(
          pos,
          (c) => c.copyWith(
            content: const EmptyCell(),
            jellyLayers: (c.jellyLayers - 1).clamp(0, 2),
          ),
        );
      }

      events.add(ClearEvent(affected.toList()));
      currentScore += affected.length * 60 * 2;

      currentProgress = scoreCalculator.updateGoalProgress(
        state.copyWith(score: currentScore, goalProgress: currentProgress),
        clearedPositions: affected.toList(),
        clearedPieces: clearedPieces,
        clearedJellyLayers: clearedJellyCount,
      );

      // Apply initial gravity and refill following special combo
      final (boardAfterGravity, gravityEvent) =
          gravityEngine.applyGravity(currentBoard);
      currentBoard = boardAfterGravity;
      if (gravityEvent.moves.isNotEmpty) {
        events.add(gravityEvent);
      }

      final (boardAfterRefill, refillEvent) =
          _refillEmptyCells(currentBoard, state.levelConfig.allowedColors);
      currentBoard = boardAfterRefill;
      if (refillEvent.pieces.isNotEmpty) {
        events.add(refillEvent);
      }
    }

    // 3. Cascade Loop (Iterative match detection, clears, gravity, and refills)
    final cascadeResult = _runCascadeLoop(
      state: state,
      currentBoard: currentBoard,
      currentScore: currentScore,
      currentProgress: currentProgress,
      events: events,
      from: from,
      to: to,
    );
    currentBoard = cascadeResult.$1;
    currentScore = cascadeResult.$2;
    currentProgress = cascadeResult.$3;

    // 4. Post-cascade win/loss and deadlock resolution
    return _finalizeState(
      baseState: state,
      currentBoard: currentBoard,
      currentScore: currentScore,
      currentMovesLeft: currentMovesLeft,
      currentProgress: currentProgress,
      events: events,
    );
  }

  /// Activates an in-game booster (Hammer, Shuffle, Extra Moves, Color Swap).
  (GameState, List<GameEvent>) processBooster(
    GameState state,
    BoosterType booster,
    Position? target,
  ) {
    final count = state.boosterInventory[booster] ?? 0;
    if (state.isGameOver) {
      return (state.copyWith(status: state.status), const []);
    }

    final newInventory = Map<BoosterType, int>.from(state.boosterInventory);
    if (count > 0) {
      newInventory[booster] = count - 1;
    }

    var currentBoard = state.board;
    var currentScore = state.score;
    var currentProgress = Map<String, int>.from(state.goalProgress);
    var currentMovesLeft = state.movesLeft;
    final events = <GameEvent>[];

    switch (booster) {
      case BoosterType.hammer:
        if (target == null || !currentBoard.isValidPosition(target)) {
          return (state.copyWith(status: GameStatus.playing), const []);
        }
        events.add(BoosterUsedEvent(booster, [target]));
        events.add(ClearEvent([target]));

        final cell = currentBoard.cellAt(target);
        final clearedPieces = <Piece>[];
        if (cell.content.piece != null) {
          clearedPieces.add(cell.content.piece!);
        }
        final jellyDamaged = cell.hasJelly ? 1 : 0;
        if (jellyDamaged > 0) {
          events.add(ObstacleDamageEvent(target, 1));
        }

        currentBoard = currentBoard.updateCell(
          target,
          (c) => c.copyWith(
            content: const EmptyCell(),
            jellyLayers: (c.jellyLayers - 1).clamp(0, 2),
          ),
        );

        currentScore += GameConfig.basePieceScore;
        currentProgress = scoreCalculator.updateGoalProgress(
          state.copyWith(score: currentScore, goalProgress: currentProgress),
          clearedPositions: [target],
          clearedPieces: clearedPieces,
          clearedJellyLayers: jellyDamaged,
        );

        final (afterGravity, gEvent) = gravityEngine.applyGravity(currentBoard);
        currentBoard = afterGravity;
        if (gEvent.moves.isNotEmpty) events.add(gEvent);

        final (afterRefill, rEvent) =
            _refillEmptyCells(currentBoard, state.levelConfig.allowedColors);
        currentBoard = afterRefill;
        if (rEvent.pieces.isNotEmpty) events.add(rEvent);

        // Run any cascades triggered by gravity and refill
        final cascadeResult = _runCascadeLoop(
          state: state,
          currentBoard: currentBoard,
          currentScore: currentScore,
          currentProgress: currentProgress,
          events: events,
        );

        return _finalizeState(
          baseState: state,
          currentBoard: cascadeResult.$1,
          currentScore: cascadeResult.$2,
          currentMovesLeft: currentMovesLeft,
          currentProgress: cascadeResult.$3,
          events: events,
          boosterInventory: newInventory,
        );

      case BoosterType.shuffle:
        events.add(BoosterUsedEvent(booster, const []));
        final newBoard = deadlockDetector.shuffle(state.board, random);
        events.add(ShuffleEvent(newBoard));

        return (
          state.copyWith(
            board: newBoard,
            boosterInventory: newInventory,
            status: GameStatus.playing,
          ),
          events,
        );

      case BoosterType.plusFiveMoves:
        events.add(BoosterUsedEvent(booster, const []));
        return (
          state.copyWith(
            movesLeft: state.movesLeft + 5,
            boosterInventory: newInventory,
            status: GameStatus.playing,
          ),
          events,
        );

      case BoosterType.colorSwap:
        if (target == null || !currentBoard.isValidPosition(target)) {
          return (state.copyWith(status: GameStatus.playing), const []);
        }
        final piece = currentBoard.pieceAt(target);
        if (piece == null) {
          return (state.copyWith(status: GameStatus.playing), const []);
        }

        final otherColors = state.levelConfig.allowedColors
            .where((c) => c != piece.pieceType)
            .toList();
        final newColor = otherColors.isNotEmpty
            ? otherColors[random.nextInt(otherColors.length)]
            : piece.pieceType;
        final newPiece = piece.copyWith(pieceType: newColor);

        currentBoard = currentBoard.updateCell(
          target,
          (c) => c.copyWith(content: NormalCell(newPiece)),
        );
        events.add(BoosterUsedEvent(booster, [target]));

        final cascadeResult = _runCascadeLoop(
          state: state,
          currentBoard: currentBoard,
          currentScore: currentScore,
          currentProgress: currentProgress,
          events: events,
          preferSpawnPos: target,
        );

        return _finalizeState(
          baseState: state,
          currentBoard: cascadeResult.$1,
          currentScore: cascadeResult.$2,
          currentMovesLeft: currentMovesLeft,
          currentProgress: cascadeResult.$3,
          events: events,
          boosterInventory: newInventory,
        );
    }
  }

  (Board, int, Map<String, int>) _runCascadeLoop({
    required GameState state,
    required Board currentBoard,
    required int currentScore,
    required Map<String, int> currentProgress,
    required List<GameEvent> events,
    Position? preferSpawnPos,
    Position? from,
    Position? to,
  }) {
    var board = currentBoard;
    var score = currentScore;
    var progress = currentProgress;
    var cascadeLevel = 1;

    while (true) {
      final matches = matchDetector.findAllMatches(board);
      if (matches.isEmpty) break;

      final comboMult = scoreCalculator.comboMultiplier(cascadeLevel);
      if (cascadeLevel > 1) {
        events.add(ComboEvent(comboMult.toInt()));
      }

      final positionsToClear = <Position>{};
      final clearedPieces = <Piece>[];
      final specialsToSpawn = <Position, (PieceType, SpecialType)>{};
      var stepScore = 0;
      var stepJellyCleared = 0;

      for (final match in matches) {
        events.add(MatchEvent(match.positions));
        stepScore += (scoreCalculator.baseScore(match) * comboMult).toInt();

        final specialType = matchDetector.getSpecialTypeForMatch(match);
        if (specialType.isSpecial) {
          stepScore += scoreCalculator.specialBonus(specialType);
          final Position spawnPos;
          if (to != null && match.positions.contains(to)) {
            spawnPos = to;
          } else if (from != null && match.positions.contains(from)) {
            spawnPos = from;
          } else if (preferSpawnPos != null &&
              match.positions.contains(preferSpawnPos)) {
            spawnPos = preferSpawnPos;
          } else {
            spawnPos = match.centerPosition;
          }
          specialsToSpawn[spawnPos] = (match.pieceType, specialType);
        }

        for (final pos in match.positions) {
          positionsToClear.add(pos);
          final piece = board.pieceAt(pos);
          if (piece != null && piece.specialType.isSpecial) {
            final blast = specialCombos.getSingleSpecialAffectedPositions(
              board,
              pos,
              piece.specialType,
              targetColor: piece.pieceType,
            );
            positionsToClear.addAll(blast);
          }
        }
      }

      for (final pos in positionsToClear) {
        final cell = board.cellAt(pos);
        if (cell.content.piece != null) {
          clearedPieces.add(cell.content.piece!);
        }
        if (cell.hasJelly) {
          stepJellyCleared++;
          events.add(ObstacleDamageEvent(pos, 1));
        }

        if (specialsToSpawn.containsKey(pos)) {
          final (color, special) = specialsToSpawn[pos]!;
          final newSpecialPiece = Piece(
            id: 'special_${pos.row}_${pos.col}_$cascadeLevel',
            pieceType: color,
            specialType: special,
          );
          board = board.updateCell(
            pos,
            (c) => c.copyWith(
              content: NormalCell(newSpecialPiece),
              jellyLayers: (c.jellyLayers - 1).clamp(0, 2),
            ),
          );
          events.add(SpawnSpecialEvent(pos, special));
        } else {
          board = board.updateCell(
            pos,
            (c) => c.copyWith(
              content: const EmptyCell(),
              jellyLayers: (c.jellyLayers - 1).clamp(0, 2),
            ),
          );
        }
      }

      events.add(ClearEvent(positionsToClear.toList()));
      score += stepScore;

      progress = scoreCalculator.updateGoalProgress(
        state.copyWith(score: score, goalProgress: progress),
        clearedPositions: positionsToClear.toList(),
        clearedPieces: clearedPieces,
        clearedJellyLayers: stepJellyCleared,
      );

      final (boardAfterGravity, gravityEvent) =
          gravityEngine.applyGravity(board);
      board = boardAfterGravity;
      if (gravityEvent.moves.isNotEmpty) {
        events.add(gravityEvent);
      }

      final (boardAfterRefill, refillEvent) =
          _refillEmptyCells(board, state.levelConfig.allowedColors);
      board = boardAfterRefill;
      if (refillEvent.pieces.isNotEmpty) {
        events.add(refillEvent);
      }

      cascadeLevel++;
    }

    return (board, score, progress);
  }

  (GameState, List<GameEvent>) _finalizeState({
    required GameState baseState,
    required Board currentBoard,
    required int currentScore,
    required int currentMovesLeft,
    required Map<String, int> currentProgress,
    required List<GameEvent> events,
    Map<BoosterType, int>? boosterInventory,
  }) {
    var updatedState = baseState.copyWith(
      board: currentBoard,
      score: currentScore,
      movesLeft: currentMovesLeft,
      goalProgress: currentProgress,
      boosterInventory: boosterInventory ?? baseState.boosterInventory,
      status: GameStatus.playing,
    );

    if (updatedState.areAllGoalsMet()) {
      final bonus = scoreCalculator.calculateBonus(currentMovesLeft);
      final finalScore = currentScore + bonus;
      final stars = scoreCalculator.starRating(
        finalScore,
        baseState.levelConfig.starThresholds,
      );
      events.add(LevelWonEvent(stars, finalScore, currentMovesLeft));
      return (
        updatedState.copyWith(
          score: finalScore,
          status: GameStatus.won,
        ),
        events,
      );
    }

    if (currentMovesLeft <= 0) {
      events.add(const LevelLostEvent());
      return (
        updatedState.copyWith(status: GameStatus.lost),
        events,
      );
    }

    if (deadlockDetector.isDeadlock(currentBoard)) {
      currentBoard = deadlockDetector.shuffle(currentBoard, random);
      events.add(ShuffleEvent(currentBoard));
      updatedState = updatedState.copyWith(board: currentBoard);
    }

    return (updatedState, events);
  }

  (Board, RefillEvent) _refillEmptyCells(
    Board board,
    List<PieceType> allowedColors,
  ) {
    var grid = board.cells.map((r) => List<CellState>.from(r)).toList();
    final newPieces = <(Position, Piece)>[];
    var idCounter = 0;

    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final cell = grid[r][c];
        if (cell.content is EmptyCell && !cell.isLocked) {
          final randomColor = allowedColors[random.nextInt(allowedColors.length)];
          final piece = Piece(
            id: 'refill_${r}_${c}_${DateTime.now().microsecondsSinceEpoch}_${idCounter++}',
            pieceType: randomColor,
          );
          grid[r][c] = cell.copyWith(content: NormalCell(piece));
          newPieces.add((Position(r, c), piece));
        }
      }
    }

    final newBoard = Board(rows: board.rows, cols: board.cols, cells: grid);
    return (newBoard, RefillEvent(newPieces));
  }
}
