import 'package:flutter/material.dart';
import 'package:match3_game/features/game/domain/models/board.dart';

/// Custom painter dedicated exclusively to static board grid rendering.
///
/// Draws the outer rounded container, individual tile slots, and blocked void cells.
/// Designed to be enclosed within a [RepaintBoundary] so it repaints only upon board layout changes.
class BoardPainter extends CustomPainter {
  final Board board;
  final double cellSize;
  final Color backgroundColor;
  final Color cellColor;
  final Color blockedColor;

  final Paint _bgPaint = Paint();
  final Paint _cellPaint = Paint();
  final Paint _blockedPaint = Paint();

  BoardPainter({
    required this.board,
    required this.cellSize,
    this.backgroundColor = const Color(0xFF231640),
    this.cellColor = const Color(0x2EFFFFFF),
    this.blockedColor = const Color(0x38000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalWidth = board.cols * cellSize;
    final totalHeight = board.rows * cellSize;

    // 1. Board Background Outer Rounded Panel
    final boardRect = Rect.fromLTWH(0, 0, totalWidth, totalHeight);
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(cellSize * 0.22),
    );

    _bgPaint.color = backgroundColor;
    _bgPaint.style = PaintingStyle.fill;
    canvas.drawRRect(boardRRect, _bgPaint);

    _cellPaint.color = cellColor;
    _cellPaint.style = PaintingStyle.fill;

    _blockedPaint.color = blockedColor;
    _blockedPaint.style = PaintingStyle.fill;

    final cellCornerRadius = Radius.circular(cellSize * 0.16);

    // 2. Individual Grid Slot Recesses
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final cell = board.cells[r][c];
        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );
        final cellRRect = RRect.fromRectAndRadius(
          rect.deflate(2.0),
          cellCornerRadius,
        );

        if (cell.content.isBlocked) {
          canvas.drawRRect(cellRRect, _blockedPaint);
        } else {
          canvas.drawRRect(cellRRect, _cellPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return !identical(board, oldDelegate.board) ||
        cellSize != oldDelegate.cellSize ||
        backgroundColor != oldDelegate.backgroundColor ||
        cellColor != oldDelegate.cellColor ||
        blockedColor != oldDelegate.blockedColor;
  }
}

