import '../models/game_event.dart';
import '../models/game_state.dart';

/// Abstract interface for persisting board states, booster supplies, and player coins.
abstract interface class GameRepository {
  /// Persists an in-progress game session for [levelId].
  Future<void> saveGameState(int levelId, GameState state);

  /// Restores a previously saved in-progress game session for [levelId], or null.
  Future<GameState?> loadGameState(int levelId);

  /// Clears saved in-progress game state for [levelId].
  Future<void> clearGameState(int levelId);

  /// Returns the current booster inventory.
  Future<Map<BoosterType, int>> getBoosterInventory();

  /// Persists the player's booster inventory.
  Future<void> saveBoosterInventory(Map<BoosterType, int> inventory);

  /// Uses a booster of [type], decrementing its count. Throws [StateError] if count is 0.
  Future<void> useBooster(BoosterType type);

  /// Returns the current coin balance.
  Future<int> getCoins();

  /// Adds [amount] coins to the player's balance.
  Future<void> addCoins(int amount);

  /// Spends [amount] coins. Throws [StateError] if balance is insufficient.
  Future<void> spendCoins(int amount);
}
