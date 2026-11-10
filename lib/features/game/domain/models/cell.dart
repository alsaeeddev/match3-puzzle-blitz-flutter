import 'package:flutter/foundation.dart';
import 'piece.dart';
import 'position.dart';

/// Types of obstacles that can occupy or overlay a cell.
enum ObstacleType {
  rock,
  wood,
  crate,
}

/// Sealed hierarchy defining the core occupancy/content of a cell.
sealed class CellContent {
  const CellContent();

  Piece? get piece => switch (this) {
        NormalCell(:final piece) => piece,
        _ => null,
      };

  bool get isEmpty => this is EmptyCell;
  bool get isBlocked => this is BlockedCell;
  bool get isObstacle => this is ObstacleCell;
  bool get isNormal => this is NormalCell;
}

/// A cell occupied by a standard game piece (gem).
final class NormalCell extends CellContent {
  @override
  final Piece piece;

  const NormalCell(this.piece);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalCell &&
          runtimeType == other.runtimeType &&
          piece == other.piece;

  @override
  int get hashCode => piece.hashCode;

  @override
  String toString() => 'NormalCell($piece)';
}

/// An empty cell ready to receive falling pieces.
final class EmptyCell extends CellContent {
  const EmptyCell();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptyCell && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'EmptyCell()';
}

/// A non-playable, impassable board void.
final class BlockedCell extends CellContent {
  const BlockedCell();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedCell && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'BlockedCell()';
}

/// A destructible obstacle cell (e.g. wooden crates, rocks).
final class ObstacleCell extends CellContent {
  final int hp;
  final ObstacleType type;

  const ObstacleCell({
    this.hp = 1,
    this.type = ObstacleType.crate,
  });

  ObstacleCell copyWith({
    int? hp,
    ObstacleType? type,
  }) {
    return ObstacleCell(
      hp: hp ?? this.hp,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObstacleCell &&
          runtimeType == other.runtimeType &&
          hp == other.hp &&
          type == other.type;

  @override
  int get hashCode => Object.hash(hp, type);

  @override
  String toString() => 'ObstacleCell(type: $type, hp: $hp)';
}

/// Complete immutable state of a single cell on the game grid.
@immutable
class CellState {
  final Position position;
  final CellContent content;
  final int jellyLayers; // 0, 1, or 2 layers
  final bool hasIce;
  final bool hasCrate;
  final bool isLocked;

  const CellState({
    required this.position,
    required this.content,
    this.jellyLayers = 0,
    this.hasIce = false,
    this.hasCrate = false,
    this.isLocked = false,
  }) : assert(
            jellyLayers >= 0 && jellyLayers <= 2, 'jellyLayers must be 0, 1, or 2');

  bool get hasJelly => jellyLayers > 0;
  bool get canSwap => content.isNormal && !isLocked && !hasIce;
  bool get canFallThrough => content.isEmpty;

  CellState copyWith({
    Position? position,
    CellContent? content,
    int? jellyLayers,
    bool? hasIce,
    bool? hasCrate,
    bool? isLocked,
  }) {
    return CellState(
      position: position ?? this.position,
      content: content ?? this.content,
      jellyLayers: jellyLayers ?? this.jellyLayers,
      hasIce: hasIce ?? this.hasIce,
      hasCrate: hasCrate ?? this.hasCrate,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellState &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          content == other.content &&
          jellyLayers == other.jellyLayers &&
          hasIce == other.hasIce &&
          hasCrate == other.hasCrate &&
          isLocked == other.isLocked;

  @override
  int get hashCode => Object.hash(
        position,
        content,
        jellyLayers,
        hasIce,
        hasCrate,
        isLocked,
      );

  @override
  String toString() =>
      'CellState($position, content: $content, jelly: $jellyLayers, ice: $hasIce, locked: $isLocked)';
}
