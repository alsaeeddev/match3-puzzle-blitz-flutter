import 'package:collection/collection.dart';
import '../models/board.dart';
import '../models/cell.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Geometric shapes formed by matched pieces.
enum MatchShape {
  horizontal,
  vertical,
  shapeL,
  shapeT,
  shapeCross,
}

/// A validated contiguous or intersecting match of pieces on the board.
class BoardMatch {
  final List<Position> positions;
  final MatchShape shape;
  final int length;
  final Position centerPosition;
  final PieceType pieceType;

  BoardMatch({
    required List<Position> positions,
    required this.shape,
    required this.centerPosition,
    required this.pieceType,
  })  : positions = List.unmodifiable(positions),
        length = positions.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardMatch &&
          runtimeType == other.runtimeType &&
          shape == other.shape &&
          centerPosition == other.centerPosition &&
          pieceType == other.pieceType &&
          const SetEquality()
              .equals(positions.toSet(), other.positions.toSet());

  @override
  int get hashCode => Object.hash(
        shape,
        centerPosition,
        pieceType,
        const SetEquality().hash(positions.toSet()),
      );

  @override
  String toString() =>
      'BoardMatch($pieceType, shape: $shape, length: $length, center: $centerPosition)';
}

/// Pure Dart engine responsible for detecting horizontal, vertical, L, T,
/// and Cross matches, evaluating valid player swaps, and scanning legal moves.
class MatchDetector {
  const MatchDetector();

  /// Scans the entire board for all valid matches of 3 or more pieces.
  /// Combines intersecting horizontal and vertical runs into composite L/T/Cross matches.
  List<BoardMatch> findAllMatches(Board board) {
    final horizontalRuns = _findHorizontalRuns(board);
    final verticalRuns = _findVerticalRuns(board);

    final matches = <BoardMatch>[];
    final usedHorizontal = <List<Position>>{};
    final usedVertical = <List<Position>>{};

    // Check for intersections between horizontal and vertical runs of identical colors
    for (final hRun in horizontalRuns) {
      final hPieceType = board.pieceAt(hRun.first)!.pieceType;

      for (final vRun in verticalRuns) {
        final vPieceType = board.pieceAt(vRun.first)!.pieceType;
        if (hPieceType != vPieceType) continue;

        // Find intersection point
        final intersection = hRun.toSet().intersection(vRun.toSet());
        if (intersection.isNotEmpty) {
          final center = intersection.first;
          final combined = (hRun.toSet()..addAll(vRun)).toList();
          final shape = detectShape(combined, center: center, hRun: hRun, vRun: vRun);

          matches.add(
            BoardMatch(
              positions: combined,
              shape: shape,
              centerPosition: center,
              pieceType: hPieceType,
            ),
          );

          usedHorizontal.add(hRun);
          usedVertical.add(vRun);
        }
      }
    }

    // Add remaining standalone horizontal runs
    for (final hRun in horizontalRuns) {
      if (!usedHorizontal.contains(hRun)) {
        final pieceType = board.pieceAt(hRun.first)!.pieceType;
        matches.add(
          BoardMatch(
            positions: hRun,
            shape: MatchShape.horizontal,
            centerPosition: hRun[hRun.length ~/ 2],
            pieceType: pieceType,
          ),
        );
      }
    }

    // Add remaining standalone vertical runs
    for (final vRun in verticalRuns) {
      if (!usedVertical.contains(vRun)) {
        final pieceType = board.pieceAt(vRun.first)!.pieceType;
        matches.add(
          BoardMatch(
            positions: vRun,
            shape: MatchShape.vertical,
            centerPosition: vRun[vRun.length ~/ 2],
            pieceType: pieceType,
          ),
        );
      }
    }

    return matches;
  }

  /// Identifies whether an intersecting match forms an L, T, or Cross shape.
  MatchShape detectShape(
    List<Position> positions, {
    Position? center,
    List<Position>? hRun,
    List<Position>? vRun,
  }) {
    if (center == null || hRun == null || vRun == null) {
      // Analyze coordinate distributions
      final rows = positions.map((p) => p.row).toSet();
      final cols = positions.map((p) => p.col).toSet();

      if (rows.length == 1) return MatchShape.horizontal;
      if (cols.length == 1) return MatchShape.vertical;
      return MatchShape.shapeT;
    }

    final hIndex = hRun.indexOf(center);
    final vIndex = vRun.indexOf(center);

    final isHEnd = hIndex == 0 || hIndex == hRun.length - 1;
    final isVEnd = vIndex == 0 || vIndex == vRun.length - 1;

    if (!isHEnd && !isVEnd) {
      return MatchShape.shapeCross;
    } else if ((!isHEnd && isVEnd) || (isHEnd && !isVEnd)) {
      return MatchShape.shapeT;
    } else {
      return MatchShape.shapeL;
    }
  }

  /// Maps a completed [BoardMatch] to the corresponding special piece creation.
  SpecialType getSpecialTypeForMatch(BoardMatch match) {
    if (match.shape == MatchShape.shapeCross ||
        match.shape == MatchShape.shapeT ||
        match.shape == MatchShape.shapeL) {
      return SpecialType.wrapped;
    }

    if (match.length >= 5) {
      return SpecialType.colorBomb;
    }

    if (match.length == 4) {
      return match.shape == MatchShape.horizontal
          ? SpecialType.stripedH
          : SpecialType.stripedV;
    }

    return SpecialType.none;
  }

  /// Determines whether swapping the pieces at [from] and [to] is a legal game move.
  bool isValidSwap(Board board, Position from, Position to) {
    if (!board.canSwap(from, to)) return false;

    final cellA = board.cellAt(from);
    final cellB = board.cellAt(to);
    final pieceA = cellA.content.piece;
    final pieceB = cellB.content.piece;

    if (pieceA == null || pieceB == null) return false;

    // Special combo: swapping any two special pieces is always legal
    if (pieceA.specialType.isSpecial && pieceB.specialType.isSpecial) {
      return true;
    }

    // Color Bomb rule: swapping a Color Bomb with ANY piece is always legal
    if (pieceA.specialType.isColorBomb || pieceB.specialType.isColorBomb) {
      return true;
    }

    // Normal swap: check if swapping creates at least one 3-match
    final simulatedBoard = board.swapPieces(from, to);
    final matches = findAllMatches(simulatedBoard);
    return matches.isNotEmpty;
  }

  /// Finds all valid (from, to) swap combinations available on the current board.
  List<(Position from, Position to)> findAllValidMoves(Board board) {
    final validMoves = <(Position from, Position to)>[];

    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final current = Position(r, c);

        // Check right neighbor
        final right = Position(r, c + 1);
        if (board.isValidPosition(right) && isValidSwap(board, current, right)) {
          validMoves.add((current, right));
        }

        // Check down neighbor
        final down = Position(r + 1, c);
        if (board.isValidPosition(down) && isValidSwap(board, current, down)) {
          validMoves.add((current, down));
        }
      }
    }

    return validMoves;
  }

  // ---------------------------------------------------------------------------
  // Internal scan helpers
  // ---------------------------------------------------------------------------

  List<List<Position>> _findHorizontalRuns(Board board) {
    final runs = <List<Position>>[];

    for (var r = 0; r < board.rows; r++) {
      var currentRun = <Position>[];
      PieceType? runType;

      for (var c = 0; c < board.cols; c++) {
        final pos = Position(r, c);
        final cell = board.cellAt(pos);
        final piece = cell.content.piece;

        if (cell.content is NormalCell && piece != null) {
          if (runType == null) {
            runType = piece.pieceType;
            currentRun.add(pos);
          } else if (runType == piece.pieceType) {
            currentRun.add(pos);
          } else {
            if (currentRun.length >= 3) {
              runs.add(List.from(currentRun));
            }
            currentRun = [pos];
            runType = piece.pieceType;
          }
        } else {
          if (currentRun.length >= 3) {
            runs.add(List.from(currentRun));
          }
          currentRun.clear();
          runType = null;
        }
      }

      if (currentRun.length >= 3) {
        runs.add(List.from(currentRun));
      }
    }

    return runs;
  }

  List<List<Position>> _findVerticalRuns(Board board) {
    final runs = <List<Position>>[];

    for (var c = 0; c < board.cols; c++) {
      var currentRun = <Position>[];
      PieceType? runType;

      for (var r = 0; r < board.rows; r++) {
        final pos = Position(r, c);
        final cell = board.cellAt(pos);
        final piece = cell.content.piece;

        if (cell.content is NormalCell && piece != null) {
          if (runType == null) {
            runType = piece.pieceType;
            currentRun.add(pos);
          } else if (runType == piece.pieceType) {
            currentRun.add(pos);
          } else {
            if (currentRun.length >= 3) {
              runs.add(List.from(currentRun));
            }
            currentRun = [pos];
            runType = piece.pieceType;
          }
        } else {
          if (currentRun.length >= 3) {
            runs.add(List.from(currentRun));
          }
          currentRun.clear();
          runType = null;
        }
      }

      if (currentRun.length >= 3) {
        runs.add(List.from(currentRun));
      }
    }

    return runs;
  }
}
