import 'package:match3_game/features/game/domain/models/level_config.dart';
import '../models/level_progress.dart';

/// Abstract interface for querying level configurations and persisting level progress.
abstract interface class LevelRepository {
  /// Returns all LevelConfig definitions for the game.
  List<LevelConfig> getAllLevels();

  /// Returns a single level configuration by its ID. Throws if not found.
  LevelConfig getLevelById(int id);

  /// Returns player progress for all levels.
  Future<List<LevelProgress>> getAllProgress();

  /// Returns progress for a specific level by its ID.
  Future<LevelProgress> getProgress(int levelId);

  /// Saves player progress after completing or attempting a level.
  Future<void> saveProgress(LevelProgress progress);

  /// Unlocks the level with the given [levelId].
  Future<void> unlockLevel(int levelId);
}
