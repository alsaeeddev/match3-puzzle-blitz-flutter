import '../models/board.dart';
import '../models/cell.dart';
import '../models/game_event.dart';
import '../models/position.dart';

/// Pure Dart engine responsible for simulating gravity across board columns.
class GravityEngine {
  const GravityEngine();

  /// Applies gravity to the board column-by-column, dropping playable pieces
  /// downwards into available [EmptyCell] spaces.
  ///
  /// Respects [BlockedCell] voids and immovable obstacles by preventing pieces
  /// from passing through blocked partitions.
  ///
  /// Returns a tuple containing the updated [Board] and the resulting [GravityFallEvent].
  (Board newBoard, GravityFallEvent event) applyGravity(Board board) {
    var currentGrid = board.cells.map((row) => List<CellState>.from(row)).toList();
    final moves = <(Position from, Position to)>[];

    for (var col = 0; col < board.cols; col++) {
      // Process column bottom-up
      for (var targetRow = board.rows - 1; targetRow >= 0; targetRow--) {
        final targetCell = currentGrid[targetRow][col];

        // Only empty cells that are not blocked can receive falling pieces
        if (targetCell.content is EmptyCell && !targetCell.isLocked) {
          // Look upward for the first movable piece
          var foundSourceRow = -1;

          for (var sourceRow = targetRow - 1; sourceRow >= 0; sourceRow--) {
            final sourceCell = currentGrid[sourceRow][col];

            // If an impassable blocked cell is encountered, stop upward search for this slot
            if (sourceCell.content is BlockedCell) {
              break;
            }

            // Fixed obstacles cannot drop, but allow pieces to be blocked below them
            if (sourceCell.content is ObstacleCell) {
              break;
            }

            // Found a movable normal piece
            if (sourceCell.content is NormalCell && !sourceCell.isLocked && !sourceCell.hasIce) {
              foundSourceRow = sourceRow;
              break;
            }
          }

          if (foundSourceRow != -1) {
            final sourcePos = Position(foundSourceRow, col);
            final targetPos = Position(targetRow, col);

            final sourceCell = currentGrid[foundSourceRow][col];
            final targetCellState = currentGrid[targetRow][col];

            // Move piece to target cell
            currentGrid[targetRow][col] = targetCellState.copyWith(
              content: sourceCell.content,
            );

            // Empty the source cell
            currentGrid[foundSourceRow][col] = sourceCell.copyWith(
              content: const EmptyCell(),
            );

            moves.add((sourcePos, targetPos));
          }
        }
      }
    }

    final newBoard = Board(
      rows: board.rows,
      cols: board.cols,
      cells: currentGrid,
    );

    return (newBoard, GravityFallEvent(moves));
  }
}
