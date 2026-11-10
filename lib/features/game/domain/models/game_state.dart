import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'board.dart';
import 'game_event.dart';
import 'level_config.dart';
import 'position.dart';

/// Current operational state of the game loop and UI interactions.
enum GameStatus {
  idle,
  playing,
  animating,
  paused,
  won,
  lost,
  shuffling,
}

/// Immutable snapshot of the entire game session.
@immutable
class GameState {
  final Board board;
  final LevelConfig levelConfig;
  final int score;
  final int movesLeft;
  final int? timeLeft;
  final GameStatus status;
  final Map<String, int> goalProgress;
  final double comboMultiplier;
  final Position? selectedPosition;
  final (Position, Position)? hintMove;
  final Map<BoosterType, int> boosterInventory;
  final BoosterType? activeBooster;

  const GameState({
    required this.board,
    required this.levelConfig,
    this.score = 0,
    required this.movesLeft,
    this.timeLeft,
    this.status = GameStatus.playing,
    this.goalProgress = const {},
    this.comboMultiplier = 1.0,
    this.selectedPosition,
    this.hintMove,
    this.boosterInventory = const {},
    this.activeBooster,
  });

  /// Factory to initialize a fresh GameState from a [LevelConfig] and generated [Board].
  factory GameState.initial({
    required LevelConfig levelConfig,
    required Board board,
  }) {
    final initialGoals = <String, int>{};
    for (final goal in levelConfig.goals) {
      initialGoals[goal.id] = 0;
    }

    return GameState(
      board: board,
      levelConfig: levelConfig,
      score: 0,
      movesLeft: levelConfig.maxMoves,
      timeLeft: levelConfig.timerSeconds,
      status: GameStatus.playing,
      goalProgress: initialGoals,
      comboMultiplier: 1.0,
      selectedPosition: null,
      hintMove: null,
      boosterInventory: Map.from(levelConfig.availableBoosters),
      activeBooster: null,
    );
  }

  bool get isGameOver => status == GameStatus.won || status == GameStatus.lost;
  bool get canInteract =>
      status == GameStatus.playing || status == GameStatus.idle;

  /// Checks whether all victory conditions specified in [levelConfig] have been satisfied.
  bool areAllGoalsMet() {
    for (final goal in levelConfig.goals) {
      final current = goalProgress[goal.id] ?? 0;
      final isMet = switch (goal) {
        TargetScore(:final targetScore) => score >= targetScore,
        CollectPieces(:final count) => current >= count,
        ClearAllJelly() => current >= _totalJellyCount(levelConfig),
        DropIngredients(:final count) => current >= count,
      };
      if (!isMet) return false;
    }
    return true;
  }

  static int _totalJellyCount(LevelConfig config) {
    var total = 0;
    for (final layers in config.layout.jellyGrid.values) {
      total += layers;
    }
    return total;
  }

  GameState copyWith({
    Board? board,
    LevelConfig? levelConfig,
    int? score,
    int? movesLeft,
    int? timeLeft,
    GameStatus? status,
    Map<String, int>? goalProgress,
    double? comboMultiplier,
    Position? selectedPosition,
    bool clearSelectedPosition = false,
    (Position, Position)? hintMove,
    bool clearHintMove = false,
    Map<BoosterType, int>? boosterInventory,
    BoosterType? activeBooster,
    bool clearActiveBooster = false,
  }) {
    return GameState(
      board: board ?? this.board,
      levelConfig: levelConfig ?? this.levelConfig,
      score: score ?? this.score,
      movesLeft: movesLeft ?? this.movesLeft,
      timeLeft: timeLeft ?? this.timeLeft,
      status: status ?? this.status,
      goalProgress: goalProgress ?? this.goalProgress,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      selectedPosition: clearSelectedPosition
          ? null
          : (selectedPosition ?? this.selectedPosition),
      hintMove: clearHintMove ? null : (hintMove ?? this.hintMove),
      boosterInventory: boosterInventory ?? this.boosterInventory,
      activeBooster:
          clearActiveBooster ? null : (activeBooster ?? this.activeBooster),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          runtimeType == other.runtimeType &&
          board == other.board &&
          levelConfig == other.levelConfig &&
          score == other.score &&
          movesLeft == other.movesLeft &&
          timeLeft == other.timeLeft &&
          status == other.status &&
          const MapEquality().equals(goalProgress, other.goalProgress) &&
          comboMultiplier == other.comboMultiplier &&
          selectedPosition == other.selectedPosition &&
          hintMove == other.hintMove &&
          const MapEquality().equals(boosterInventory, other.boosterInventory) &&
          activeBooster == other.activeBooster;

  @override
  int get hashCode => Object.hash(
        board,
        levelConfig,
        score,
        movesLeft,
        timeLeft,
        status,
        const MapEquality().hash(goalProgress),
        comboMultiplier,
        selectedPosition,
        hintMove,
        const MapEquality().hash(boosterInventory),
        activeBooster,
      );

  @override
  String toString() =>
      'GameState(score: $score, moves: $movesLeft, status: $status)';
}
