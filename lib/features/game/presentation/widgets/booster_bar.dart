import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/presentation/providers/game_providers.dart';

/// Bottom tool bar presenting actionable player boosters (Hammer, Shuffle, +5 Moves, Color Swap).
class BoosterBar extends ConsumerWidget {
  final int levelId;

  const BoosterBar({
    super.key,
    required this.levelId,
  });

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider(levelId));
    final isAnimating = ref.watch(isAnimatingProvider(levelId));
    final activeBooster = gameState.activeBooster;
    final inventory = gameState.boosterInventory;

    const boosters = [
      BoosterType.hammer,
      BoosterType.shuffle,
      BoosterType.plusFiveMoves,
      BoosterType.colorSwap,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: boosters.map((type) {
              final count = inventory[type] ?? 0;
              final isArmed = activeBooster == type;
              final isEnabled =
                  count > 0 && !isAnimating && !gameState.isGameOver;

              return Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _BoosterButton(
                      type: type,
                      count: count,
                      isArmed: isArmed,
                      isEnabled: isEnabled,
                      onTap: () {
                        if (isAnimating || gameState.isGameOver) return;
                        if (count <= 0) {
                          // TODO: Show rewarded ad or prompt shop flow
                          return;
                        }
                        if (!isArmed) {
                          ref.read(audioServiceProvider).playButtonTap();
                        }
                        ref
                            .read(gameNotifierProvider(levelId).notifier)
                            .toggleBooster(type);
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  final BoosterType type;
  final int count;
  final bool isArmed;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _BoosterButton({
    required this.type,
    required this.count,
    required this.isArmed,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = switch (type) {
      BoosterType.hammer => 'Hammer',
      BoosterType.shuffle => 'Shuffle',
      BoosterType.plusFiveMoves => '+5 Moves',
      BoosterType.colorSwap => 'Color Swap',
    };

    // When armed, label shows "Tap a gem" in amberAccent; otherwise the normal name.
    // Both are wrapped in a fixed-height SizedBox so toggling never causes layout shift.
    final labelText = isArmed ? 'Tap a gem' : name;
    final labelColor = isArmed ? Colors.amberAccent : Colors.white70;

    return Semantics(
      label: '$name booster, $count remaining',
      button: true,
      enabled: isEnabled,
      child: SizedBox(
        width: 64,
        height: 80,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isEnabled ? 1.0 : 0.45,
              child: AnimatedScale(
                scale: isArmed ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main Booster Icon Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isArmed
                                ? const Color(0xFF5E35B1)
                                : const Color(0x2EFFFFFF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isArmed
                                  ? Colors.amberAccent
                                  : Colors.white.withValues(alpha: 0.3),
                              width: isArmed ? 2.5 : 1.2,
                            ),
                            boxShadow: isArmed
                                ? [
                                    const BoxShadow(
                                      color: Colors.amberAccent,
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(34, 34),
                              painter: _buildBoosterPainter(type),
                            ),
                          ),
                        ),

                        // Stock Count Badge
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: !isEnabled
                                  ? Colors.grey
                                  : const Color(0xFFEF5350),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // Fixed-height label row: width/height never changes on arm/disarm.
                    SizedBox(
                      height: 14,
                      child: Text(
                        labelText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: labelColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  CustomPainter _buildBoosterPainter(BoosterType type) {
    return switch (type) {
      BoosterType.hammer => const _HammerPainter(),
      BoosterType.shuffle => const _ShufflePainter(),
      BoosterType.plusFiveMoves => const _PlusFiveMovesPainter(),
      BoosterType.colorSwap => const _ColorSwapPainter(),
    };
  }
}

/// Custom painter rendering a vector hammer icon.
class _HammerPainter extends CustomPainter {
  const _HammerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final headPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;

    final handlePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-pi / 4);

    // Hammer Head (horizontal rect)
    final headRect = Rect.fromCenter(
      center: const Offset(0, -7),
      width: 20,
      height: 9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(2)),
      headPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(2)),
      outlinePaint,
    );

    // Hammer Handle (vertical shaft)
    final handleRect = Rect.fromCenter(
      center: const Offset(0, 4),
      width: 5,
      height: 16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(2)),
      handlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(2)),
      outlinePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter rendering circular rotation arrows for the shuffle booster.
class _ShufflePainter extends CustomPainter {
  const _ShufflePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Top arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.2,
      pi * 0.7,
      false,
      paint,
    );

    // Bottom arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 1.2,
      pi * 0.7,
      false,
      paint,
    );

    // Arrow heads
    final arrowPaint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..style = PaintingStyle.fill;

    final arrow1 = Path()
      ..moveTo(center.dx + radius * cos(pi * 0.9) - 3, center.dy + radius * sin(pi * 0.9) - 5)
      ..lineTo(center.dx + radius * cos(pi * 0.9) + 4, center.dy + radius * sin(pi * 0.9))
      ..lineTo(center.dx + radius * cos(pi * 0.9) + 2, center.dy + radius * sin(pi * 0.9) + 6)
      ..close();
    canvas.drawPath(arrow1, arrowPaint);

    final arrow2 = Path()
      ..moveTo(center.dx + radius * cos(pi * 1.9) + 3, center.dy + radius * sin(pi * 1.9) + 5)
      ..lineTo(center.dx + radius * cos(pi * 1.9) - 4, center.dy + radius * sin(pi * 1.9))
      ..lineTo(center.dx + radius * cos(pi * 1.9) - 2, center.dy + radius * sin(pi * 1.9) - 6)
      ..close();
    canvas.drawPath(arrow2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter rendering "+5" text against a star emblem.
class _PlusFiveMovesPainter extends CustomPainter {
  const _PlusFiveMovesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background star
    final starPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    final path = Path();
    const numPoints = 5;
    final outerRadius = size.width * 0.46;
    final innerRadius = outerRadius * 0.52;

    for (var i = 0; i < numPoints * 2; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / numPoints) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);

    // "+5" text inside
    const textSpan = TextSpan(
      text: '+5',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Color(0xFF2C1B4D),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter rendering two overlapping colored spheres.
class _ColorSwapPainter extends CustomPainter {
  const _ColorSwapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    final redPaint = Paint()
      ..color = const Color(0xFFEF5350).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final bluePaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left circle
    canvas.drawCircle(Offset(center.dx - radius * 0.45, center.dy), radius, redPaint);
    canvas.drawCircle(Offset(center.dx - radius * 0.45, center.dy), radius, outlinePaint);

    // Right circle
    canvas.drawCircle(Offset(center.dx + radius * 0.45, center.dy), radius, bluePaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.45, center.dy), radius, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
