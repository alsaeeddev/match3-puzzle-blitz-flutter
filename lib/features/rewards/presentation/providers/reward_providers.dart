import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/constants/app_constants.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/features/rewards/domain/models/daily_reward.dart';

/// Async notifier managing the daily login reward streak and claim cycles.
class RewardNotifier extends AsyncNotifier<DailyRewardState> {
  static const String _rewardStateKey = 'daily_reward_state';

  @override
  Future<DailyRewardState> build() async {
    final storage = ref.watch(storageServiceProvider);
    final json = await storage.getJson(_rewardStateKey);
    if (json != null) {
      try {
        return DailyRewardState.fromJson(json);
      } catch (_) {}
    }

    // Fallback reading from legacy individual keys
    final lastClaimStr =
        await storage.getString(AppConstants.keyDailyRewardLastClaimed);
    final streak =
        await storage.getInt(AppConstants.keyDailyRewardStreak) ?? 0;
    final lastClaim =
        lastClaimStr != null ? DateTime.tryParse(lastClaimStr) : null;

    return DailyRewardState(
      lastClaimDate: lastClaim,
      currentStreak: streak,
    );
  }

  /// Claims today's scheduled reward tier, awarding coins, boosters, and lives.
  /// Returns `true` if claimed successfully, or `false` if already claimed today.
  Future<bool> claimReward() async {
    final current = state.value ?? const DailyRewardState();
    if (!current.canClaimToday) {
      return false;
    }

    final nextDay = current.nextClaimDay;
    final tier = kRewardTiers.firstWhere(
      (t) => t.day == nextDay,
      orElse: () => kRewardTiers.first,
    );

    final gameRepo = ref.read(gameRepositoryProvider);
    final livesService = ref.read(livesServiceProvider);
    final audioService = ref.read(audioServiceProvider);
    final analyticsService = ref.read(analyticsServiceProvider);
    final storage = ref.read(storageServiceProvider);

    // 1. Award coins
    if (tier.coins > 0) {
      await gameRepo.addCoins(tier.coins);
    }

    // 2. Award boosters
    if (tier.boosters.isNotEmpty) {
      final inventory = await gameRepo.getBoosterInventory();
      for (final entry in tier.boosters.entries) {
        inventory[entry.key] = (inventory[entry.key] ?? 0) + entry.value;
      }
      await gameRepo.saveBoosterInventory(inventory);
    }

    // 3. Award lives
    if (tier.lives > 0) {
      await livesService.addLives(tier.lives);
    }

    // 4. Play audio and log analytics
    await audioService.playDailyReward();
    await analyticsService.logDailyRewardClaimed(nextDay);

    // 5. Update state & storage
    final newState = DailyRewardState(
      lastClaimDate: DateTime.now(),
      currentStreak: nextDay,
    );

    await storage.setJson(_rewardStateKey, newState.toJson());
    await storage.setString(
      AppConstants.keyDailyRewardLastClaimed,
      newState.lastClaimDate!.toIso8601String(),
    );
    await storage.setInt(AppConstants.keyDailyRewardStreak, nextDay);

    state = AsyncData(newState);
    return true;
  }
}

/// Global provider for daily reward claim state.
final rewardNotifierProvider =
    AsyncNotifierProvider<RewardNotifier, DailyRewardState>(RewardNotifier.new);

/// Derived provider indicating whether the user is currently eligible to claim today's reward.
final canClaimRewardProvider = Provider<bool>((ref) {
  final rewardState = ref.watch(rewardNotifierProvider).value;
  return rewardState?.canClaimToday ?? false;
});

