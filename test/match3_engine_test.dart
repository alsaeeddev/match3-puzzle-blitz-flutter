import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3_game/features/game/domain/engine/board_generator.dart';
import 'package:match3_game/features/game/domain/engine/cascade_engine.dart';
import 'package:match3_game/features/game/domain/engine/deadlock_detector.dart';
import 'package:match3_game/features/game/domain/engine/gravity_engine.dart';
import 'package:match3_game/features/game/domain/engine/hint_engine.dart';
import 'package:match3_game/features/game/domain/engine/match_detector.dart';
import 'package:match3_game/features/game/domain/engine/special_combos.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/domain/models/game_state.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/game/domain/scoring/score_calculator.dart';

void main() {
  group('Match-3 Engine Tests', () {
    const matchDetector = MatchDetector();
    const specialCombos = SpecialCombos();
    const gravityEngine = GravityEngine();
    const deadlockDetector = DeadlockDetector(matchDetector);
    const scoreCalculator = ScoreCalculator();
    final random = Random(42);

    final generator = BoardGenerator(random: random, matchDetector: matchDetector);
    final cascadeEngine = CascadeEngine(
      matchDetector: matchDetector,
      specialCombos: specialCombos,
      gravityEngine: gravityEngine,
      deadlockDetector: deadlockDetector,
      scoreCalculator: scoreCalculator,
      random: random,
    );

    const levelConfig = LevelConfig(
      id: 1,
      name: 'Test Level 1',
      rows: 8,
      cols: 8,
      maxMoves: 25,
      goals: [TargetScore(1000)],
    );

    test('BoardGenerator generates valid board with no matches and at least one valid move', () {
      final board = generator.generate(levelConfig);
      expect(matchDetector.findAllMatches(board), isEmpty);
      expect(matchDetector.findAllValidMoves(board), isNotEmpty);
    });

    test('HintEngine finds best available hint', () {
      final board = generator.generate(levelConfig);
      const hintEngine = HintEngine(matchDetector);
      final hint = hintEngine.findBestHint(board);
      expect(hint, isNotNull);
      expect(matchDetector.isValidSwap(board, hint!.$1, hint.$2), isTrue);
    });

    test('CascadeEngine processes valid swap and increments score', () {
      final board = generator.generate(levelConfig);
      const hintEngine = HintEngine(matchDetector);
      final hint = hintEngine.findBestHint(board)!;

      final initialState = GameState.initial(levelConfig: levelConfig, board: board);
      final (nextState, events) = cascadeEngine.processSwap(initialState, hint.$1, hint.$2);

      expect(nextState.movesLeft, equals(initialState.movesLeft - 1));
      expect(events.first, isA<SwapEvent>());
      expect(events.whereType<ClearEvent>(), isNotEmpty);
      expect(nextState.score, greaterThan(0));
    });

    test('CascadeEngine rejects invalid swap', () {
      final board = generator.generate(levelConfig);
      final moves = matchDetector.findAllValidMoves(board).toSet();

      // Find an adjacent pair that is NOT a valid move
      final invalidSwap = (
        from: board.cells[0][0].position,
        to: board.cells[0][1].position,
      );

      if (!moves.contains((invalidSwap.from, invalidSwap.to)) &&
          !moves.contains((invalidSwap.to, invalidSwap.from))) {
        final state = GameState.initial(levelConfig: levelConfig, board: board);
        final (nextState, events) = cascadeEngine.processSwap(state, invalidSwap.from, invalidSwap.to);
        expect(events.single, isA<InvalidSwapEvent>());
        expect(nextState.movesLeft, equals(state.movesLeft));
        expect(nextState.score, equals(0));
      }
    });

    test('CascadeEngine processes Hammer booster on targeted cell', () {
      final board = generator.generate(levelConfig);
      final initialState = GameState.initial(
        levelConfig: levelConfig.copyWith(
          availableBoosters: {BoosterType.hammer: 1},
        ),
        board: board,
      );

      final targetPos = board.cells[2][2].position;
      final (nextState, events) = cascadeEngine.processBooster(
        initialState,
        BoosterType.hammer,
        targetPos,
      );

      expect(events.whereType<BoosterUsedEvent>(), isNotEmpty);
      expect(events.whereType<ClearEvent>(), isNotEmpty);
      expect(nextState.boosterInventory[BoosterType.hammer], equals(0));
    });

    test('GameState correctly manages activeBooster arming and disarming', () {
      final board = generator.generate(levelConfig);
      var state = GameState.initial(levelConfig: levelConfig, board: board);
      expect(state.activeBooster, isNull);

      // Arm hammer
      state = state.copyWith(activeBooster: BoosterType.hammer);
      expect(state.activeBooster, equals(BoosterType.hammer));

      // Disarm hammer
      state = state.copyWith(clearActiveBooster: true);
      expect(state.activeBooster, isNull);
    });
  });
}
