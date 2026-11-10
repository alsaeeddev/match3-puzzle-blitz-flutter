import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';

/// Async notifier managing the player's spendable coin balance.
class CoinsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final gameRepo = ref.watch(gameRepositoryProvider);
    return gameRepo.getCoins();
  }

  /// Adds [amount] coins to the player's wallet and updates state.
  Future<void> addCoins(int amount) async {
    final gameRepo = ref.read(gameRepositoryProvider);
    await gameRepo.addCoins(amount);
    final updated = await gameRepo.getCoins();
    state = AsyncData(updated);
  }

  /// Spends [amount] coins. Returns true if successful, false if insufficient balance.
  Future<bool> spendCoins(int amount) async {
    final current = state.value ?? 0;
    if (current < amount) return false;

    final gameRepo = ref.read(gameRepositoryProvider);
    try {
      await gameRepo.spendCoins(amount);
      final updated = await gameRepo.getCoins();
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Refreshes the coin balance from storage.
  Future<void> refresh() async {
    final gameRepo = ref.read(gameRepositoryProvider);
    final coins = await gameRepo.getCoins();
    state = AsyncData(coins);
  }
}

/// Global provider for the player's coin balance.
final coinsProvider =
    AsyncNotifierProvider<CoinsNotifier, int>(CoinsNotifier.new);

/// Async notifier managing player booster inventories.
class BoosterInventoryNotifier
    extends AsyncNotifier<Map<BoosterType, int>> {
  @override
  Future<Map<BoosterType, int>> build() async {
    final gameRepo = ref.watch(gameRepositoryProvider);
    return gameRepo.getBoosterInventory();
  }

  /// Adds [count] of [type] booster to inventory.
  Future<void> addBoosters(BoosterType type, int count) async {
    final gameRepo = ref.read(gameRepositoryProvider);
    final current = Map<BoosterType, int>.from(state.value ?? {});
    current[type] = (current[type] ?? 0) + count;
    await gameRepo.saveBoosterInventory(current);
    state = AsyncData(current);
  }

  /// Uses 1 booster of [type] if count > 0.
  Future<bool> useBooster(BoosterType type) async {
    final gameRepo = ref.read(gameRepositoryProvider);
    final current = Map<BoosterType, int>.from(state.value ?? {});
    final available = current[type] ?? 0;
    if (available <= 0) return false;

    current[type] = available - 1;
    await gameRepo.saveBoosterInventory(current);
    state = AsyncData(current);
    return true;
  }

  /// Refreshes inventory from repository.
  Future<void> refresh() async {
    final gameRepo = ref.read(gameRepositoryProvider);
    final inv = await gameRepo.getBoosterInventory();
    state = AsyncData(inv);
  }
}

/// Global provider for booster inventories.
final boosterInventoryProvider = AsyncNotifierProvider<
    BoosterInventoryNotifier, Map<BoosterType, int>>(
  BoosterInventoryNotifier.new,
);

