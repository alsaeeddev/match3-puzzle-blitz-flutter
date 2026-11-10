import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/features/settings/domain/models/settings_model.dart';

/// Async notifier managing user preferences and persisting them to local storage.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';

  @override
  Future<AppSettings> build() async {
    final storage = ref.watch(storageServiceProvider);
    final json = await storage.getJson(_settingsKey);

    final AppSettings settings;
    if (json == null) {
      settings = const AppSettings();
    } else {
      try {
        settings = AppSettings.fromJson(json);
      } catch (_) {
        return const AppSettings();
      }
    }

    // Apply all three saved flags to the audio service on every build/restart.
    final audio = ref.read(audioServiceProvider);
    audio.setSoundEnabled(settings.soundEnabled);
    audio.setHapticsEnabled(settings.hapticsEnabled);
    // Music is started in splash after this future completes; here we just
    // propagate the flag so the service knows the intent.
    if (!settings.musicEnabled) {
      await audio.stopMusic();
    }

    return settings;
  }

  Future<void> _saveSettings(AppSettings updated) async {
    state = AsyncData(updated);
    final storage = ref.read(storageServiceProvider);
    await storage.setJson(_settingsKey, updated.toJson());
  }

  /// Toggles sound effects independently of vibration and music.
  Future<void> updateSound(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(soundEnabled: enabled);
    ref.read(audioServiceProvider).setSoundEnabled(enabled);
    await _saveSettings(updated);
  }

  /// Toggles haptic / vibration feedback independently of sound and music.
  Future<void> updateHaptics(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(hapticsEnabled: enabled);
    ref.read(audioServiceProvider).setHapticsEnabled(enabled);
    await _saveSettings(updated);
  }

  /// Toggles background music independently of sound and haptics.
  /// Turning ON immediately starts music; turning OFF stops it.
  Future<void> updateMusic(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(musicEnabled: enabled);
    await ref.read(audioServiceProvider).setMusicEnabled(enabled);
    await _saveSettings(updated);
  }

  /// Updates the application theme (system, light, or dark).
  Future<void> updateTheme(AppThemeMode theme) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(theme: theme);
    await _saveSettings(updated);
  }

  /// Updates the application language.
  Future<void> updateLanguage(AppLanguage language) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(language: language);
    await _saveSettings(updated);
  }

  /// Toggles high-contrast shape/pattern rendering for color-blind accessibility.
  Future<void> updateColorBlindMode(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(colorBlindMode: enabled);
    await _saveSettings(updated);
  }

  /// Toggles push notifications.
  Future<void> updateNotifications(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(notificationsEnabled: enabled);
    await _saveSettings(updated);
  }

  /// Updates status of the "Remove Ads" IAP purchase.
  Future<void> updateRemoveAds(bool purchased) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(removeAdsPurchased: purchased);
    ref.read(adServiceProvider).setRemoveAds(purchased);
    await _saveSettings(updated);
  }
}

/// Global provider for [SettingsNotifier] exposing [AppSettings].
final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
