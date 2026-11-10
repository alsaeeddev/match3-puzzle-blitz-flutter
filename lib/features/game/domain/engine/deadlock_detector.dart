import 'dart:math';
import '../models/board.dart';
import '../models/cell.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'match_detector.dart';

/// Pure Dart deadlock detector that senses when no valid player moves remain
/// and reshuffles existing board pieces to guarantee playability without immediate matches.
class DeadlockDetector {
  final MatchDetector matchDetector;

  const DeadlockDetector([this.matchDetector = const MatchDetector()]);

  /// Returns true if no legal swaps are currently available to the player.
  bool isDeadlock(Board board) {
    return matchDetector.findAllValidMoves(board).isEmpty;
  }

  /// Reshuffles playable pieces on [board] to produce a new layout that has
  /// NO immediate 3-matches AND at least one valid player move.
  ///
  /// Throws [StateError] if a valid board cannot be found within [maxAttempts].
  Board shuffle(
    Board board,
    Random random, {
    int maxAttempts = 50,
  }) {
    // Collect all movable normal cell positions and their pieces
    final movablePositions = <Position>[];
    final pieces = <Piece>[];

    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final pos = Position(r, c);
        final cell = board.cellAt(pos);
        if (cell.content is NormalCell && !cell.isLocked && !cell.hasIce) {
          movablePositions.add(pos);
          pieces.add(cell.content.piece!);
        }
      }
    }

    if (movablePositions.length < 3) {
      return board;
    }

    final shuffledPieces = List<Piece>.from(pieces);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      shuffledPieces.shuffle(random);

      var newGrid = board.cells.map((row) => List<CellState>.from(row)).toList();
      for (var i = 0; i < movablePositions.length; i++) {
        final pos = movablePositions[i];
        final oldCell = newGrid[pos.row][pos.col];
        newGrid[pos.row][pos.col] = oldCell.copyWith(
          content: NormalCell(shuffledPieces[i]),
        );
      }

      final candidateBoard = Board(
        rows: board.rows,
        cols: board.cols,
        cells: newGrid,
      );

      // Verify that the candidate board has NO existing matches
      // and HAS at least one valid move
      final hasNoMatches = matchDetector.findAllMatches(candidateBoard).isEmpty;
      final hasValidMoves = matchDetector.findAllValidMoves(candidateBoard).isNotEmpty;

      if (hasNoMatches && hasValidMoves) {
        return candidateBoard;
      }
    }

    throw StateError(
      'Unable to resolve board deadlock after $maxAttempts shuffle attempts.',
    );
  }
}
