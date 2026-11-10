import 'package:flutter/material.dart';
import 'package:match3_game/core/constants/game_config.dart';
import 'package:match3_game/features/game/domain/models/cell.dart';
import 'package:match3_game/features/game/domain/models/position.dart';
import 'package:match3_game/features/game/presentation/painters/gem_painter.dart';

// Interactive animated widget representing a single gem cell on the board.
// Orchestrates pulse, gravity fall, spawn scale-in, and clear pop animations.
class GemWidget extends StatefulWidget {
  final CellState cell;
  final Position position;
  final bool isSelected;
  final bool isHinted;
  final bool colorBlindMode;
  final VoidCallback? onTap;
  final Offset? fallFromOffset;
  final bool isClearAnimating;
  final bool isSpawnAnimating;
  final double size;

  const GemWidget({
    super.key,
    required this.cell,
    required this.position,
    this.isSelected = false,
    this.isHinted = false,
    this.colorBlindMode = false,
    this.onTap,
    this.fallFromOffset,
    this.isClearAnimating = false,
    this.isSpawnAnimating = false,
    required this.size,
  });

  @override
  State<GemWidget> createState() => _GemWidgetState();
}

class _GemWidgetState extends State<GemWidget> with TickerProviderStateMixin {
  late final AnimationController _selectionController;
  late final AnimationController _clearController;
  late final AnimationController _fallController;
  late final AnimationController _spawnController;

  late final Animation<double> _selectionAnimation;
  late final Animation<double> _clearAnimation;
  late final Animation<double> _fallAnimation;
  late final Animation<double> _spawnAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Selection & Hint Pulse Animation
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    );
    if (widget.isSelected || widget.isHinted) {
      _selectionController.repeat(reverse: true);
    }

    // 2. Clear / Pop Scale-out Animation
    _clearController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: GameConfig.matchClearDurationMs),
    );
    _clearAnimation = CurvedAnimation(
      parent: _clearController,
      curve: Curves.easeInBack,
    );
    if (widget.isClearAnimating) {
      _clearController.forward();
    }

    // 3. Gravity Fall Slide Animation
    _fallController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: GameConfig.gravityFallDurationMs),
    );
    _fallAnimation = CurvedAnimation(
      parent: _fallController,
      curve: Curves.easeOutQuad,
    );
    if (widget.fallFromOffset != null) {
      _fallController.forward();
    } else {
      _fallController.value = 1.0;
    }

    // 4. Spawn Scale-in Animation
    _spawnController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: GameConfig.refillFallDurationMs),
    );
    _spawnAnimation = CurvedAnimation(
      parent: _spawnController,
      curve: Curves.elasticOut,
    );
    if (widget.isSpawnAnimating) {
      _spawnController.forward();
    } else {
      _spawnController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant GemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Pulse trigger
    if ((widget.isSelected || widget.isHinted) &&
        !_selectionController.isAnimating) {
      _selectionController.repeat(reverse: true);
    } else if (!widget.isSelected &&
        !widget.isHinted &&
        _selectionController.isAnimating) {
      _selectionController.stop();
      _selectionController.reset();
    }

    // Clear pop trigger
    if (widget.isClearAnimating && !oldWidget.isClearAnimating) {
      _clearController.forward(from: 0.0);
    } else if (!widget.isClearAnimating && oldWidget.isClearAnimating) {
      _clearController.reset();
    }

    // Fall trigger
    if (widget.fallFromOffset != null &&
        widget.fallFromOffset != oldWidget.fallFromOffset) {
      _fallController.forward(from: 0.0);
    }

    // Spawn trigger
    if (widget.isSpawnAnimating && !oldWidget.isSpawnAnimating) {
      _spawnController.forward(from: 0.0);
    }

    // Cell content change: reset clear controller so new piece is immediately visible
    if (widget.cell.content != oldWidget.cell.content && !widget.isClearAnimating) {
      _clearController.reset();
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _clearController.dispose();
    _fallController.dispose();
    _spawnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.cell.content.piece;
    final colorName = piece?.pieceType.name ?? 'empty';
    final specialDesc = piece != null && piece.specialType.isSpecial
        ? ' ${piece.specialType}'
        : '';
    final semanticLabel =
        'Gem $colorName$specialDesc at row ${widget.position.row} col ${widget.position.col}';

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: widget.cell.canSwap,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _selectionAnimation,
              _clearAnimation,
              _fallAnimation,
              _spawnAnimation,
            ]),
            builder: (context, child) {
              final fallOffset = widget.fallFromOffset != null
                  ? widget.fallFromOffset!.dy * (1.0 - _fallAnimation.value)
                  : 0.0;

              final spawnScale = widget.isSpawnAnimating
                  ? _spawnAnimation.value.clamp(0.0, 1.2)
                  : 1.0;
              final clearScale = widget.isClearAnimating
                  ? (1.0 - _clearAnimation.value).clamp(0.0, 1.0)
                  : 1.0;
              final netScale = spawnScale * clearScale;

              return Transform.translate(
                offset: Offset(0, fallOffset),
                child: Transform.scale(
                  scale: netScale,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: GemPainter(
                      cell: widget.cell,
                      isSelected: widget.isSelected,
                      isHinted: widget.isHinted,
                      colorBlindMode: widget.colorBlindMode,
                      animValue: _selectionAnimation.value,
                      clearAnimValue: _clearAnimation.value,
                      fallOffset: 0.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

