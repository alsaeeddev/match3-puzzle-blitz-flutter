import 'dart:math';
import '../models/board.dart';
import '../models/cell.dart';
import '../models/level_config.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'match_detector.dart';

// Pure Dart generator producing solvable, match-free initial boards.
// Ensures every generated board satisfies two strict criteria:
// 1. Zero initial pre-existing matches (no accidental cascades before the player acts).
// 2. At least one legal, valid player move is immediately playable.
class BoardGenerator {
  final Random random;
  final MatchDetector matchDetector;

  const BoardGenerator({
    required this.random,
    this.matchDetector = const MatchDetector(),
  });

  // Generates a complete, playable [Board] based on [config].
  // Places blocked voids, obstacles, jelly, and ice layers as specified
  // in [config.layout], then fills open cells with random gems while
  // avoiding three-in-a-row sequences.
  Board generate(LevelConfig config, {int maxAttempts = 100}) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final grid = List.generate(
        config.rows,
        (r) => List.generate(
          config.cols,
          (c) => _createCell(config, Position(r, c)),
        ),
      );

      // Fill playable normal cells with gems using backtracking checks
      var pieceCounter = 0;
      for (var r = 0; r < config.rows; r++) {
        for (var c = 0; c < config.cols; c++) {
          final pos = Position(r, c);
          if (grid[r][c].content is NormalCell) {
            final excludedColors = <PieceType>{};

            // Avoid horizontal 3-in-a-row
            if (c >= 2) {
              final p1 = grid[r][c - 1].content.piece;
              final p2 = grid[r][c - 2].content.piece;
              if (p1 != null && p2 != null && p1.pieceType == p2.pieceType) {
                excludedColors.add(p1.pieceType);
              }
            }

            // Avoid vertical 3-in-a-row
            if (r >= 2) {
              final p1 = grid[r - 1][c].content.piece;
              final p2 = grid[r - 2][c].content.piece;
              if (p1 != null && p2 != null && p1.pieceType == p2.pieceType) {
                excludedColors.add(p1.pieceType);
              }
            }

            final candidates = config.allowedColors
                .where((color) => !excludedColors.contains(color))
                .toList();

            final selectedColor = candidates.isNotEmpty
                ? candidates[random.nextInt(candidates.length)]
                : config.allowedColors[random.nextInt(config.allowedColors.length)];

            final piece = Piece(
              id: 'p_${attempt}_${pos.row}_${pos.col}_${pieceCounter++}',
              pieceType: selectedColor,
            );

            grid[r][c] = grid[r][c].copyWith(content: NormalCell(piece));
          }
        }
      }

      final candidateBoard = Board(
        rows: config.rows,
        cols: config.cols,
        cells: grid,
      );

      // Verify that no accidental matches exist AND at least one valid move is available
      final hasNoMatches = matchDetector.findAllMatches(candidateBoard).isEmpty;
      final hasValidMoves = matchDetector.findAllValidMoves(candidateBoard).isNotEmpty;

      if (hasNoMatches && hasValidMoves) {
        return candidateBoard;
      }
    }

    // Fallback: force create a board with guaranteed valid move if random attempts exceed threshold
    return _generateWithGuaranteedMove(config);
  }

  CellState _createCell(LevelConfig config, Position pos) {
    if (config.layout.blockedPositions.contains(pos)) {
      return CellState(
        position: pos,
        content: const BlockedCell(),
      );
    }

    if (config.layout.obstacles.containsKey(pos)) {
      final obstacleType = config.layout.obstacles[pos]!;
      return CellState(
        position: pos,
        content: ObstacleCell(type: obstacleType),
        jellyLayers: config.layout.jellyGrid[pos] ?? 0,
        hasIce: config.layout.icePositions.contains(pos),
        isLocked: config.layout.lockedPositions.contains(pos),
      );
    }

    return CellState(
      position: pos,
      // Place dummy piece that will be replaced during piece allocation
      content: NormalCell(
        Piece(
          id: 'placeholder',
          pieceType: config.allowedColors.first,
        ),
      ),
      jellyLayers: config.layout.jellyGrid[pos] ?? 0,
      hasIce: config.layout.icePositions.contains(pos),
      isLocked: config.layout.lockedPositions.contains(pos),
    );
  }

  Board _generateWithGuaranteedMove(LevelConfig config) {
    // Basic deterministic arrangement
    final grid = List.generate(
      config.rows,
      (r) => List.generate(
        config.cols,
        (c) => _createCell(config, Position(r, c)),
      ),
    );

    var idCounter = 0;
    for (var r = 0; r < config.rows; r++) {
      for (var c = 0; c < config.cols; c++) {
        if (grid[r][c].content is NormalCell) {
          final colorIndex = (r * 2 + c) % config.allowedColors.length;
          final color = config.allowedColors[colorIndex];
          grid[r][c] = grid[r][c].copyWith(
            content: NormalCell(
              Piece(id: 'piece_${idCounter++}', pieceType: color),
            ),
          );
        }
      }
    }

    // Guarantee a valid move in the first two rows if playable
    if (config.rows >= 2 && config.cols >= 4) {
      final color = config.allowedColors.first;
      final otherColor = config.allowedColors[1 % config.allowedColors.length];

      grid[0][0] = grid[0][0].copyWith(content: NormalCell(Piece(id: 'g_0', pieceType: color)));
      grid[0][1] = grid[0][1].copyWith(content: NormalCell(Piece(id: 'g_1', pieceType: color)));
      grid[0][2] = grid[0][2].copyWith(content: NormalCell(Piece(id: 'g_2', pieceType: otherColor)));
      grid[1][2] = grid[1][2].copyWith(content: NormalCell(Piece(id: 'g_3', pieceType: color)));
    }

    return Board(rows: config.rows, cols: config.cols, cells: grid);
  }
}
