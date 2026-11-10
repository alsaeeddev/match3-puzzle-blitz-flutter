import 'package:flutter/foundation.dart';

/// The 6 base gem colors in Match-3 Blitz.
enum PieceType {
  red,
  orange,
  yellow,
  green,
  blue,
  purple,
}

/// Sealed hierarchy defining all special piece variants in the game.
sealed class SpecialType {
  const SpecialType();

  static const SpecialType none = NoneSpecial();
  static const SpecialType stripedH = StripedHSpecial();
  static const SpecialType stripedV = StripedVSpecial();
  static const SpecialType wrapped = WrappedSpecial();
  static const SpecialType colorBomb = ColorBombSpecial();

  bool get isNone => this is NoneSpecial;
  bool get isStripedH => this is StripedHSpecial;
  bool get isStripedV => this is StripedVSpecial;
  bool get isStriped => isStripedH || isStripedV;
  bool get isWrapped => this is WrappedSpecial;
  bool get isColorBomb => this is ColorBombSpecial;
  bool get isSpecial => !isNone;
}

final class NoneSpecial extends SpecialType {
  const NoneSpecial();
  @override
  String toString() => 'none';
}

final class StripedHSpecial extends SpecialType {
  const StripedHSpecial();
  @override
  String toString() => 'stripedH';
}

final class StripedVSpecial extends SpecialType {
  const StripedVSpecial();
  @override
  String toString() => 'stripedV';
}

final class WrappedSpecial extends SpecialType {
  const WrappedSpecial();
  @override
  String toString() => 'wrapped';
}

final class ColorBombSpecial extends SpecialType {
  const ColorBombSpecial();
  @override
  String toString() => 'colorBomb';
}

/// Immutable representation of a game piece (gem).
@immutable
class Piece {
  final String id;
  final PieceType pieceType;
  final SpecialType specialType;

  const Piece({
    required this.id,
    required this.pieceType,
    this.specialType = SpecialType.none,
  });

  Piece copyWith({
    String? id,
    PieceType? pieceType,
    SpecialType? specialType,
  }) {
    return Piece(
      id: id ?? this.id,
      pieceType: pieceType ?? this.pieceType,
      specialType: specialType ?? this.specialType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pieceType == other.pieceType &&
          specialType == other.specialType;

  @override
  int get hashCode => Object.hash(id, pieceType, specialType);

  @override
  String toString() => 'Piece($id, ${pieceType.name}, $specialType)';
}
