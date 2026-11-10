import 'package:flutter/foundation.dart';

/// Application appearance themes.
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Supported app localization languages.
enum AppLanguage {
  english,
  urdu,
}

/// Immutable configuration capturing all user audio, display, accessibility,
/// and monetization preferences.
@immutable
class AppSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool musicEnabled;
  final AppThemeMode theme;
  final AppLanguage language;
  final bool colorBlindMode;
  final bool notificationsEnabled;
  final bool removeAdsPurchased;

  const AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.musicEnabled = true,
    this.theme = AppThemeMode.system,
    this.language = AppLanguage.english,
    this.colorBlindMode = false,
    this.notificationsEnabled = true,
    this.removeAdsPurchased = false,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? musicEnabled,
    AppThemeMode? theme,
    AppLanguage? language,
    bool? colorBlindMode,
    bool? notificationsEnabled,
    bool? removeAdsPurchased,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      removeAdsPurchased: removeAdsPurchased ?? this.removeAdsPurchased,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'musicEnabled': musicEnabled,
      'theme': theme.name,
      'language': language.name,
      'colorBlindMode': colorBlindMode,
      'notificationsEnabled': notificationsEnabled,
      'removeAdsPurchased': removeAdsPurchased,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      theme: AppThemeMode.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => AppThemeMode.system,
      ),
      language: AppLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => AppLanguage.english,
      ),
      colorBlindMode: json['colorBlindMode'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      removeAdsPurchased: json['removeAdsPurchased'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          soundEnabled == other.soundEnabled &&
          hapticsEnabled == other.hapticsEnabled &&
          musicEnabled == other.musicEnabled &&
          theme == other.theme &&
          language == other.language &&
          colorBlindMode == other.colorBlindMode &&
          notificationsEnabled == other.notificationsEnabled &&
          removeAdsPurchased == other.removeAdsPurchased;

  @override
  int get hashCode => Object.hash(
        soundEnabled,
        hapticsEnabled,
        musicEnabled,
        theme,
        language,
        colorBlindMode,
        notificationsEnabled,
        removeAdsPurchased,
      );

  @override
  String toString() =>
      'AppSettings(sound: $soundEnabled, haptics: $hapticsEnabled, music: $musicEnabled, theme: $theme, lang: $language, colorBlind: $colorBlindMode, removeAds: $removeAdsPurchased)';
}
