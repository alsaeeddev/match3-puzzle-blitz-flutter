import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/features/game/presentation/providers/game_providers.dart';

/// Top Heads-Up Display (HUD) showing moves/timer, score counter, star progress, and pause controls.
class HudWidget extends ConsumerWidget {
  final int levelId;
  final VoidCallback? onPause;

  const HudWidget({
    super.key,
    required this.levelId,
    this.onPause,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider(levelId));
    final config = gameState.levelConfig;
    final movesLeft = gameState.movesLeft;
    final score = gameState.score;
    final isMovesLow = movesLeft <= 5;

    final thresholds = config.starThresholds.length == 3
        ? config.starThresholds
        : const [1000, 2500, 4500];
    final maxScoreThreshold = thresholds.last;
    final progressFraction = (score / maxScoreThreshold).clamp(0.0, 1.0);

    final starsEarned = score >= thresholds[2]
        ? 3
        : (score >= thresholds[1] ? 2 : (score >= thresholds[0] ? 1 : 0));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Level Title, Stars indicator, Pause button
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Level ${config.id}: ${config.name}',
                  child: Text(
                    'Level ${config.id} - ${config.name}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Semantics(
                label: 'Stars earned: $starsEarned out of 3',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final earned = index < starsEarned;
                    return Icon(
                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: earned ? const Color(0xFFFFD54F) : Colors.white24,
                      size: 22,
                    );
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                label: 'Pause game',
                button: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: onPause,
                    icon: const Icon(
                      Icons.pause_circle_filled_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Pause',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxs),

          // Middle Row: Prominent Moves / Timer & Animated Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Moves / Time Box
              Semantics(
                label: gameState.timeLeft != null
                    ? '${gameState.timeLeft} seconds remaining'
                    : '$movesLeft moves remaining',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isMovesLow
                        ? const Color(0x44F44336)
                        : const Color(0x22FFFFFF),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isMovesLow
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gameState.timeLeft != null ? 'TIME' : 'MOVES',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isMovesLow
                              ? Colors.redAccent
                              : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isMovesLow)
                        _PulseWidget(
                          child: Text(
                            gameState.timeLeft != null
                                ? '${gameState.timeLeft}s'
                                : '$movesLeft',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: isMovesLow
                                  ? Colors.redAccent
                                  : Colors.white,
                              height: 1.1,
                            ),
                          ),
                        )
                      else
                        Text(
                          gameState.timeLeft != null
                              ? '${gameState.timeLeft}s'
                              : '$movesLeft',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isMovesLow
                                ? Colors.redAccent
                                : Colors.white,
                            height: 1.1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Animated Score Counter
              Semantics(
                label: 'Current score: $score points',
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, animatedScore, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SCORE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _formatScore(animatedScore),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD54F),
                            height: 1.1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Bottom Row: Star Threshold Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Background track
                  Container(
                    height: 10,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: AppRadius.borderPill,
                    ),
                  ),

                  // Filled track
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 10,
                    width: barWidth * progressFraction,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB300),
                          Color(0xFFFFD54F),
                        ],
                      ),
                      borderRadius: AppRadius.borderPill,
                    ),
                  ),

                  // 3 Milestone Star Nodes
                  for (var i = 0; i < thresholds.length; i++)
                    Positioned(
                      left: (thresholds[i] / maxScoreThreshold) * barWidth - 8,
                      child: _StarNode(
                        key: ValueKey('star_$i'),
                        earned: score >= thresholds[i],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _formatScore(int score) {
    if (score < 1000) return '$score';
    final str = score.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}

// ---------------------------------------------------------------------------
// _PulseWidget — repeating scale pulse for low-move warning
// ---------------------------------------------------------------------------

class _PulseWidget extends StatefulWidget {
  final Widget child;
  const _PulseWidget({required this.child});
  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final firstView = views.isNotEmpty ? views.first : null;
    final disableAnimations = firstView != null
        ? MediaQueryData.fromView(firstView).disableAnimations
        : false;
    if (!disableAnimations) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable) return widget.child;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// _StarNode — animated star milestone on the progress bar
// ---------------------------------------------------------------------------

class _StarNode extends StatefulWidget {
  final bool earned;
  const _StarNode({super.key, required this.earned});
  @override
  State<_StarNode> createState() => _StarNodeState();
}

class _StarNodeState extends State<_StarNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _wasEarned = false;

  @override
  void initState() {
    super.initState();
    _wasEarned = widget.earned;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.value = 1.0; // start at full scale
  }

  @override
  void didUpdateWidget(_StarNode old) {
    super.didUpdateWidget(old);
    if (widget.earned && !_wasEarned) {
      _wasEarned = true;
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
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.earned ? const Color(0xFFFFD54F) : const Color(0xFF4A3469),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(
          Icons.star,
          size: 10,
          color: widget.earned ? const Color(0xFF2C1B4D) : Colors.white38,
        ),
      ),
    );
  }
}
