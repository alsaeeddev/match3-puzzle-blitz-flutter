// Abstract interface for game audio, sound effects, haptic feedback, and music.
abstract interface class AudioService {
  /// Initializes the audio subsystem.
  Future<void> init();

  // ── Sound Effects ─────────────────────────────────────────────────────────

  // Plays sound/feedback for gem swapping.
  Future<void> playSwap();

  // Plays sound/feedback for regular match-3 detections.
  Future<void> playMatch();

  // Plays sound/feedback when matched pieces are cleared from the board.
  Future<void> playClear();

  // Plays sound/feedback when a special piece is created.
  Future<void> playSpecialSpawn();

  // Plays escalating sound/feedback for cascade combos.
  Future<void> playCombo(int level);

  // Plays celebratory sound/feedback upon beating a level.
  Future<void> playLevelWon();

  // Plays defeat sound/feedback when moves run out.
  Future<void> playLevelLost();

  // Plays sound/feedback when a booster is triggered.
  Future<void> playBooster();

  // Plays UI sound/feedback for button taps.
  Future<void> playButtonTap();

  // Plays sound/feedback when claiming a daily reward.
  Future<void> playDailyReward();

  // ── Sound Toggle ──────────────────────────────────────────────────────────

  // Enables or disables SFX (SystemSound / audioplayers SFX) independently.
  void setSoundEnabled(bool enabled);

  // Whether SFX are currently enabled.
  bool get soundEnabled;

  // ── Haptic Toggle ─────────────────────────────────────────────────────────

  // Enables or disables vibration / haptic feedback independently of sound.
  void setHapticsEnabled(bool enabled);

  // Whether haptic feedback is currently enabled.
  bool get hapticsEnabled;

  // ── Music ─────────────────────────────────────────────────────────────────

  // Enables or disables background music. When [enabled] is true the music
  // starts (or resumes); when false, it stops immediately.
  Future<void> setMusicEnabled(bool enabled);

  // Whether background music is currently enabled.
  bool get musicEnabled;

  // Starts background music from the beginning (or resumes if paused).
  Future<void> startMusic();

  // Stops background music completely.
  Future<void> stopMusic();

  // Pauses background music (position is preserved for [resumeMusic]).
  Future<void> pauseMusic();

  // Resumes background music from the last paused position.
  Future<void> resumeMusic();

  // ── Backward-Compat Aliases ───────────────────────────────────────────────

  // Legacy alias: sets mute state for SFX only. Prefer [setSoundEnabled].
  void setMuted(bool muted);

  // Legacy alias: current SFX mute state. Prefer [soundEnabled].
  bool get isMuted;
}
