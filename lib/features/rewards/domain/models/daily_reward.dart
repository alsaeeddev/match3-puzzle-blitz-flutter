import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';

/// Defines the reward payout for a specific streak day.
@immutable
class DailyRewardTier {
  final int day; // 1 to 7
  final int coins;
  final Map<BoosterType, int> boosters;
  final int lives;

  const DailyRewardTier({
    required this.day,
    this.coins = 0,
    this.boosters = const {},
    this.lives = 0,
  }) : assert(day >= 1 && day <= 7, 'Reward day must be between 1 and 7');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRewardTier &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          coins == other.coins &&
          const MapEquality().equals(boosters, other.boosters) &&
          lives == other.lives;

  @override
  int get hashCode => Object.hash(
        day,
        coins,
        const MapEquality().hash(boosters),
        lives,
      );

  @override
  String toString() =>
      'DailyRewardTier(day: $day, coins: $coins, boosters: $boosters, lives: $lives)';
}

/// Static schedule of 7 daily reward tiers.
const List<DailyRewardTier> kRewardTiers = [
  DailyRewardTier(
    day: 1,
    coins: 50,
  ),
  DailyRewardTier(
    day: 2,
    boosters: {BoosterType.hammer: 1},
  ),
  DailyRewardTier(
    day: 3,
    coins: 100,
    boosters: {BoosterType.shuffle: 1},
  ),
  DailyRewardTier(
    day: 4,
    lives: 2,
  ),
  DailyRewardTier(
    day: 5,
    coins: 200,
    boosters: {BoosterType.plusFiveMoves: 1},
  ),
  DailyRewardTier(
    day: 6,
    boosters: {BoosterType.hammer: 3},
  ),
  DailyRewardTier(
    day: 7,
    coins: 500,
    boosters: {
      BoosterType.hammer: 2,
      BoosterType.shuffle: 2,
      BoosterType.plusFiveMoves: 2,
      BoosterType.colorSwap: 2,
    },
    lives: 5,
  ),
];

/// Player streak state tracking daily login rewards.
@immutable
class DailyRewardState {
  final DateTime? lastClaimDate;
  final int currentStreak; // 0 to 7

  const DailyRewardState({
    this.lastClaimDate,
    this.currentStreak = 0,
  }) : assert(
            currentStreak >= 0 && currentStreak <= 7, 'Streak must be 0-7');

  /// Indicates if the player is eligible to claim a reward on the current calendar day.
  bool get canClaimToday {
    if (lastClaimDate == null) return true;
    final now = DateTime.now();
    final last = lastClaimDate!;
    final isSameCalendarDay =
        now.year == last.year && now.month == last.month && now.day == last.day;
    return !isSameCalendarDay;
  }

  /// Checks if the streak was broken due to missing more than 1 calendar day.
  bool get isStreakBroken {
    if (lastClaimDate == null) return false;
    final now = DateTime.now();
    final last = lastClaimDate!;
    final dayDifference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    return dayDifference > 1;
  }

  /// Calculates the next streak day to claim (1-7), resetting to 1 if streak is broken or looped.
  int get nextClaimDay {
    if (isStreakBroken || currentStreak >= 7) {
      return 1;
    }
    return currentStreak + 1;
  }

  DailyRewardState copyWith({
    DateTime? lastClaimDate,
    bool clearLastClaimDate = false,
    int? currentStreak,
  }) {
    return DailyRewardState(
      lastClaimDate: clearLastClaimDate
          ? null
          : (lastClaimDate ?? this.lastClaimDate),
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastClaimDate': lastClaimDate?.toIso8601String(),
      'currentStreak': currentStreak,
    };
  }

  factory DailyRewardState.fromJson(Map<String, dynamic> json) {
    return DailyRewardState(
      lastClaimDate: json['lastClaimDate'] != null
          ? DateTime.tryParse(json['lastClaimDate'] as String)
          : null,
      currentStreak: json['currentStreak'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRewardState &&
          runtimeType == other.runtimeType &&
          lastClaimDate == other.lastClaimDate &&
          currentStreak == other.currentStreak;

  @override
  int get hashCode => Object.hash(lastClaimDate, currentStreak);

  @override
  String toString() =>
      'DailyRewardState(streak: $currentStreak, lastClaim: $lastClaimDate, canClaim: $canClaimToday)';
}
