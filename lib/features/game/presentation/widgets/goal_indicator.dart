import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/core/theme/gem_palette.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/game/presentation/providers/game_providers.dart';

// Horizontal compact status row displaying progress toward all required level goals.
class GoalIndicator extends ConsumerWidget {
  final int levelId;

  const GoalIndicator({
    super.key,
    required this.levelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider(levelId));
    final config = gameState.levelConfig;
    final progress = gameState.goalProgress;

    // Total jelly count across the board
    var totalJelly = 0;
    for (final layers in config.layout.jellyGrid.values) {
      totalJelly += layers;
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < config.goals.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: _GoalItemWidget(
                goal: config.goals[i],
                current: progress[config.goals[i].id] ?? 0,
                totalScore: gameState.score,
                totalJelly: totalJelly,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalItemWidget extends StatefulWidget {
  final LevelGoal goal;
  final int current;
  final int totalScore;
  final int totalJelly;

  const _GoalItemWidget({
    required this.goal,
    required this.current,
    required this.totalScore,
    required this.totalJelly,
  });

  @override
  State<_GoalItemWidget> createState() => _GoalItemWidgetState();
}

class _GoalItemWidgetState extends State<_GoalItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _wasComplete = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _wasComplete = _isComplete;
    _ctrl.value = 1.0;
  }

  bool get _isComplete => switch (widget.goal) {
        TargetScore(:final targetScore) => widget.totalScore >= targetScore,
        CollectPieces(:final count) => widget.current >= count,
        ClearAllJelly() => widget.current >= widget.totalJelly,
        DropIngredients(:final count) => widget.current >= count,
      };

  @override
  void didUpdateWidget(_GoalItemWidget old) {
    super.didUpdateWidget(old);
    if (_isComplete && !_wasComplete) {
      _wasComplete = true;
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _isComplete;

    final (Widget icon, String labelText) = switch (widget.goal) {
      TargetScore(:final targetScore) => (
          const Text('🎯 ', style: TextStyle(fontSize: 24)),
          '${widget.totalScore} / $targetScore',
        ),
      CollectPieces(:final pieceType, :final count) => (
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: GemPalette.gemColor(pieceType),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          '${min(widget.current, count)} / $count',
        ),
      ClearAllJelly() => (
          const Icon(Icons.layers_rounded, color: Color(0xFF4FC3F7), size: 24),
          (widget.totalJelly - widget.current) <= 0
              ? 'Cleared!'
              : '${max(0, widget.totalJelly - widget.current)} left',
        ),
      DropIngredients(:final count) => (
          const Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 24),
          '${min(widget.current, count)} / $count',
        ),
    };

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: _scale.value, child: child!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 44, // dono pills ki height same
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0x334CAF50) : const Color(0x22FFFFFF),
          borderRadius: AppRadius.borderPill,
          border: Border.all(
            color: isComplete ? Colors.greenAccent : const Color(0x33FFFFFF),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labelText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isComplete ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (isComplete) ...[
              const SizedBox(width: AppSpacing.xxs),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
