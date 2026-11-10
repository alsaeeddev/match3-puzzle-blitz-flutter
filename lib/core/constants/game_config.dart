// Game configuration constants and tunables for Match-3 Blitz.
class GameConfig {
  GameConfig._();

  // Grid dimensions
  static const int defaultRows = 8;
  static const int defaultCols = 8;
  static const int minRows = 6;
  static const int maxRows = 10;
  static const int minCols = 6;
  static const int maxCols = 10;

  // Colors & Types
  static const int defaultColorCount = 6;
  static const int minColors = 4;
  static const int maxColors = 6;

  // Special match thresholds
  static const int stripedMatchThreshold = 4;
  static const int colorBombMatchThreshold = 5;
  static const int wrappedMatchMinPieces = 5; // L or T or Cross shapes with >= 5 pieces

  // Animation and timing durations (in milliseconds)
  static const int swapDurationMs = 250;
  static const int invalidSwapDurationMs = 200;
  static const int matchClearDurationMs = 300;
  static const int gravityFallDurationMs = 250;
  static const int refillFallDurationMs = 250;
  static const int specialSpawnDurationMs = 300;
  static const int cascadeDelayMs = 150;
  static const int shuffleDurationMs = 600;

  // Base scoring values
  static const int basePieceScore = 60;
  static const int stripedBonusScore = 200;
  static const int wrappedBonusScore = 400;
  static const int colorBombBonusScore = 1000;
  static const int bonusScorePerMoveLeft = 100;
  static const int jellyClearScore = 100;
  static const int obstacleDamageScore = 50;

  // Combo multipliers by cascade level (index 0 = cascade 1)
  static const List<double> comboMultipliers = [
    1.0,
    1.5,
    2.0,
    3.0,
    4.0,
    5.0,
  ];

  // Lives system configuration
  static const int maxLives = 5;
  static const int lifeRegenDurationMinutes = 30;
  static const int lifeRefillCostCoins = 0;

  // Hint configuration
  static const int hintIdleDelaySeconds = 5;

  // Deadlock detection
  static const int deadlockShuffleMaxAttempts = 50;

  // Star rating thresholds (default fallback)
  static const List<int> defaultStarThresholds = [1000, 2500, 4500];

  // Starting boosters for new players
  static const int initialHammerBoosters = 99;
  static const int initialShuffleBoosters = 99;
  static const int initialPlusFiveMovesBoosters = 99;
  static const int initialColorSwapBoosters = 99;
}
