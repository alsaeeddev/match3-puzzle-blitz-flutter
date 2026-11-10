// Abstract interface for game telemetries, events, and player funnels.
abstract interface class AnalyticsService {
  // Initializes the analytics service.
  Future<void> init();

  // Logs when a player starts or restarts a level.
  Future<void> logLevelStart(int levelId);

  // Logs when a player successfully completes a level.
  Future<void> logLevelComplete(
    int levelId,
    int stars,
    int score,
    int moves,
  );

  // Logs when a player fails a level attempt.
  Future<void> logLevelFail(int levelId, int score, int movesUsed);

  // Logs booster activation during gameplay.
  Future<void> logBoosterUsed(String boosterName, int levelId);

  // Logs when an ad impression completes.
  Future<void> logAdWatched(String adType);

  // Logs in-app purchase transactions.
  Future<void> logIapPurchase(String productId, double price);

  // Logs daily reward collection and streak day.
  Future<void> logDailyRewardClaimed(int day);

  // Logs screen navigation events.
  Future<void> logScreenView(String screenName);

  // Logs custom key-value analytics events.
  Future<void> logEvent(String name, Map<String, Object> params);
}
