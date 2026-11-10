import 'package:collection/collection.dart';
import 'board.dart';
import 'piece.dart';
import 'position.dart';

/// Available boosters that players can use to manipulate the board.
enum BoosterType {
  hammer,
  shuffle,
  plusFiveMoves,
  colorSwap,
}

/// Sealed hierarchy defining all deterministic game events emitted
/// during user input, swaps, cascades, clears, and level resolutions.
sealed class GameEvent {
  const GameEvent();
}

/// User triggered a valid swap between two adjacent positions.
final class SwapEvent extends GameEvent {
  final Position from;
  final Position to;

  const SwapEvent(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwapEvent &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'SwapEvent($from -> $to)';
}

/// An attempted swap failed validation (not adjacent or produced no match).
final class InvalidSwapEvent extends GameEvent {
  final Position from;
  final Position to;

  const InvalidSwapEvent(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvalidSwapEvent &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'InvalidSwapEvent($from -> $to)';
}

/// A match (or special color bomb activation) was detected on the board.
final class MatchEvent extends GameEvent {
  final List<Position> positions;
  final PieceType? colorBombTarget;

  const MatchEvent(this.positions, [this.colorBombTarget]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchEvent &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(positions, other.positions) &&
          colorBombTarget == other.colorBombTarget;

  @override
  int get hashCode =>
      Object.hash(const ListEquality().hash(positions), colorBombTarget);

  @override
  String toString() =>
      'MatchEvent(positions: $positions, target: $colorBombTarget)';
}

/// Positions whose contents were cleared from the board.
final class ClearEvent extends GameEvent {
  final List<Position> positions;

  const ClearEvent(this.positions);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClearEvent &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(positions, other.positions);

  @override
  int get hashCode => const ListEquality().hash(positions);

  @override
  String toString() => 'ClearEvent(positions: $positions)';
}

/// A special piece was generated and placed at [position].
final class SpawnSpecialEvent extends GameEvent {
  final Position position;
  final SpecialType special;

  const SpawnSpecialEvent(this.position, this.special);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpawnSpecialEvent &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          special == other.special;

  @override
  int get hashCode => Object.hash(position, special);

  @override
  String toString() => 'SpawnSpecialEvent($position, $special)';
}

/// Pieces dropped downwards due to gravity.
final class GravityFallEvent extends GameEvent {
  final List<(Position from, Position to)> moves;

  const GravityFallEvent(this.moves);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GravityFallEvent &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(moves, other.moves);

  @override
  int get hashCode => const ListEquality().hash(moves);

  @override
  String toString() => 'GravityFallEvent(moves: $moves)';
}

/// New pieces were spawned from the top to refill empty positions.
final class RefillEvent extends GameEvent {
  final List<(Position position, Piece piece)> pieces;

  const RefillEvent(this.pieces);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefillEvent &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(pieces, other.pieces);

  @override
  int get hashCode => const ListEquality().hash(pieces);

  @override
  String toString() => 'RefillEvent(pieces: $pieces)';
}

/// Damage or layer decrement applied to an obstacle or jelly.
final class ObstacleDamageEvent extends GameEvent {
  final Position position;
  final int layersRemoved;

  const ObstacleDamageEvent(this.position, this.layersRemoved);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObstacleDamageEvent &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          layersRemoved == other.layersRemoved;

  @override
  int get hashCode => Object.hash(position, layersRemoved);

  @override
  String toString() =>
      'ObstacleDamageEvent($position, layersRemoved: $layersRemoved)';
}

/// A combo multiplier was triggered during a cascade step.
final class ComboEvent extends GameEvent {
  final int multiplier;

  const ComboEvent(this.multiplier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComboEvent &&
          runtimeType == other.runtimeType &&
          multiplier == other.multiplier;

  @override
  int get hashCode => multiplier.hashCode;

  @override
  String toString() => 'ComboEvent(${multiplier}x)';
}

/// The board was reshuffled to resolve a deadlock.
final class ShuffleEvent extends GameEvent {
  final Board newBoard;

  const ShuffleEvent(this.newBoard);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShuffleEvent &&
          runtimeType == other.runtimeType &&
          newBoard == other.newBoard;

  @override
  int get hashCode => newBoard.hashCode;

  @override
  String toString() => 'ShuffleEvent()';
}

/// The player successfully fulfilled all level goals.
final class LevelWonEvent extends GameEvent {
  final int stars;
  final int score;
  final int bonusMoves;

  const LevelWonEvent(this.stars, this.score, this.bonusMoves);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelWonEvent &&
          runtimeType == other.runtimeType &&
          stars == other.stars &&
          score == other.score &&
          bonusMoves == other.bonusMoves;

  @override
  int get hashCode => Object.hash(stars, score, bonusMoves);

  @override
  String toString() =>
      'LevelWonEvent(stars: $stars, score: $score, bonusMoves: $bonusMoves)';
}

/// The player ran out of moves without completing all goals.
final class LevelLostEvent extends GameEvent {
  const LevelLostEvent();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelLostEvent && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'LevelLostEvent()';
}

/// Hint event showing a recommended move to the player.
final class HintEvent extends GameEvent {
  final Position from;
  final Position to;

  const HintEvent(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HintEvent &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'HintEvent($from -> $to)';
}

/// A booster was activated on the board.
final class BoosterUsedEvent extends GameEvent {
  final BoosterType booster;
  final List<Position> affected;

  const BoosterUsedEvent(this.booster, this.affected);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoosterUsedEvent &&
          runtimeType == other.runtimeType &&
          booster == other.booster &&
          const ListEquality().equals(affected, other.affected);

  @override
  int get hashCode =>
      Object.hash(booster, const ListEquality().hash(affected));

  @override
  String toString() => 'BoosterUsedEvent($booster, affected: $affected)';
}
