import 'dart:async';
import 'package:match3_game/core/constants/app_constants.dart';
import 'package:match3_game/core/constants/game_config.dart';
import 'package:match3_game/services/storage/storage_service.dart';
import 'lives_service.dart';

// Timestamp-based persistent implementation of [LivesService].
// Recovers and regenerates lives correctly across app restarts and backgrounding.
class LivesServiceImpl implements LivesService {
  final StorageService _storage;
  final StreamController<int> _livesController =
      StreamController<int>.broadcast();

  LivesServiceImpl(this._storage);

  @override
  Stream<int> get livesStream => _livesController.stream;

  @override
  Future<void> init() async {
    await syncLives();
  }

  @override
  Future<int> getLives() async {
    return syncLives();
  }

  @override
  Future<DateTime?> getNextRegenTime() async {
    final current = await syncLives();
    if (current >= GameConfig.maxLives) {
      return null;
    }

    final lastMillis =
        await _storage.getInt(AppConstants.keyLastLifeRegenTimestamp);
    if (lastMillis == null) {
      return null;
    }

    final lastRegen = DateTime.fromMillisecondsSinceEpoch(lastMillis);
    return lastRegen
        .add(const Duration(minutes: GameConfig.lifeRegenDurationMinutes));
  }

  @override
  Future<int> syncLives() async {
    final storedLives = await _storage.getInt(AppConstants.keyLives);
    var currentLives = storedLives ?? GameConfig.maxLives;

    if (currentLives >= GameConfig.maxLives) {
      if (storedLives == null || storedLives != GameConfig.maxLives) {
        await _storage.setInt(AppConstants.keyLives, GameConfig.maxLives);
      }
      await _storage.remove(AppConstants.keyLastLifeRegenTimestamp);
      _livesController.add(GameConfig.maxLives);
      return GameConfig.maxLives;
    }

    final lastMillis =
        await _storage.getInt(AppConstants.keyLastLifeRegenTimestamp);
    if (lastMillis == null) {
      await _storage.setInt(
        AppConstants.keyLastLifeRegenTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
      _livesController.add(currentLives);
      return currentLives;
    }

    final lastRegenTime = DateTime.fromMillisecondsSinceEpoch(lastMillis);
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastRegenTime).inMinutes;
    final regenCount = elapsedMinutes ~/ GameConfig.lifeRegenDurationMinutes;

    if (regenCount > 0) {
      currentLives =
          (currentLives + regenCount).clamp(0, GameConfig.maxLives);
      await _storage.setInt(AppConstants.keyLives, currentLives);

      if (currentLives >= GameConfig.maxLives) {
        await _storage.remove(AppConstants.keyLastLifeRegenTimestamp);
      } else {
        final remainderBaseTime = lastRegenTime.add(
          Duration(minutes: regenCount * GameConfig.lifeRegenDurationMinutes),
        );
        await _storage.setInt(
          AppConstants.keyLastLifeRegenTimestamp,
          remainderBaseTime.millisecondsSinceEpoch,
        );
      }
    }

    _livesController.add(currentLives);
    return currentLives;
  }

  @override
  Future<void> consumeLife() async {
    final current = await syncLives();
    if (current <= 0) {
      throw StateError('Cannot consume life: 0 lives remaining');
    }

    final updated = current - 1;
    await _storage.setInt(AppConstants.keyLives, updated);

    // If we just dropped from max, record the start of regen timer
    if (current >= GameConfig.maxLives) {
      await _storage.setInt(
        AppConstants.keyLastLifeRegenTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    _livesController.add(updated);
  }

  @override
  Future<void> addLives(int count) async {
    final current = await syncLives();
    final updated = (current + count).clamp(0, GameConfig.maxLives);
    await _storage.setInt(AppConstants.keyLives, updated);

    if (updated >= GameConfig.maxLives) {
      await _storage.remove(AppConstants.keyLastLifeRegenTimestamp);
    }

    _livesController.add(updated);
  }

  @override
  Future<void> refillLives() async {
    await _storage.setInt(AppConstants.keyLives, GameConfig.maxLives);
    await _storage.remove(AppConstants.keyLastLifeRegenTimestamp);
    _livesController.add(GameConfig.maxLives);
  }

  void dispose() {
    _livesController.close();
  }
}
