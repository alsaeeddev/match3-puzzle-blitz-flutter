import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'cell.dart';
import 'piece.dart';
import 'position.dart';

/// Immutable representation of the game board matrix.
@immutable
class Board {
  final int rows;
  final int cols;
  final List<List<CellState>> cells;

  Board({
    required this.rows,
    required this.cols,
    required List<List<CellState>> cells,
  }) : cells = List<List<CellState>>.unmodifiable(
          cells.map((row) => List<CellState>.unmodifiable(row)),
        );

  /// Creates a completely blank board filled with [EmptyCell] contents.
  factory Board.empty({required int rows, required int cols}) {
    final grid = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => CellState(
          position: Position(r, c),
          content: const EmptyCell(),
        ),
      ),
    );
    return Board(rows: rows, cols: cols, cells: grid);
  }

  /// Verifies whether [pos] falls within the bounds of this grid.
  bool isValidPosition(Position pos) =>
      pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols;

  /// Retrieves the cell at [pos]. Throws [RangeError] if out of bounds.
  CellState cellAt(Position pos) {
    if (!isValidPosition(pos)) {
      throw RangeError(
          'Position $pos is outside the board bounds (${rows}x$cols).');
    }
    return cells[pos.row][pos.col];
  }

  /// Safely returns the cell at [pos], or null if out of bounds.
  CellState? cellOrNull(Position pos) {
    if (!isValidPosition(pos)) return null;
    return cells[pos.row][pos.col];
  }

  /// Convenience getter for the piece at [pos] (if normal).
  Piece? pieceAt(Position pos) => cellOrNull(pos)?.content.piece;

  /// Checks if [pos] is blocked / impassable.
  bool isBlocked(Position pos) {
    if (!isValidPosition(pos)) return true;
    return cellAt(pos).content.isBlocked;
  }

  /// Checks if two positions can be legally swapped (must be adjacent and swappable).
  bool canSwap(Position from, Position to) {
    if (!isValidPosition(from) || !isValidPosition(to)) return false;
    if (!from.isAdjacent(to)) return false;
    final cellFrom = cellAt(from);
    final cellTo = cellAt(to);
    return cellFrom.canSwap && cellTo.canSwap;
  }

  /// Returns a new Board with a single cell updated.
  Board updateCell(
      Position pos, CellState Function(CellState current) updater) {
    final newGrid = cells.map((row) => List<CellState>.from(row)).toList();
    newGrid[pos.row][pos.col] = updater(newGrid[pos.row][pos.col]);
    return Board(rows: rows, cols: cols, cells: newGrid);
  }

  /// Returns a new Board with the content at [pos] replaced.
  Board updateCellContent(Position pos, CellContent newContent) {
    return updateCell(pos, (current) => current.copyWith(content: newContent));
  }

  /// Swaps the content between positions [a] and [b].
  Board swapPieces(Position a, Position b) {
    if (!isValidPosition(a) || !isValidPosition(b)) return this;
    final cellA = cellAt(a);
    final cellB = cellAt(b);
    final newGrid = cells.map((row) => List<CellState>.from(row)).toList();
    newGrid[a.row][a.col] = cellA.copyWith(content: cellB.content);
    newGrid[b.row][b.col] = cellB.copyWith(content: cellA.content);
    return Board(rows: rows, cols: cols, cells: newGrid);
  }

  /// All cells on the board as a flat sequence.
  Iterable<CellState> get allCells sync* {
    for (final row in cells) {
      for (final cell in row) {
        yield cell;
      }
    }
  }

  /// Copies this board with optional property replacements.
  Board copyWith({
    int? rows,
    int? cols,
    List<List<CellState>>? cells,
  }) {
    return Board(
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      cells: cells ?? this.cells,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Board || runtimeType != other.runtimeType) return false;
    if (rows != other.rows || cols != other.cols) return false;
    const equality = DeepCollectionEquality();
    return equality.equals(cells, other.cells);
  }

  @override
  int get hashCode =>
      Object.hash(rows, cols, const DeepCollectionEquality().hash(cells));

  @override
  String toString() => 'Board(${rows}x$cols)';
}
