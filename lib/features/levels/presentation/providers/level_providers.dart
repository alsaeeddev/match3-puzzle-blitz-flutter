import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/levels/domain/models/level_progress.dart';

/// Async notifier managing the list of all player level progression records.
class LevelProgressNotifier extends AsyncNotifier<List<LevelProgress>> {
  @override
  Future<List<LevelProgress>> build() async {
    final repository = ref.watch(levelRepositoryProvider);
    return repository.getAllProgress();
  }

  /// Completes a level with [stars] and [score], updating records and unlocking the next level.
  Future<void> completeLevel(int levelId, int stars, int score) async {
    final repository = ref.read(levelRepositoryProvider);
    final currentList = state.value ?? await repository.getAllProgress();

    final existing = currentList.firstWhereOrNull((p) => p.levelId == levelId);
    final prevBestScore = existing?.bestScore ?? 0;
    final prevStars = existing?.stars ?? 0;
    final prevAttempts = existing?.attempts ?? 0;

    final updated = LevelProgress(
      levelId: levelId,
      isUnlocked: true,
      stars: max(stars, prevStars),
      bestScore: max(score, prevBestScore),
      completedAt: DateTime.now(),
      attempts: prevAttempts + 1,
    );

    await repository.saveProgress(updated);

    // If beat with at least 1 star, unlock the succeeding level
    if (stars > 0) {
      await repository.unlockLevel(levelId + 1);
    }

    // Refresh memory state from repository
    final refreshed = await repository.getAllProgress();
    state = AsyncData(refreshed);
  }

  /// Forces a reload of player progress from storage.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final repository = ref.read(levelRepositoryProvider);
    final reloaded = await repository.getAllProgress();
    state = AsyncData(reloaded);
  }
}

/// Global provider for all level progress entries.
final levelProgressProvider =
    AsyncNotifierProvider<LevelProgressNotifier, List<LevelProgress>>(
  LevelProgressNotifier.new,
);

/// Provider exposing all 50 predefined puzzle level configurations.
final levelConfigsProvider = Provider<List<LevelConfig>>((ref) {
  final repo = ref.watch(levelRepositoryProvider);
  return repo.getAllLevels();
});

/// Family provider resolving a specific [LevelConfig] by its ID.
final levelByIdProvider = Provider.family<LevelConfig, int>((ref, levelId) {
  final repo = ref.watch(levelRepositoryProvider);
  return repo.getLevelById(levelId);
});

/// Family provider resolving player [LevelProgress] for a specific level ID.
final levelProgressByIdProvider =
    Provider.family<LevelProgress?, int>((ref, levelId) {
  final list = ref.watch(levelProgressProvider).value;
  return list?.firstWhereOrNull((p) => p.levelId == levelId);
});

