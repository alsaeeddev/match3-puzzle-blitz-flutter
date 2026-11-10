import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'audio_service.dart';

// Full audio + haptic implementation.
// Sound (SFX), haptic vibration, and background music are **completely
// independent** of each other:
// - [_soundEnabled]   → controls SFX (audioplayers WAV assets)
// - [_hapticsEnabled] → controls HapticFeedback calls
// - [_musicEnabled]   → controls looping background music player
// Every `play*` method applies its own guard per channel so e.g.
// Sound-OFF + Haptics-ON still vibrates, and vice-versa.
// SFX uses a rotating pool of [AudioPlayer] instances to allow overlapping
// short sounds. Music uses a dedicated looping player.
// [init] MUST be awaited before any [play*] or [startMusic] call.
// The [SplashScreen] does this after [settingsProvider] resolves.
class HapticAudioService implements AudioService {
  // ── State ─────────────────────────────────────────────────────────────────
  bool _soundEnabled   = true;
  bool _hapticsEnabled = true;
  bool _musicEnabled   = true;
  bool _musicPaused    = false;
  bool _initialized    = false;

  // ── SFX pool — 4 slots for concurrent short effects ───────────────────────
  static const int _poolSize = 4;
  final List<AudioPlayer> _sfxPool = [];
  int _sfxIndex = 0;

  // ── Dedicated music player ─────────────────────────────────────────────────
  final AudioPlayer _musicPlayer = AudioPlayer();

  // ── Asset paths (WAV — proper PCM files in assets/audio/) ─────────────────
  static const _swap    = 'audio/swap.wav';
  static const _match   = 'audio/match.wav';
  static const _clear   = 'audio/clear.wav';
  static const _special = 'audio/special.wav';
  static const _combo   = 'audio/combo.wav';
  static const _win     = 'audio/win.wav';
  static const _lose    = 'audio/lose.wav';
  static const _booster = 'audio/booster.wav';
  static const _tap     = 'audio/tap.wav';
  static const _reward  = 'audio/reward.wav';
  static const _bgMusic = 'audio/bg_music.wav';

  // ── Init ──────────────────────────────────────────────────────────────────

  // Initializes the SFX pool and music player.
  // Must be awaited once before first use (called from SplashScreen).
  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Build the SFX pool — each slot uses ReleaseMode.stop so the native
    // player is kept alive and reusable across the app session.
    for (var i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(0.8);
      _sfxPool.add(p);
    }

    // Music player: loop forever at lower volume.
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.4);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Picks the next SFX slot (round-robin) and plays [asset].
  // Falls back to [SystemSound.click] if audioplayers throws synchronously.
  // (Async decode errors are swallowed by audioplayers itself; they don't
  // propagate to callers — which is why the try/catch is here only for
  // setup/platform errors.)
  Future<void> _playSfx(String asset) async {
    if (!_soundEnabled) return;
    if (_sfxPool.isEmpty) {
      // Pool not ready yet (init() not called) — silent fallback.
      try { await SystemSound.play(SystemSoundType.click); } catch (_) {}
      return;
    }
    final player = _sfxPool[_sfxIndex % _poolSize];
    _sfxIndex++;
    try {
      // stop() first so the same slot can be reused if still playing.
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      try { await SystemSound.play(SystemSoundType.click); } catch (_) {}
    }
  }

  // Runs [hapticFn] only when [_hapticsEnabled].
  Future<void> _haptic(Future<void> Function() hapticFn) async {
    if (!_hapticsEnabled) return;
    try { await hapticFn(); } catch (_) {}
  }

  // ── SFX implementations ───────────────────────────────────────────────────

  @override
  Future<void> playSwap() async {
    await _playSfx(_swap);
    await _haptic(HapticFeedback.lightImpact);
  }

  @override
  Future<void> playMatch() async {
    await _playSfx(_match);
    await _haptic(HapticFeedback.mediumImpact);
  }

  @override
  Future<void> playClear() async {
    await _playSfx(_clear);
    await _haptic(HapticFeedback.mediumImpact);
  }

  @override
  Future<void> playSpecialSpawn() async {
    await _playSfx(_special);
    await _haptic(HapticFeedback.heavyImpact);
  }

  @override
  Future<void> playCombo(int level) async {
    await _playSfx(_combo);
    await _haptic(HapticFeedback.heavyImpact);
    if (level >= 3) await _haptic(HapticFeedback.vibrate);
  }

  @override
  Future<void> playLevelWon() async {
    await _playSfx(_win);
    await _haptic(HapticFeedback.heavyImpact);
    await _haptic(HapticFeedback.vibrate);
  }

  @override
  Future<void> playLevelLost() async {
    await _playSfx(_lose);
    await _haptic(HapticFeedback.mediumImpact);
  }

  @override
  Future<void> playBooster() async {
    await _playSfx(_booster);
    await _haptic(HapticFeedback.heavyImpact);
  }

  @override
  Future<void> playButtonTap() async {
    await _playSfx(_tap);
    await _haptic(HapticFeedback.selectionClick);
  }

  @override
  Future<void> playDailyReward() async {
    await _playSfx(_reward);
    await _haptic(HapticFeedback.heavyImpact);
    await _haptic(HapticFeedback.vibrate);
  }

  // ── Sound toggle ──────────────────────────────────────────────────────────

  @override
  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;

  @override
  bool get soundEnabled => _soundEnabled;

  // ── Haptic toggle ─────────────────────────────────────────────────────────

  @override
  void setHapticsEnabled(bool enabled) => _hapticsEnabled = enabled;

  @override
  bool get hapticsEnabled => _hapticsEnabled;

  // ── Music controls ────────────────────────────────────────────────────────

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (enabled) {
      _musicPaused = false;
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  @override
  bool get musicEnabled => _musicEnabled;

  @override
  Future<void> startMusic() async {
    if (!_musicEnabled) return;
    _musicPaused = false;
    try {
      // Ensure loop + volume are set even if init() somehow wasn't awaited.
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setVolume(0.4);
      await _musicPlayer.play(AssetSource(_bgMusic));
    } catch (_) {}
  }

  @override
  Future<void> stopMusic() async {
    _musicPaused = false;
    try { await _musicPlayer.stop(); } catch (_) {}
  }

  @override
  Future<void> pauseMusic() async {
    if (!_musicEnabled) return;
    _musicPaused = true;
    try { await _musicPlayer.pause(); } catch (_) {}
  }

  @override
  Future<void> resumeMusic() async {
    if (!_musicEnabled || !_musicPaused) return;
    _musicPaused = false;
    try { await _musicPlayer.resume(); } catch (_) {}
  }

  // ── Legacy aliases ────────────────────────────────────────────────────────

  @override
  void setMuted(bool muted) => setSoundEnabled(!muted);

  @override
  bool get isMuted => !_soundEnabled;
}
