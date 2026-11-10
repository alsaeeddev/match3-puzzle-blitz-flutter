import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/features/game/data/game_repository_impl.dart';
import 'package:match3_game/features/game/domain/engine/board_generator.dart';
import 'package:match3_game/features/game/domain/engine/cascade_engine.dart';
import 'package:match3_game/features/game/domain/engine/deadlock_detector.dart';
import 'package:match3_game/features/game/domain/engine/gravity_engine.dart';
import 'package:match3_game/features/game/domain/engine/hint_engine.dart';
import 'package:match3_game/features/game/domain/engine/match_detector.dart';
import 'package:match3_game/features/game/domain/engine/special_combos.dart';
import 'package:match3_game/features/game/domain/repositories/game_repository.dart';
import 'package:match3_game/features/game/domain/scoring/score_calculator.dart';
import 'package:match3_game/features/levels/data/level_repository_impl.dart';
import 'package:match3_game/features/levels/domain/repositories/level_repository.dart';
import 'package:match3_game/features/settings/presentation/providers/settings_providers.dart';
import 'package:match3_game/services/ads/ad_service.dart';
import 'package:match3_game/services/ads/admob_ad_service.dart';
import 'package:match3_game/services/ads/noop_ad_service.dart';
import 'package:match3_game/services/analytics/analytics_service.dart';
import 'package:match3_game/services/analytics/debug_analytics_service.dart';
import 'package:match3_game/services/audio/audio_service.dart';
import 'package:match3_game/services/audio/haptic_audio_service.dart';
import 'package:match3_game/services/iap/iap_service.dart';
import 'package:match3_game/services/iap/stub_iap_service.dart';
import 'package:match3_game/services/lives/lives_service.dart';
import 'package:match3_game/services/lives/lives_service_impl.dart';
import 'package:match3_game/services/storage/storage_service.dart';
import 'package:match3_game/services/storage/storage_service_impl.dart';

// Provider for persistent key-value storage.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageServiceImpl();
});

// Provider for audio feedback and haptic effects.
// NOTE: Call [AudioService.init()] with await in SplashScreen before first use.
final audioServiceProvider = Provider<AudioService>((ref) {
  return HapticAudioService();
});

// Provider for ad network integrations (AdMob on mobile, No-op on web/desktop).
final adServiceProvider = Provider<AdService>((ref) {
  final AdService service = kIsWeb ? NoopAdService() : AdMobAdService();
  service.init();
  return service;
});

// Provider for in-app purchase catalog and checkout pipelines.
final iapServiceProvider = Provider<IapService>((ref) {
  final service = StubIapService();
  service.init();
  return service;
});

// Provider for telemetry and user funnel analytics.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = DebugAnalyticsService();
  service.init();
  return service;
});

// Provider for timestamp-based player lives replenishment.
final livesServiceProvider = Provider<LivesService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final service = LivesServiceImpl(storage);
  service.init();
  return service;
});

// Stream provider tracking real-time lives count changes.
final livesCountProvider = StreamProvider<int>((ref) {
  final livesService = ref.watch(livesServiceProvider);
  return livesService.livesStream;
});

// Provider for active game session, coin balance, and booster supply persistence.
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return GameRepositoryImpl(storage);
});

// Alias provider matching prompt requirement naming.
final gamRepositoryProvider = gameRepositoryProvider;

// Provider for level configurations and star progress tracking.
final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LevelRepositoryImpl(storage);
});

// Pure logic engine for detecting matches across 2D boards.
final matchDetectorProvider = Provider<MatchDetector>((ref) {
  return const MatchDetector();
});

// Pure logic engine for special piece interactions and multi-piece combos.
final specialCombosProvider = Provider<SpecialCombos>((ref) {
  return const SpecialCombos();
});

// Pure logic engine for applying vertical gravity to falling gems.
final gravityEngineProvider = Provider<GravityEngine>((ref) {
  return const GravityEngine();
});

// Pure logic engine for detecting unsolvable boards and reshuffling.
final deadlockDetectorProvider = Provider<DeadlockDetector>((ref) {
  final matchDetector = ref.watch(matchDetectorProvider);
  return DeadlockDetector(matchDetector);
});

// Pure logic engine for scoring formulas, bonuses, combos, and goals.
final scoreCalculatorProvider = Provider<ScoreCalculator>((ref) {
  return const ScoreCalculator();
});

// Pure logic generator for match-free initial solvable boards.
final boardGeneratorProvider = Provider<BoardGenerator>((ref) {
  final matchDetector = ref.watch(matchDetectorProvider);
  return BoardGenerator(
    random: Random(),
    matchDetector: matchDetector,
  );
});

// Pure logic engine recommending the highest-value move for hints.
final hintEngineProvider = Provider<HintEngine>((ref) {
  final matchDetector = ref.watch(matchDetectorProvider);
  return HintEngine(matchDetector);
});

// Core cascade resolution pipeline orchestrating swaps, matches, gravity, and refills.
final cascadeEngineProvider = Provider<CascadeEngine>((ref) {
  return CascadeEngine(
    matchDetector: ref.watch(matchDetectorProvider),
    specialCombos: ref.watch(specialCombosProvider),
    gravityEngine: ref.watch(gravityEngineProvider),
    deadlockDetector: ref.watch(deadlockDetectorProvider),
    scoreCalculator: ref.watch(scoreCalculatorProvider),
    random: Random(),
  );
});

// Global provider for application settings.
final settingsProvider = settingsNotifierProvider;
