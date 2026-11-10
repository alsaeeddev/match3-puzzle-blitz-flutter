import 'package:flutter/foundation.dart';

// AdMob configuration containing official Google sample/test Ad Unit IDs
// and helper methods for switching between test and production units.
// CAUTION: Replace these test IDs with your production AdMob Unit IDs
// before publishing to the Google Play Store or Apple App Store.
class AdConfig {
  AdConfig._();

  // ---------------------------------------------------------------------------
  // Google Official Test Ad Unit IDs
  // https://developers.google.com/admob/android/test-ads
  // https://developers.google.com/admob/ios/test-ads
  // ---------------------------------------------------------------------------

  // Android Test Ad Units
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  // iOS Test Ad Units
  static const String iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  // ---------------------------------------------------------------------------
  // Production Ad Units (REPLACE WITH YOUR ACTUAL REGISTERED ADMOB IDS)
  // ---------------------------------------------------------------------------
  static const String _androidBannerProdId =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _androidInterstitialProdId =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _androidRewardedProdId =
      'ca-app-pub-0000000000000000/0000000000';

  static const String _iosBannerProdId =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _iosInterstitialProdId =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _iosRewardedProdId =
      'ca-app-pub-0000000000000000/0000000000';

  // Toggle this to false in release production builds.
  static const bool isTesting = !kReleaseMode;

  // Returns the appropriate Banner Ad Unit ID based on platform and build mode.
  static String get bannerAdUnitId {
    if (isTesting) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? iosBannerTestId
          : androidBannerTestId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosBannerProdId
        : _androidBannerProdId;
  }

  // Returns the appropriate Interstitial Ad Unit ID based on platform and build mode.
  static String get interstitialAdUnitId {
    if (isTesting) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? iosInterstitialTestId
          : androidInterstitialTestId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosInterstitialProdId
        : _androidInterstitialProdId;
  }

  // Returns the appropriate Rewarded Ad Unit ID based on platform and build mode.
  static String get rewardedAdUnitId {
    if (isTesting) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? iosRewardedTestId
          : androidRewardedTestId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosRewardedProdId
        : _androidRewardedProdId;
  }
}
