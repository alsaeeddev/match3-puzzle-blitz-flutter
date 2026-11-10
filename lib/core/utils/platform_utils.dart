import 'package:flutter/foundation.dart';

// Platform detection utilities with strict web safety guards to prevent
// runtime `dart:io` UnsupportedError exceptions on Web targets.
class PlatformUtils {
  PlatformUtils._();

  // Whether the app is running in a web browser.
  static bool get isWeb => kIsWeb;

  // Whether the app is running on Android.
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Whether the app is running on iOS.
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // Whether the app is running on a mobile platform (iOS or Android).
  static bool get isMobile => isAndroid || isIOS;

  // Whether the app is running on a desktop platform (Windows, macOS, Linux).
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  // Whether the app is running on an Apple platform (iOS or macOS).
  static bool get isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  // Human-readable name of the current running platform.
  static String get platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
