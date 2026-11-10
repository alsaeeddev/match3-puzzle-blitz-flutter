import 'dart:math';
import 'package:flutter/material.dart';
import 'package:match3_game/core/theme/gem_palette.dart';
import 'package:match3_game/features/game/domain/models/cell.dart';
import 'package:match3_game/features/game/domain/models/piece.dart';

/// Highly optimized custom painter rendering individual gems, obstacles,
/// special effects, selection outlines, and accessibility indicators.
class GemPainter extends CustomPainter {
  final CellState cell;
  final bool isSelected;
  final bool isHinted;
  final bool colorBlindMode;
  final double animValue;
  final double clearAnimValue;
  final double fallOffset;

  // Pre-allocated reusable Paint objects preventing per-frame heap allocations
  final Paint _bgPaint = Paint();
  final Paint _gemPaint = Paint();
  final Paint _overlayPaint = Paint();
  final Paint _specialPaint = Paint();
  final Paint _strokePaint = Paint();

  // Pre-allocated reusable path
  final Path _shapePath = Path();

  GemPainter({
    required this.cell,
    this.isSelected = false,
    this.isHinted = false,
    this.colorBlindMode = false,
    this.animValue = 0.0,
    this.clearAnimValue = 0.0,
    this.fallOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cornerRadius = Radius.circular(size.width * 0.16);
    final cellRRect = RRect.fromRectAndRadius(cellRect, cornerRadius);

    // 1. Draw Cell Background Grid Slot
    _bgPaint.shader = null;
    _bgPaint.style = PaintingStyle.fill;
    _bgPaint.color = const Color(0x22FFFFFF);
    canvas.drawRRect(cellRRect, _bgPaint);

    // If cell is an impassable blocked void, render dark hollow slot and exit
    if (cell.content.isBlocked) {
      _bgPaint.color = const Color(0x38000000);
      canvas.drawRRect(cellRRect, _bgPaint);
      return;
    }

    // 2. Destructible Obstacle (Wooden Crate)
    if (cell.content is ObstacleCell || cell.hasCrate) {
      _bgPaint.color = const Color(0xFF8D6E63);
      canvas.drawRRect(cellRRect, _bgPaint);

      _specialPaint.shader = null;
      _specialPaint.color = const Color(0xFF5D4037);
      _specialPaint.strokeWidth = 2.0;
      _specialPaint.style = PaintingStyle.stroke;
      canvas.drawRRect(cellRRect, _specialPaint);
      canvas.drawLine(cellRect.topLeft, cellRect.bottomRight, _specialPaint);
      canvas.drawLine(cellRect.topRight, cellRect.bottomLeft, _specialPaint);
    }

    // 3. Jelly Layer Underlay / Indicator
    if (cell.hasJelly) {
      _overlayPaint.shader = null;
      _overlayPaint.style = PaintingStyle.stroke;
      if (cell.jellyLayers == 1) {
        _overlayPaint.color = const Color(0x664FC3F7);
        _overlayPaint.strokeWidth = 3.0;
      } else {
        _overlayPaint.color = const Color(0xAA0288D1);
        _overlayPaint.strokeWidth = 6.0;
      }
      canvas.drawRRect(cellRRect.deflate(2), _overlayPaint);
    }

    // 4. Gem Piece Rendering
    final piece = cell.content.piece;
    if (piece != null) {
      canvas.save();

      // Gravity fall vertical offset translation
      if (fallOffset != 0.0) {
        canvas.translate(0, fallOffset);
      }

      // Clear / pop scale transformation
      if (clearAnimValue > 0.0) {
        final scale = (1.0 - clearAnimValue).clamp(0.0, 1.0);
        canvas.translate(size.width / 2, size.height / 2);
        canvas.scale(scale);
        canvas.translate(-size.width / 2, -size.height / 2);
      }

      final pad = size.width * 0.15;
      final gemRect = Rect.fromLTWH(
        pad,
        pad,
        size.width - pad * 2,
        size.height - pad * 2,
      );
      final center = gemRect.center;
      final radius = gemRect.width / 2;

      if (piece.specialType.isColorBomb) {
        // Multi-color cosmic swirl sphere
        _gemPaint.shader = null;
        _gemPaint.color = const Color(0xFF1A1A2E);
        _gemPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, _gemPaint);

        _specialPaint.style = PaintingStyle.stroke;
        _specialPaint.strokeWidth = radius * 0.32;
        const colorList = PieceType.values;
        for (var i = 0; i < colorList.length; i++) {
          final startAngle = i * (2 * pi / colorList.length);
          final sweepAngle = (2 * pi / colorList.length) * 0.85;
          _specialPaint.color = GemPalette.gemColor(colorList[i]);
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius * 0.72),
            startAngle,
            sweepAngle,
            false,
            _specialPaint,
          );
        }

        // Central bright starburst
        _specialPaint.color = Colors.white;
        _specialPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, radius * 0.28, _specialPaint);
      } else {
        // Regular gem or Striped/Wrapped special
        final primaryColor = GemPalette.gemColor(
          piece.pieceType,
          colorBlindMode: colorBlindMode,
        );
        final secondaryColor = GemPalette.gemSecondaryColor(piece.pieceType);

        _gemPaint.shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [primaryColor, secondaryColor],
        ).createShader(gemRect);
        _gemPaint.style = PaintingStyle.fill;

        final shape = GemPalette.gemShape(
          piece.pieceType,
          colorBlindMode: colorBlindMode,
        );
        _drawGemShape(canvas, shape, gemRect, center, radius, _gemPaint);

        // Special Variants Overlays
        if (piece.specialType.isStripedH) {
          _specialPaint.shader = null;
          _specialPaint.color = Colors.white.withValues(alpha: 0.85);
          _specialPaint.style = PaintingStyle.stroke;
          _specialPaint.strokeWidth = 2.5;
          canvas.drawLine(
            Offset(gemRect.left + 2, center.dy - radius * 0.42),
            Offset(gemRect.right - 2, center.dy - radius * 0.42),
            _specialPaint,
          );
          canvas.drawLine(
            Offset(gemRect.left, center.dy),
            Offset(gemRect.right, center.dy),
            _specialPaint,
          );
          canvas.drawLine(
            Offset(gemRect.left + 2, center.dy + radius * 0.42),
            Offset(gemRect.right - 2, center.dy + radius * 0.42),
            _specialPaint,
          );
        } else if (piece.specialType.isStripedV) {
          _specialPaint.shader = null;
          _specialPaint.color = Colors.white.withValues(alpha: 0.85);
          _specialPaint.style = PaintingStyle.stroke;
          _specialPaint.strokeWidth = 2.5;
          canvas.drawLine(
            Offset(center.dx - radius * 0.42, gemRect.top + 2),
            Offset(center.dx - radius * 0.42, gemRect.bottom - 2),
            _specialPaint,
          );
          canvas.drawLine(
            Offset(center.dx, gemRect.top),
            Offset(center.dx, gemRect.bottom),
            _specialPaint,
          );
          canvas.drawLine(
            Offset(center.dx + radius * 0.42, gemRect.top + 2),
            Offset(center.dx + radius * 0.42, gemRect.bottom - 2),
            _specialPaint,
          );
        } else if (piece.specialType.isWrapped) {
          _specialPaint.shader = null;
          _specialPaint.color = Colors.white.withValues(alpha: 0.85);
          _specialPaint.style = PaintingStyle.stroke;
          _specialPaint.strokeWidth = 2.2;
          canvas.drawCircle(center, radius * 0.82, _specialPaint);
          canvas.drawCircle(center, radius * 0.48, _specialPaint);
        }

        // Specular glossy reflection highlight
        _strokePaint.shader = null;
        _strokePaint.color = Colors.white.withValues(alpha: 0.38);
        _strokePaint.style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromLTWH(
            gemRect.left + radius * 0.3,
            gemRect.top + radius * 0.18,
            radius * 0.6,
            radius * 0.32,
          ),
          _strokePaint,
        );
      }

      canvas.restore();
    }

    // 5. Frozen Ice Overlay with Crack Lines
    if (cell.hasIce) {
      _overlayPaint.shader = null;
      _overlayPaint.color = const Color(0x66E0F7FA);
      _overlayPaint.style = PaintingStyle.fill;
      canvas.drawRRect(cellRRect, _overlayPaint);

      _specialPaint.shader = null;
      _specialPaint.color = Colors.white.withValues(alpha: 0.9);
      _specialPaint.style = PaintingStyle.stroke;
      _specialPaint.strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cellRect.left + 6, cellRect.top + 8),
        Offset(cellRect.center.dx - 2, cellRect.center.dy + 4),
        _specialPaint,
      );
      canvas.drawLine(
        Offset(cellRect.center.dx - 2, cellRect.center.dy + 4),
        Offset(cellRect.right - 8, cellRect.bottom - 6),
        _specialPaint,
      );
      canvas.drawLine(
        Offset(cellRect.center.dx + 4, cellRect.top + 4),
        Offset(cellRect.right - 4, cellRect.center.dy + 6),
        _specialPaint,
      );
    }

    // 6. Selected Piece Pulsing Outline
    if (isSelected) {
      final pulse = (0.5 + 0.5 * animValue);
      _strokePaint.shader = null;
      _strokePaint.color =
          Colors.amberAccent.withValues(alpha: 0.7 + 0.3 * animValue);
      _strokePaint.style = PaintingStyle.stroke;
      _strokePaint.strokeWidth = 2.5 + 2.0 * pulse;
      canvas.drawRRect(cellRRect.deflate(1.5), _strokePaint);
    }

    // 7. Hint Shimmer Gold Glow
    if (isHinted && !isSelected) {
      _strokePaint.shader = null;
      _strokePaint.color =
          const Color(0xFFFFD700).withValues(alpha: 0.6 + 0.4 * animValue);
      _strokePaint.style = PaintingStyle.stroke;
      _strokePaint.strokeWidth = 3.0;
      canvas.drawRRect(cellRRect.deflate(1.5), _strokePaint);
    }
  }

  void _drawGemShape(
    Canvas canvas,
    GemShape shape,
    Rect rect,
    Offset center,
    double radius,
    Paint paint,
  ) {
    switch (shape) {
      case GemShape.circle:
        canvas.drawCircle(center, radius, paint);

      case GemShape.diamond:
        _shapePath.reset();
        _shapePath.moveTo(center.dx, rect.top);
        _shapePath.lineTo(rect.right, center.dy);
        _shapePath.lineTo(center.dx, rect.bottom);
        _shapePath.lineTo(rect.left, center.dy);
        _shapePath.close();
        canvas.drawPath(_shapePath, paint);

      case GemShape.hexagon:
        _shapePath.reset();
        for (var i = 0; i < 6; i++) {
          final angle = (i * pi / 3) - (pi / 6);
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          if (i == 0) {
            _shapePath.moveTo(x, y);
          } else {
            _shapePath.lineTo(x, y);
          }
        }
        _shapePath.close();
        canvas.drawPath(_shapePath, paint);

      case GemShape.star:
        _shapePath.reset();
        const numPoints = 5;
        final innerRadius = radius * 0.48;
        for (var i = 0; i < numPoints * 2; i++) {
          final r = i.isEven ? radius : innerRadius;
          final angle = (i * pi / numPoints) - (pi / 2);
          final x = center.dx + r * cos(angle);
          final y = center.dy + r * sin(angle);
          if (i == 0) {
            _shapePath.moveTo(x, y);
          } else {
            _shapePath.lineTo(x, y);
          }
        }
        _shapePath.close();
        canvas.drawPath(_shapePath, paint);

      case GemShape.triangle:
        _shapePath.reset();
        _shapePath.moveTo(center.dx, rect.top);
        _shapePath.lineTo(rect.right, rect.bottom);
        _shapePath.lineTo(rect.left, rect.bottom);
        _shapePath.close();
        canvas.drawPath(_shapePath, paint);

      case GemShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.3)),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant GemPainter oldDelegate) {
    return cell != oldDelegate.cell ||
        isSelected != oldDelegate.isSelected ||
        isHinted != oldDelegate.isHinted ||
        colorBlindMode != oldDelegate.colorBlindMode ||
        animValue != oldDelegate.animValue ||
        clearAnimValue != oldDelegate.clearAnimValue ||
        fallOffset != oldDelegate.fallOffset;
  }
}
