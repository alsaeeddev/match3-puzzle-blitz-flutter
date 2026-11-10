import 'package:flutter/material.dart';
import 'package:match3_game/features/game/domain/models/piece.dart';

// Geometric shapes associated with each gem color for visual clarity and accessibility.
enum GemShape {
  circle,
  diamond,
  hexagon,
  star,
  triangle,
  square,
}

// Color system and shape mapping for Match-3 Blitz pieces.
class GemPalette {
  GemPalette._();

  // Primary vibrant color for [type].
  static Color gemColor(PieceType type, {bool colorBlindMode = false}) {
    return switch (type) {
      PieceType.red => Colors.red[400]!,
      PieceType.orange => Colors.orange[400]!,
      PieceType.yellow => Colors.yellow[400]!,
      PieceType.green => Colors.green[400]!,
      PieceType.blue => Colors.blue[400]!,
      PieceType.purple => Colors.purple[400]!,
    };
  }

  // Darker accent color used for radial gradients and shading.
  static Color gemSecondaryColor(PieceType type) {
    return switch (type) {
      PieceType.red => Colors.red[700]!,
      PieceType.orange => Colors.deepOrange[600]!,
      PieceType.yellow => Colors.amber[600]!,
      PieceType.green => Colors.green[700]!,
      PieceType.blue => Colors.blue[800]!,
      PieceType.purple => Colors.purple[800]!,
    };
  }

  // Geometric shape assignment providing distinct silhouettes for color-blind accessibility.
  // Red=Circle, Orange=Diamond, Yellow=Hexagon, Green=Star, Blue=Triangle, Purple=Square.
  static GemShape gemShape(PieceType type, {bool colorBlindMode = false}) {
    return switch (type) {
      PieceType.red => GemShape.circle,
      PieceType.orange => GemShape.diamond,
      PieceType.yellow => GemShape.hexagon,
      PieceType.green => GemShape.star,
      PieceType.blue => GemShape.triangle,
      PieceType.purple => GemShape.square,
    };
  }
}

