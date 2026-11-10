import 'package:flutter/widgets.dart';

// Abstract interface for loading and presenting Banner, Interstitial, and Rewarded ads.
abstract interface class AdService {
  // Initializes the underlying ad network SDK.
  Future<void> init();

  // Loads a bottom banner ad.
  Future<void> loadBanner();

  // Retrieves the active banner ad widget if ready, or null.
  Widget? getBannerWidget();

  // Displays an interstitial ad if available, triggering [onDismissed] when closed.
  Future<void> showInterstitial({VoidCallback? onDismissed});

  // Displays a rewarded ad. Invokes [onRewarded] when reward condition is met,
  // or [onFailed] if ad failed to load/show. Returns true if reward was granted.
  Future<bool> showRewarded({
    required String rewardType,
    required VoidCallback onRewarded,
    VoidCallback? onFailed,
  });

  // Frees resources and disposes active ads.
  Future<void> dispose();

  // Whether the user has purchased the "Remove Ads" IAP.
  bool get isRemoveAdsPurchased;

  // Updates the "Remove Ads" status.
  void setRemoveAds(bool value);
}
