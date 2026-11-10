import 'package:flutter/widgets.dart';
import 'ad_service.dart';

// No-op fallback implementation of [AdService] for Web, Desktop, and Unit Tests.
class NoopAdService implements AdService {
  bool _isRemoveAdsPurchased = false;

  @override
  bool get isRemoveAdsPurchased => _isRemoveAdsPurchased;

  @override
  void setRemoveAds(bool value) {
    _isRemoveAdsPurchased = value;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> loadBanner() async {}

  @override
  Widget? getBannerWidget() => null;

  @override
  Future<void> showInterstitial({VoidCallback? onDismissed}) async {
    onDismissed?.call();
  }

  @override
  Future<bool> showRewarded({
    required String rewardType,
    required VoidCallback onRewarded,
    VoidCallback? onFailed,
  }) async {
    // In testing or noop environments, instantly grant the requested reward
    onRewarded();
    return true;
  }

  @override
  Future<void> dispose() async {}
}
