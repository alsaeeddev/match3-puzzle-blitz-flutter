import '../models/board.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Pure Dart engine resolving special piece interactions and combo explosions.
class SpecialCombos {
  const SpecialCombos();

  /// Determines whether swapping two pieces forms an active special combo.
  bool isSpecialCombo(SpecialType a, SpecialType b) {
    if (a.isColorBomb || b.isColorBomb) return true;
    return a.isSpecial && b.isSpecial;
  }

  /// Calculates all positions affected by a two-piece special combo.
  Set<Position> getAffectedPositions(
    Board board,
    Position a,
    Position b,
    SpecialType typeA,
    SpecialType typeB, {
    PieceType? targetColor,
  }) {
    final affected = <Position>{a, b};

    // 1. ColorBomb + ColorBomb -> Clears entire board
    if (typeA.isColorBomb && typeB.isColorBomb) {
      for (var r = 0; r < board.rows; r++) {
        for (var c = 0; c < board.cols; c++) {
          final pos = Position(r, c);
          if (!board.cellAt(pos).content.isBlocked) {
            affected.add(pos);
          }
        }
      }
      return affected;
    }

    // 2. ColorBomb + Striped
    if ((typeA.isColorBomb && typeB.isStriped) ||
        (typeB.isColorBomb && typeA.isStriped)) {
      final color = targetColor ?? _findColorOf(board, a, b);
      if (color != null) {
        final matchingPositions = _findPositionsOfColor(board, color);
        affected.addAll(matchingPositions);
        var toggle = false;
        for (final pos in matchingPositions) {
          // Alternating rows and columns
          if (toggle) {
            affected.addAll(_getRowPositions(board, pos.row));
          } else {
            affected.addAll(_getColumnPositions(board, pos.col));
          }
          toggle = !toggle;
        }
      }
      return affected;
    }

    // 3. ColorBomb + Wrapped
    if ((typeA.isColorBomb && typeB.isWrapped) ||
        (typeB.isColorBomb && typeA.isWrapped)) {
      final color = targetColor ?? _findColorOf(board, a, b);
      if (color != null) {
        final matchingPositions = _findPositionsOfColor(board, color);
        affected.addAll(matchingPositions);
        for (final pos in matchingPositions) {
          affected.addAll(_getAreaPositions(board, pos, radius: 1));
        }
      }
      return affected;
    }

    // 4. ColorBomb + Normal piece
    if (typeA.isColorBomb || typeB.isColorBomb) {
      final color = targetColor ?? _findColorOf(board, a, b);
      if (color != null) {
        affected.addAll(_findPositionsOfColor(board, color));
      }
      return affected;
    }

    // 5. Striped + Wrapped -> Giant 3-row by 3-column cross beam
    if ((typeA.isStriped && typeB.isWrapped) ||
        (typeB.isStriped && typeA.isWrapped)) {
      final center = b;
      for (var r = center.row - 1; r <= center.row + 1; r++) {
        if (r >= 0 && r < board.rows) {
          affected.addAll(_getRowPositions(board, r));
        }
      }
      for (var c = center.col - 1; c <= center.col + 1; c++) {
        if (c >= 0 && c < board.cols) {
          affected.addAll(_getColumnPositions(board, c));
        }
      }
      return affected;
    }

    // 6. Striped + Striped -> Cross clearance (entire row + entire column)
    if (typeA.isStriped && typeB.isStriped) {
      final center = b;
      affected.addAll(_getRowPositions(board, center.row));
      affected.addAll(_getColumnPositions(board, center.col));
      return affected;
    }

    // 7. Wrapped + Wrapped -> Massive 5x5 blast area
    if (typeA.isWrapped && typeB.isWrapped) {
      final center = b;
      affected.addAll(_getAreaPositions(board, center, radius: 2));
      return affected;
    }

    return affected;
  }

  /// Calculates positions affected by an individual special piece activation.
  Set<Position> getSingleSpecialAffectedPositions(
    Board board,
    Position pos,
    SpecialType special, {
    PieceType? targetColor,
  }) {
    final affected = <Position>{pos};

    switch (special) {
      case StripedHSpecial():
        affected.addAll(_getRowPositions(board, pos.row));
        break;
      case StripedVSpecial():
        affected.addAll(_getColumnPositions(board, pos.col));
        break;
      case WrappedSpecial():
        // Standard 3x3 blast area
        affected.addAll(_getAreaPositions(board, pos, radius: 1));
        break;
      case ColorBombSpecial():
        if (targetColor != null) {
          affected.addAll(_findPositionsOfColor(board, targetColor));
        }
        break;
      case NoneSpecial():
        break;
    }

    return affected;
  }

  // ---------------------------------------------------------------------------
  // Geometric position helpers
  // ---------------------------------------------------------------------------

  List<Position> _getRowPositions(Board board, int row) {
    final positions = <Position>[];
    for (var c = 0; c < board.cols; c++) {
      final p = Position(row, c);
      if (!board.cellAt(p).content.isBlocked) {
        positions.add(p);
      }
    }
    return positions;
  }

  List<Position> _getColumnPositions(Board board, int col) {
    final positions = <Position>[];
    for (var r = 0; r < board.rows; r++) {
      final p = Position(r, col);
      if (!board.cellAt(p).content.isBlocked) {
        positions.add(p);
      }
    }
    return positions;
  }

  List<Position> _getAreaPositions(Board board, Position center, {required int radius}) {
    final positions = <Position>[];
    for (var dr = -radius; dr <= radius; dr++) {
      for (var dc = -radius; dc <= radius; dc++) {
        final p = Position(center.row + dr, center.col + dc);
        if (board.isValidPosition(p) && !board.cellAt(p).content.isBlocked) {
          positions.add(p);
        }
      }
    }
    return positions;
  }

  PieceType? _findColorOf(Board board, Position a, Position b) {
    final pieceA = board.pieceAt(a);
    final pieceB = board.pieceAt(b);
    if (pieceA != null && !pieceA.specialType.isColorBomb) {
      return pieceA.pieceType;
    }
    if (pieceB != null && !pieceB.specialType.isColorBomb) {
      return pieceB.pieceType;
    }
    return null;
  }

  List<Position> _findPositionsOfColor(Board board, PieceType color) {
    final matching = <Position>[];
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final p = Position(r, c);
        final piece = board.pieceAt(p);
        if (piece != null && piece.pieceType == color) {
          matching.add(p);
        }
      }
    }
    return matching;
  }
}
