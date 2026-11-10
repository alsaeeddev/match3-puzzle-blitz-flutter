// Global application constants, persistence keys, and routing paths.
class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Match-3 Puzzle Blitz';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  static const String developerOrg = 'Gemini Game Studios';

  // Persistence (SharedPreferences) Keys
  static const String keyHighScores = 'pref_high_scores_map';
  static const String keyCurrentLevel = 'pref_current_level_id';
  static const String keyLevelStars = 'pref_level_stars_map';
  static const String keySettingsSound = 'pref_sound_enabled';
  static const String keySettingsMusic = 'pref_music_enabled';
  static const String keySettingsHaptics = 'pref_haptics_enabled';
  static const String keyLives = 'pref_current_lives';
  static const String keyLastLifeRegenTimestamp = 'pref_last_life_regen_ts';
  static const String keyCoinBalance = 'pref_user_coins';
  static const String keyBoosterInventory = 'pref_booster_inventory_map';
  static const String keyDailyRewardLastClaimed = 'pref_daily_reward_last_claimed_date';
  static const String keyDailyRewardStreak = 'pref_daily_reward_streak';

  // Navigation Route Paths
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeGame = '/game';
  static const String routeLevels = '/levels';
  static const String routeSettings = '/settings';
  static const String routeShop = '/shop';
  static const String routeRewards = '/rewards';

  // Economy & Lives Constants
  static const int startingCoins = 99999;
  static const int rewardCoinsPerLevelWin = 50;
  static const int maxLivesCount = 5;
  static const int minutesPerLifeRegen = 30;
  static const int fullRefillCoinsCost = 0;
}
