import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/constants/game_config.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/features/game/domain/engine/board_generator.dart';
import 'package:match3_game/features/game/domain/engine/cascade_engine.dart';
import 'package:match3_game/features/game/domain/engine/hint_engine.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/domain/models/game_state.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/game/domain/models/position.dart';
import 'package:match3_game/features/game/domain/repositories/game_repository.dart';
import 'package:match3_game/features/levels/presentation/providers/level_providers.dart';
import 'package:match3_game/services/analytics/analytics_service.dart';
import 'package:match3_game/services/audio/audio_service.dart';

/// Central game state controller executing player inputs, cascades, animations, and hints.
class GameNotifier extends Notifier<GameState> {
  final int levelId;

  final CascadeEngine? _cascadeEngineOverride;
  final BoardGenerator? _boardGeneratorOverride;
  final HintEngine? _hintEngineOverride;
  final AudioService? _audioServiceOverride;
  final AnalyticsService? _analyticsServiceOverride;
  final GameRepository? _gameRepositoryOverride;
  final LevelConfig? _levelConfigOverride;

  Timer? _hintTimer;
  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();

  GameNotifier(
    this.levelId, {
    CascadeEngine? cascadeEngine,
    BoardGenerator? boardGenerator,
    HintEngine? hintEngine,
    AudioService? audioService,
    AnalyticsService? analyticsService,
    GameRepository? gameRepository,
    LevelConfig? levelConfig,
  })  : _cascadeEngineOverride = cascadeEngine,
        _boardGeneratorOverride = boardGenerator,
        _hintEngineOverride = hintEngine,
        _audioServiceOverride = audioService,
        _analyticsServiceOverride = analyticsService,
        _gameRepositoryOverride = gameRepository,
        _levelConfigOverride = levelConfig;

  CascadeEngine get _cascadeEngine =>
      _cascadeEngineOverride ?? ref.read(cascadeEngineProvider);
  BoardGenerator get _boardGenerator =>
      _boardGeneratorOverride ?? ref.read(boardGeneratorProvider);
  HintEngine get _hintEngine =>
      _hintEngineOverride ?? ref.read(hintEngineProvider);
  AudioService get _audioService =>
      _audioServiceOverride ?? ref.read(audioServiceProvider);
  AnalyticsService get _analyticsService =>
      _analyticsServiceOverride ?? ref.read(analyticsServiceProvider);
  GameRepository get _gameRepository =>
      _gameRepositoryOverride ?? ref.read(gameRepositoryProvider);
  LevelConfig get _levelConfig =>
      _levelConfigOverride ?? ref.read(levelByIdProvider(levelId));

  /// Stream of emitted game cascade and animation events.
  Stream<GameEvent> get events => _eventController.stream;

  /// Currently armed booster awaiting cell target selection (e.g. Hammer).
  BoosterType? get activeBooster => state.activeBooster;

  @override
  GameState build() {
    ref.onDispose(() {
      _hintTimer?.cancel();
      _eventController.close();
    });

    final config = _levelConfig;
    final board = _boardGenerator.generate(config);
    final initial = GameState.initial(levelConfig: config, board: board);
    resetHintTimer();
    return initial;
  }

  /// Initializes a fresh game board for the given [config] and logs telemetry.
  void startLevel(LevelConfig config) {
    _hintTimer?.cancel();
    final board = _boardGenerator.generate(config);
    state = GameState.initial(levelConfig: config, board: board);
    _analyticsService.logLevelStart(config.id);
    resetHintTimer();
  }

  /// Handles cell selection via tap gesture (select, deselect, or swap).
  void selectPiece(Position pos) {
    if (!state.canInteract) return;
    resetHintTimer();

    // If an armed booster is awaiting a target cell:
    if (state.activeBooster != null) {
      final booster = state.activeBooster!;
      // NOTE: do NOT clear activeBooster here — useBooster will handle it,
      // and after the cascade we re-arm if stock remains (see _playbackEvents).
      useBooster(booster, pos);
      return;
    }

    final selected = state.selectedPosition;
    if (selected == null) {
      if (state.board.isValidPosition(pos) && state.board.cellAt(pos).canSwap) {
        state = state.copyWith(selectedPosition: pos, clearHintMove: true);
      }
    } else if (selected == pos) {
      state = state.copyWith(clearSelectedPosition: true);
    } else if (selected.isAdjacent(pos)) {
      state = state.copyWith(
        clearSelectedPosition: true,
        clearHintMove: true,
      );
      swapPieces(selected, pos);
    } else {
      if (state.board.isValidPosition(pos) && state.board.cellAt(pos).canSwap) {
        state = state.copyWith(selectedPosition: pos, clearHintMove: true);
      } else {
        state = state.copyWith(clearSelectedPosition: true);
      }
    }
  }

  /// Triggers a swap attempt between [from] and [to], executing the cascade loop.
  Future<void> swapPieces(Position from, Position to) async {
    if (!state.canInteract || state.movesLeft <= 0) return;
    resetHintTimer();

    state = state.copyWith(
      status: GameStatus.animating,
      clearSelectedPosition: true,
      clearHintMove: true,
    );

    final (targetState, eventList) =
        _cascadeEngine.processSwap(state, from, to);
    await _playbackEvents(eventList, targetState);
  }

  /// Plays back cascade events sequentially with audio and timing delays.
  Future<void> _playbackEvents(
    List<GameEvent> eventList,
    GameState targetState, {
    BoosterType? reArmBooster,
  }) async {
    for (final event in eventList) {
      _eventController.add(event);

      switch (event) {
        case SwapEvent():
          await _audioService.playSwap();
          await Future.delayed(
            const Duration(milliseconds: GameConfig.swapDurationMs),
          );

        case InvalidSwapEvent():
          await Future.delayed(
            const Duration(milliseconds: GameConfig.invalidSwapDurationMs),
          );

        case MatchEvent():
          await _audioService.playMatch();

        case SpawnSpecialEvent():
          await _audioService.playSpecialSpawn();
          await Future.delayed(
            const Duration(milliseconds: GameConfig.specialSpawnDurationMs),
          );

        case ClearEvent():
          await _audioService.playClear();
          await Future.delayed(
            const Duration(milliseconds: GameConfig.matchClearDurationMs),
          );

        case GravityFallEvent():
          await Future.delayed(
            const Duration(milliseconds: GameConfig.gravityFallDurationMs),
          );

        case RefillEvent():
          await Future.delayed(
            const Duration(milliseconds: GameConfig.refillFallDurationMs),
          );

        case ComboEvent(:final multiplier):
          await _audioService.playCombo(multiplier);

        case ObstacleDamageEvent():
          await _audioService.playClear();

        case ShuffleEvent():
          await Future.delayed(
            const Duration(milliseconds: GameConfig.shuffleDurationMs),
          );

        case LevelWonEvent(:final stars, :final score, :final bonusMoves):
          await _audioService.playLevelWon();
          await _analyticsService.logLevelComplete(
            levelId,
            stars,
            score,
            bonusMoves,
          );
          await ref
              .read(levelProgressProvider.notifier)
              .completeLevel(levelId, stars, score);

        case LevelLostEvent():
          await _audioService.playLevelLost();
          final movesUsed = state.levelConfig.maxMoves - state.movesLeft;
          await _analyticsService.logLevelFail(levelId, state.score, movesUsed);

        case HintEvent():
          break;

        case BoosterUsedEvent():
          await _audioService.playBooster();
      }
    }

    final finalStatus =
        targetState.isGameOver ? targetState.status : GameStatus.playing;

    // Re-arm the booster automatically if the player still has stock,
    // so they can tap multiple gems without re-selecting each time.
    final remainingStock =
        reArmBooster != null && !targetState.isGameOver
            ? (targetState.boosterInventory[reArmBooster] ?? 0)
            : 0;
    final shouldReArm = remainingStock > 0;

    state = targetState.copyWith(
      status: finalStatus,
      activeBooster: shouldReArm ? reArmBooster : null,
      clearActiveBooster: !shouldReArm,
    );
    if (finalStatus == GameStatus.playing) {
      resetHintTimer();
    }
  }

  /// Toggles arming of a targeted booster (Hammer, Color Swap) or immediately triggers untargeted boosters.
  void toggleBooster(BoosterType type) {
    if (state.isGameOver || state.status == GameStatus.animating) return;

    if (type == BoosterType.hammer || type == BoosterType.colorSwap) {
      final isCurrentlyArmed = state.activeBooster == type;
      state = state.copyWith(
        activeBooster: isCurrentlyArmed ? null : type,
        clearActiveBooster: isCurrentlyArmed,
        clearSelectedPosition: true,
      );
    } else {
      // Untargeted booster (Shuffle, +5 Moves): execute immediately!
      useBooster(type, null);
    }
  }

  /// Arms or activates an in-game booster power-up.
  Future<void> useBooster(BoosterType type, Position? target) async {
    if (state.isGameOver || state.status == GameStatus.animating) return;
    resetHintTimer();

    // If targeted booster without target provided, toggle target arming mode
    if ((type == BoosterType.hammer || type == BoosterType.colorSwap) &&
        target == null) {
      final isCurrentlyArmed = state.activeBooster == type;
      state = state.copyWith(
        activeBooster: isCurrentlyArmed ? null : type,
        clearActiveBooster: isCurrentlyArmed,
        clearSelectedPosition: true,
      );
      return;
    }

    state = state.copyWith(
      status: GameStatus.animating,
      clearActiveBooster: true,
      clearSelectedPosition: true,
    );

    try {
      final (targetState, eventList) =
          _cascadeEngine.processBooster(state, type, target);

      if (eventList.isNotEmpty) {
        await _audioService.playBooster();
        await _analyticsService.logBoosterUsed(type.name, levelId);
        try {
          await _gameRepository.useBooster(type);
        } catch (_) {
          // Graceful fallback if storage inventory differs
        }
        await _playbackEvents(eventList, targetState, reArmBooster: type);
      } else {
        state = state.copyWith(status: GameStatus.playing);
      }
    } catch (_) {
      state = state.copyWith(status: GameStatus.playing);
    }
  }

  /// Pauses the active game session.
  void pauseGame() {
    if (state.status == GameStatus.playing || state.status == GameStatus.idle) {
      _hintTimer?.cancel();
      state = state.copyWith(status: GameStatus.paused);
    }
  }

  /// Resumes a paused game session.
  void resumeGame() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
      resetHintTimer();
    }
  }

  /// Recommends a high-scoring swap move to assist the player.
  void requestHint() {
    if (!state.canInteract) return;
    final hint = _hintEngine.findBestHint(state.board);
    if (hint != null) {
      state = state.copyWith(hintMove: hint);
      _eventController.add(HintEvent(hint.$1, hint.$2));
    }
  }

  /// Resets the idle timer that triggers automatic hint recommendations.
  void resetHintTimer() {
    _hintTimer?.cancel();
    if (!state.canInteract) return;

    _hintTimer = Timer(
      const Duration(seconds: GameConfig.hintIdleDelaySeconds),
      requestHint,
    );
  }

  /// Saves the current session state to disk.
  Future<void> saveProgress() async {
    if (!state.isGameOver) {
      await _gameRepository.saveGameState(levelId, state);
    }
  }
}

/// Family notifier provider for [GameNotifier] parametrized by level ID.
final gameNotifierProvider =
    NotifierProvider.family<GameNotifier, GameState, int>(
  (levelId) => GameNotifier(levelId),
);

/// Family provider resolving the currently selected cell position on the grid.
final selectedPositionProvider =
    Provider.family<Position?, int>((ref, levelId) {
  return ref.watch(gameNotifierProvider(levelId)).selectedPosition;
});

/// Family provider indicating if the board is actively running cascade animations.
final isAnimatingProvider = Provider.family<bool, int>((ref, levelId) {
  return ref.watch(gameNotifierProvider(levelId)).status ==
      GameStatus.animating;
});

/// Family provider exposing the recommended hint swap positions.
final hintPositionProvider =
    Provider.family<(Position, Position)?, int>((ref, levelId) {
  return ref.watch(gameNotifierProvider(levelId)).hintMove;
});

/// Family provider exposing the currently armed booster waiting for cell selection.
final activeBoosterProvider =
    Provider.family<BoosterType?, int>((ref, levelId) {
  return ref.watch(gameNotifierProvider(levelId)).activeBooster;
});
