import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:match3_game/core/constants/ad_config.dart';
import 'ad_service.dart';

// NOTE: Add UMP consent flow here before initializing ads in production
/// Production implementation of [AdService] backed by Google Mobile Ads (AdMob).
/// Safely degrades to no-op execution on Web and unsupported platforms.
class AdMobAdService implements AdService {
  bool _isRemoveAdsPurchased = false;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  @override
  bool get isRemoveAdsPurchased => _isRemoveAdsPurchased;

  @override
  void setRemoveAds(bool value) {
    _isRemoveAdsPurchased = value;
    if (value) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerLoaded = false;
    }
  }

  @override
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      if (!_isRemoveAdsPurchased) {
        await loadBanner();
        _preloadInterstitial();
      }
      _preloadRewarded();
    } catch (e) {
      debugPrint('[AdMobAdService] Failed to initialize AdMob: $e');
    }
  }

  @override
  Future<void> loadBanner() async {
    if (kIsWeb || _isRemoveAdsPurchased) return;

    await _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;

    final completer = Completer<void>();

    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          _isBannerLoaded = true;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMobAdService] Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    await ad.load();
    return completer.future;
  }

  @override
  Widget? getBannerWidget() {
    if (kIsWeb || _isRemoveAdsPurchased || !_isBannerLoaded || _bannerAd == null) {
      return null;
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  void _preloadInterstitial() {
    if (kIsWeb || _isRemoveAdsPurchased || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobAdService] Interstitial failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  @override
  Future<void> showInterstitial({VoidCallback? onDismissed}) async {
    if (kIsWeb || _isRemoveAdsPurchased) {
      onDismissed?.call();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      onDismissed?.call();
      _preloadInterstitial();
      return;
    }

    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDismissed?.call();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMobAdService] Interstitial failed to show: $error');
        ad.dispose();
        onDismissed?.call();
        _preloadInterstitial();
      },
    );

    await ad.show();
  }

  void _preloadRewarded() {
    if (kIsWeb || _isRewardedLoading || _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobAdService] Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  @override
  Future<bool> showRewarded({
    required String rewardType,
    required VoidCallback onRewarded,
    VoidCallback? onFailed,
  }) async {
    if (kIsWeb) {
      onRewarded();
      return true;
    }

    final completer = Completer<bool>();
    var rewardGranted = false;

    void present(RewardedAd ad) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _preloadRewarded();
          if (!completer.isCompleted) {
            completer.complete(rewardGranted);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdMobAdService] Rewarded ad failed to show: $error');
          ad.dispose();
          _preloadRewarded();
          onFailed?.call();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      ad.show(
        onUserEarnedReward: (adWithoutView, reward) {
          rewardGranted = true;
          onRewarded();
        },
      );
    }

    if (_rewardedAd != null) {
      final ad = _rewardedAd!;
      _rewardedAd = null;
      present(ad);
      return completer.future;
    }

    // Attempt on-demand load if preloaded was unavailable
    await RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          present(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobAdService] On-demand rewarded load failed: $error');
          onFailed?.call();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }

  @override
  Future<void> dispose() async {
    await _bannerAd?.dispose();
    _bannerAd = null;
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    await _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
