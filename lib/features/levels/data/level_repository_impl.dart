import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/services/storage/storage_service.dart';
import '../domain/models/level_progress.dart';
import '../domain/repositories/level_repository.dart';
import 'level_definitions.dart';

/// Implementation of [LevelRepository] using static [kLevelDefinitions]
/// and persisting player achievements via [StorageService].
class LevelRepositoryImpl implements LevelRepository {
  static const String _progressStorageKey = 'pref_levels_progress_list';

  final StorageService _storage;

  LevelRepositoryImpl(this._storage);

  @override
  List<LevelConfig> getAllLevels() {
    return kLevelDefinitions;
  }

  @override
  LevelConfig getLevelById(int id) {
    try {
      return kLevelDefinitions.firstWhere((level) => level.id == id);
    } catch (_) {
      throw ArgumentError('Level with id $id not found in level definitions');
    }
  }

  @override
  Future<List<LevelProgress>> getAllProgress() async {
    final rawList = await _storage.getJsonList(_progressStorageKey);
    final progressMap = <int, LevelProgress>{};

    if (rawList != null) {
      for (final json in rawList) {
        final progress = LevelProgress.fromJson(json);
        progressMap[progress.levelId] = progress;
      }
    }

    // Ensure all defined levels have progress represented, with level 1 unlocked by default
    final result = <LevelProgress>[];
    for (final level in kLevelDefinitions) {
      if (progressMap.containsKey(level.id)) {
        result.add(progressMap[level.id]!);
      } else {
        result.add(
          LevelProgress(
            levelId: level.id,
            isUnlocked: level.id == 1,
          ),
        );
      }
    }

    result.sort((a, b) => a.levelId.compareTo(b.levelId));
    return result;
  }

  @override
  Future<LevelProgress> getProgress(int levelId) async {
    final allProgress = await getAllProgress();
    return allProgress.firstWhere(
      (p) => p.levelId == levelId,
      orElse: () => LevelProgress(
        levelId: levelId,
        isUnlocked: levelId == 1,
      ),
    );
  }

  @override
  Future<void> saveProgress(LevelProgress progress) async {
    final allProgress = await getAllProgress();
    final updatedList = <LevelProgress>[];
    var found = false;

    for (final item in allProgress) {
      if (item.levelId == progress.levelId) {
        // Keep highest stars and best score
        final bestStars = progress.stars > item.stars ? progress.stars : item.stars;
        final bestScore = progress.bestScore > item.bestScore ? progress.bestScore : item.bestScore;
        final isUnlocked = progress.isUnlocked || item.isUnlocked;
        final completedAt = progress.completedAt ?? item.completedAt;
        final totalAttempts = item.attempts + (progress.attempts > 0 ? progress.attempts : 1);

        updatedList.add(
          item.copyWith(
            stars: bestStars,
            bestScore: bestScore,
            isUnlocked: isUnlocked,
            completedAt: completedAt,
            attempts: totalAttempts,
          ),
        );
        found = true;
      } else {
        updatedList.add(item);
      }
    }

    if (!found) {
      updatedList.add(progress);
    }

    updatedList.sort((a, b) => a.levelId.compareTo(b.levelId));
    await _storage.setJsonList(
      _progressStorageKey,
      updatedList.map((p) => p.toJson()).toList(),
    );
  }

  @override
  Future<void> unlockLevel(int levelId) async {
    final progress = await getProgress(levelId);
    if (!progress.isUnlocked) {
      await saveProgress(progress.copyWith(isUnlocked: true));
    }
  }
}
