import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/rewards/domain/models/daily_reward.dart';
import 'package:match3_game/features/rewards/presentation/providers/reward_providers.dart';
import 'package:match3_game/features/shop/presentation/providers/shop_providers.dart';

/// Interactive modal dialog displaying the 7-day streak login reward calendar.
class DailyRewardDialog extends ConsumerStatefulWidget {
  const DailyRewardDialog({super.key});

  /// Displays the daily reward dialog as a modal bottom sheet or dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DailyRewardDialog(),
    );
  }

  @override
  ConsumerState<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<DailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final success =
          await ref.read(rewardNotifierProvider.notifier).claimReward();
      if (success) {
        // Refresh coins and booster inventories
        ref.read(coinsProvider.notifier).refresh();
        ref.read(boosterInventoryProvider.notifier).refresh();

        if (mounted) {
          final strings = ref.read(stringsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.purchaseSuccess),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final rewardStateAsync = ref.watch(rewardNotifierProvider);
    final theme = Theme.of(context);

    final rewardState = rewardStateAsync.value ?? const DailyRewardState();
    final canClaim = rewardState.canClaimToday;
    final activeDay = rewardState.nextClaimDay;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E38),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    strings.dailyRewardTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              Text(
                canClaim ? strings.claimNow : strings.comeBackTomorrow,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: canClaim ? const Color(0xFFFFD700) : Colors.white60,
                  fontWeight: canClaim ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 7 Day Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // Days 1 to 6
                      for (int day = 1; day <= 6; day++)
                        _buildDayCard(
                          day: day,
                          activeDay: activeDay,
                          currentStreak: rewardState.currentStreak,
                          canClaim: canClaim,
                          tier: kRewardTiers[day - 1],
                          width: (constraints.maxWidth - 32) / 3,
                          strings: strings,
                        ),

                      // Day 7 Grand Reward
                      _buildDay7Card(
                        activeDay: activeDay,
                        currentStreak: rewardState.currentStreak,
                        canClaim: canClaim,
                        tier: kRewardTiers[6],
                        width: constraints.maxWidth - 16,
                        strings: strings,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: canClaim && !_isClaiming ? _claimReward : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          canClaim ? strings.claimReward : strings.rewardClaimed,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required int activeDay,
    required int currentStreak,
    required bool canClaim,
    required DailyRewardTier tier,
    required double width,
    required AppStrings strings,
  }) {
    final isClaimed = day <= currentStreak && !canClaim;
    final isToday = day == activeDay && canClaim;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isToday ? (1.0 + 0.04 * _pulseController.value) : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: width,
        height: 100,
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFF2E2A5C)
              : isClaimed
                  ? const Color(0xFF16152B)
                  : const Color(0xFF262445),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isToday
                ? const Color(0xFFFFD700)
                : isClaimed
                    ? Colors.green.shade600
                    : Colors.white12,
            width: isToday ? 2.0 : 1.0,
          ),
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              strings.dayNumber(day),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToday ? const Color(0xFFFFD700) : Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            _buildRewardIcon(tier),
            const SizedBox(height: 4),
            Text(
              _getRewardDescription(tier),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isClaimed) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDay7Card({
    required int activeDay,
    required int currentStreak,
    required bool canClaim,
    required DailyRewardTier tier,
    required double width,
    required AppStrings strings,
  }) {
    final isClaimed = 7 <= currentStreak && !canClaim;
    final isToday = activeDay == 7 && canClaim;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [const Color(0xFF7B1FA2), const Color(0xFFE91E63)]
              : [const Color(0xFF311B92), const Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: isToday ? 2.5 : 1.0,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFD700), size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${strings.dayNumber(7)} - ${strings.grandReward}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const Text(
                    '500 Coins + 8 Boosters + 5 Lives',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else if (isToday)
            const Icon(Icons.lock_open, color: Color(0xFFFFD700), size: 24)
          else
            const Icon(Icons.lock, color: Colors.white38, size: 22),
        ],
      ),
    );
  }

  Widget _buildRewardIcon(DailyRewardTier tier) {
    if (tier.coins > 0) {
      return const Icon(Icons.monetization_on,
          color: Color(0xFFFFD700), size: 24);
    } else if (tier.lives > 0) {
      return const Icon(Icons.favorite, color: Color(0xFFFF5252), size: 24);
    } else if (tier.boosters.containsKey(BoosterType.hammer)) {
      return const Icon(Icons.gavel, color: Colors.cyanAccent, size: 24);
    } else if (tier.boosters.containsKey(BoosterType.shuffle)) {
      return const Icon(Icons.shuffle, color: Colors.purpleAccent, size: 24);
    } else {
      return const Icon(Icons.add_circle,
          color: Colors.lightGreenAccent, size: 24);
    }
  }

  String _getRewardDescription(DailyRewardTier tier) {
    if (tier.coins > 0) return '+${tier.coins}';
    if (tier.lives > 0) return '+${tier.lives} Lives';
    if (tier.boosters.isNotEmpty) {
      final entry = tier.boosters.entries.first;
      return '+${entry.value} ${_boosterName(entry.key)}';
    }
    return '';
  }

  String _boosterName(BoosterType type) {
    switch (type) {
      case BoosterType.hammer:
        return 'Hammer';
      case BoosterType.shuffle:
        return 'Shuffle';
      case BoosterType.plusFiveMoves:
        return '+5 Moves';
      case BoosterType.colorSwap:
        return 'Bomb';
    }
  }
}

