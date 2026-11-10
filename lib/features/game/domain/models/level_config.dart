import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'cell.dart';
import 'game_event.dart';
import 'piece.dart';
import 'position.dart';

/// Sealed hierarchy defining game objectives for levels.
sealed class LevelGoal {
  const LevelGoal();

  String get id;
}

/// Goal to reach a minimum total score.
final class TargetScore extends LevelGoal {
  final int targetScore;

  const TargetScore(this.targetScore);

  @override
  String get id => 'target_score';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetScore &&
          runtimeType == other.runtimeType &&
          targetScore == other.targetScore;

  @override
  int get hashCode => targetScore.hashCode;

  @override
  String toString() => 'TargetScore($targetScore)';
}

/// Goal to collect/clear a specified number of pieces of a particular color.
final class CollectPieces extends LevelGoal {
  final PieceType pieceType;
  final int count;

  const CollectPieces(this.pieceType, this.count);

  @override
  String get id => 'collect_${pieceType.name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectPieces &&
          runtimeType == other.runtimeType &&
          pieceType == other.pieceType &&
          count == other.count;

  @override
  int get hashCode => Object.hash(pieceType, count);

  @override
  String toString() => 'CollectPieces(${pieceType.name}, $count)';
}

/// Goal to clear all jelly tiles across the board.
final class ClearAllJelly extends LevelGoal {
  const ClearAllJelly();

  @override
  String get id => 'clear_all_jelly';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClearAllJelly && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ClearAllJelly()';
}

/// Goal to drop ingredients from top to the bottom edge of the board.
final class DropIngredients extends LevelGoal {
  final int count;

  const DropIngredients(this.count);

  @override
  String get id => 'drop_ingredients';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropIngredients &&
          runtimeType == other.runtimeType &&
          count == other.count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => 'DropIngredients($count)';
}

/// Static map layout details defining obstacles, jelly, and blockers.
@immutable
class LevelLayout {
  final Set<Position> blockedPositions;
  final Map<Position, ObstacleType> obstacles;
  final Map<Position, int> jellyGrid;
  final Set<Position> lockedPositions;
  final Set<Position> icePositions;

  const LevelLayout({
    this.blockedPositions = const {},
    this.obstacles = const {},
    this.jellyGrid = const {},
    this.lockedPositions = const {},
    this.icePositions = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelLayout &&
          runtimeType == other.runtimeType &&
          const SetEquality().equals(blockedPositions, other.blockedPositions) &&
          const MapEquality().equals(obstacles, other.obstacles) &&
          const MapEquality().equals(jellyGrid, other.jellyGrid) &&
          const SetEquality().equals(lockedPositions, other.lockedPositions) &&
          const SetEquality().equals(icePositions, other.icePositions);

  @override
  int get hashCode => Object.hash(
        const SetEquality().hash(blockedPositions),
        const MapEquality().hash(obstacles),
        const MapEquality().hash(jellyGrid),
        const SetEquality().hash(lockedPositions),
        const SetEquality().hash(icePositions),
      );
}

/// Complete configuration and victory requirements for a puzzle level.
@immutable
class LevelConfig {
  final int id;
  final String name;
  final int rows;
  final int cols;
  final LevelLayout layout;
  final List<LevelGoal> goals;
  final int maxMoves;
  final int? timerSeconds;
  final List<int> starThresholds;
  final List<PieceType> allowedColors;
  final Map<BoosterType, int> availableBoosters;

  const LevelConfig({
    required this.id,
    required this.name,
    this.rows = 8,
    this.cols = 8,
    this.layout = const LevelLayout(),
    required this.goals,
    required this.maxMoves,
    this.timerSeconds,
    this.starThresholds = const [1000, 2500, 4500],
    this.allowedColors = const [
      PieceType.red,
      PieceType.orange,
      PieceType.yellow,
      PieceType.green,
      PieceType.blue,
      PieceType.purple,
    ],
    this.availableBoosters = const {
      BoosterType.hammer: 99,
      BoosterType.shuffle: 99,
      BoosterType.plusFiveMoves: 99,
      BoosterType.colorSwap: 99,
    },
  });

  LevelConfig copyWith({
    int? id,
    String? name,
    int? rows,
    int? cols,
    LevelLayout? layout,
    List<LevelGoal>? goals,
    int? maxMoves,
    int? timerSeconds,
    List<int>? starThresholds,
    List<PieceType>? allowedColors,
    Map<BoosterType, int>? availableBoosters,
  }) {
    return LevelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      layout: layout ?? this.layout,
      goals: goals ?? this.goals,
      maxMoves: maxMoves ?? this.maxMoves,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      starThresholds: starThresholds ?? this.starThresholds,
      allowedColors: allowedColors ?? this.allowedColors,
      availableBoosters: availableBoosters ?? this.availableBoosters,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          rows == other.rows &&
          cols == other.cols &&
          layout == other.layout &&
          const ListEquality().equals(goals, other.goals) &&
          maxMoves == other.maxMoves &&
          timerSeconds == other.timerSeconds &&
          const ListEquality().equals(starThresholds, other.starThresholds) &&
          const ListEquality().equals(allowedColors, other.allowedColors) &&
          const MapEquality().equals(availableBoosters, other.availableBoosters);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        rows,
        cols,
        layout,
        const ListEquality().hash(goals),
        maxMoves,
        timerSeconds,
        const ListEquality().hash(starThresholds),
        const ListEquality().hash(allowedColors),
        const MapEquality().hash(availableBoosters),
      );

  @override
  String toString() =>
      'LevelConfig(id: $id, name: $name, ${rows}x$cols, moves: $maxMoves)';
}
