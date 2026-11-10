import 'package:flutter/foundation.dart';

/// Immutable 2D grid coordinate representing a board cell position.
@immutable
class Position implements Comparable<Position> {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// Returns the 4 cardinal orthogonal neighbors: Up, Down, Left, Right.
  List<Position> get neighbors => [
        Position(row - 1, col), // Up
        Position(row + 1, col), // Down
        Position(row, col - 1), // Left
        Position(row, col + 1), // Right
      ];

  /// Checks if [other] is immediately adjacent orthogonally (Manhattan distance == 1).
  bool isAdjacent(Position other) => manhattanDistance(other) == 1;

  /// Calculates the Manhattan distance (|dr| + |dc|) between this and [other].
  int manhattanDistance(Position other) =>
      (row - other.row).abs() + (col - other.col).abs();

  /// Creates a copy with optional overridden row or col values.
  Position copyWith({int? row, int? col}) {
    return Position(
      row ?? this.row,
      col ?? this.col,
    );
  }

  @override
  int compareTo(Position other) {
    if (row != other.row) {
      return row.compareTo(other.row);
    }
    return col.compareTo(other.col);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Position($row, $col)';
}
