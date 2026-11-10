import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Development/debug implementation of [AnalyticsService] that formats
/// and outputs telemetry events to debugPrint.
class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {
    debugPrint('[Analytics] Initialized debug telemetry service');
  }

  @override
  Future<void> logLevelStart(int levelId) async {
    debugPrint('[Analytics] Level Start -> levelId: $levelId');
  }

  @override
  Future<void> logLevelComplete(
    int levelId,
    int stars,
    int score,
    int moves,
  ) async {
    debugPrint(
      '[Analytics] Level Complete -> levelId: $levelId, stars: $stars, score: $score, movesLeft: $moves',
    );
  }

  @override
  Future<void> logLevelFail(int levelId, int score, int movesUsed) async {
    debugPrint(
      '[Analytics] Level Failed -> levelId: $levelId, score: $score, movesUsed: $movesUsed',
    );
  }

  @override
  Future<void> logBoosterUsed(String boosterName, int levelId) async {
    debugPrint(
      '[Analytics] Booster Used -> booster: $boosterName, levelId: $levelId',
    );
  }

  @override
  Future<void> logAdWatched(String adType) async {
    debugPrint('[Analytics] Ad Watched -> type: $adType');
  }

  @override
  Future<void> logIapPurchase(String productId, double price) async {
    debugPrint(
      '[Analytics] IAP Purchase -> productId: $productId, price: \$$price',
    );
  }

  @override
  Future<void> logDailyRewardClaimed(int day) async {
    debugPrint('[Analytics] Daily Reward Claimed -> day: $day');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    debugPrint('[Analytics] Screen View -> screen: $screenName');
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    debugPrint('[Analytics] Custom Event -> $name, params: $params');
  }
}
