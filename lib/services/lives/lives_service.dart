/// Abstract interface managing player lives, countdown regeneration, and refills.
abstract interface class LivesService {
  /// Initializes the service and syncs remaining lives.
  Future<void> init();

  /// Retrieves the current lives count.
  Future<int> getLives();

  /// Returns the estimated timestamp when the next life will be restored,
  /// or null if lives are already fully replenished.
  Future<DateTime?> getNextRegenTime();

  /// Consumes a single life to start a level attempt. Throws if 0 lives remaining.
  Future<void> consumeLife();

  /// Grants [count] additional lives up to the configured maximum.
  Future<void> addLives(int count);

  /// Instantly replenishes lives to the maximum capacity.
  Future<void> refillLives();

  /// Checks elapsed timestamp difference and regenerates lives as needed.
  /// Designed to be called upon app startup or foreground resume.
  Future<int> syncLives();

  /// Broadcast stream notifying listeners when lives count changes.
  Stream<int> get livesStream;
}
