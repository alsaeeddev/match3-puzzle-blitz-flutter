import 'package:flutter/foundation.dart';

/// Immutable model tracking a player's progress and achievements on a single level.
@immutable
class LevelProgress {
  final int levelId;
  final bool isUnlocked;
  final int stars; // 0 to 3
  final int bestScore;
  final DateTime? completedAt;
  final int attempts;

  const LevelProgress({
    required this.levelId,
    this.isUnlocked = false,
    this.stars = 0,
    this.bestScore = 0,
    this.completedAt,
    this.attempts = 0,
  }) : assert(stars >= 0 && stars <= 3, 'Stars must be between 0 and 3');

  /// Indicates if this level has been completed with at least 1 star.
  bool get isCompleted => stars > 0;

  LevelProgress copyWith({
    int? levelId,
    bool? isUnlocked,
    int? stars,
    int? bestScore,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? attempts,
  }) {
    return LevelProgress(
      levelId: levelId ?? this.levelId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'isUnlocked': isUnlocked,
      'stars': stars,
      'bestScore': bestScore,
      'completedAt': completedAt?.toIso8601String(),
      'attempts': attempts,
    };
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      attempts: json['attempts'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelProgress &&
          runtimeType == other.runtimeType &&
          levelId == other.levelId &&
          isUnlocked == other.isUnlocked &&
          stars == other.stars &&
          bestScore == other.bestScore &&
          completedAt == other.completedAt &&
          attempts == other.attempts;

  @override
  int get hashCode => Object.hash(
        levelId,
        isUnlocked,
        stars,
        bestScore,
        completedAt,
        attempts,
      );

  @override
  String toString() =>
      'LevelProgress(level: $levelId, unlocked: $isUnlocked, stars: $stars, bestScore: $bestScore, attempts: $attempts)';
}
