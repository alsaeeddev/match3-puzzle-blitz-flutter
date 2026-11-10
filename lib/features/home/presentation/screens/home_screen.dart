import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/core/theme/gem_palette.dart';
import 'package:match3_game/features/game/domain/models/piece.dart';
import 'package:match3_game/features/levels/presentation/providers/level_providers.dart';
import 'package:match3_game/features/levels/presentation/screens/level_select_screen.dart';
import 'package:match3_game/features/rewards/presentation/providers/reward_providers.dart';
import 'package:match3_game/features/rewards/presentation/widgets/daily_reward_dialog.dart';
import 'package:match3_game/features/settings/presentation/screens/settings_screen.dart';
import 'package:match3_game/features/shop/presentation/providers/shop_providers.dart';
import 'package:match3_game/features/shop/presentation/screens/shop_screen.dart';

/// Central game hub screen linking to gameplay, saga map, store, daily streaks,
/// settings, and real-time life regeneration counters.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  Timer? _lifeCountdownTimer;
  String _timeUntilNextLife = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _startLifeTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _lifeCountdownTimer?.cancel();
    super.dispose();
  }

  void _startLifeTimer() {
    _updateTimerString();
    _lifeCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTimerString();
    });
  }

  Future<void> _updateTimerString() async {
    final currentLives = ref.read(livesCountProvider).value ?? 5;
    if (currentLives >= 5) {
      if (_timeUntilNextLife.isNotEmpty && mounted) {
        setState(() => _timeUntilNextLife = '');
      }
      return;
    }

    final livesService = ref.read(livesServiceProvider);
    final nextTime = await livesService.getNextRegenTime();
    if (nextTime == null) {
      if (_timeUntilNextLife.isNotEmpty && mounted) {
        setState(() => _timeUntilNextLife = '');
      }
      return;
    }

    final now = DateTime.now();
    final diff = nextTime.difference(now);
    if (diff.isNegative) {
      await livesService.syncLives();
      return;
    }

    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    final formatted = '$minutes:$seconds';

    if (_timeUntilNextLife != formatted && mounted) {
      setState(() => _timeUntilNextLife = formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final coins = ref.watch(coinsProvider).value ?? 0;
    final lives = ref.watch(livesCountProvider).value ?? 5;
    final canClaimDaily = ref.watch(canClaimRewardProvider);
    final progressList = ref.watch(levelProgressProvider).value ?? [];
    final settings = ref.watch(settingsProvider).value;
    final isRemoveAds = settings?.removeAdsPurchased ?? false;

    // Highest unlocked level
    final highestUnlocked = progressList
        .where((p) => p.isUnlocked)
        .map((p) => p.levelId)
        .fold(1, max);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF191636), Color(0xFF261C4E), Color(0xFF0F0C20)],
          ),
        ),
        child: Stack(
          children: [
            // Background Floating Gem Particles
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _FloatingGemsPainter(
                    progress: _floatController.value,
                  ),
                );
              },
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top Header Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Lives Widget
                                InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ShopScreen(),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFFFF5252),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Color(0xFFFF5252),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$lives/5',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (_timeUntilNextLife.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            _timeUntilNextLife,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Coins & Settings
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Coins Widget
                                    InkWell(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ShopScreen(),
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFFD700),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.monetization_on,
                                              color: Color(0xFFFFD700),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$coins',
                                              style: const TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Settings Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.settings,
                                        color: Colors.white70,
                                        size: 26,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SettingsScreen(),
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Game Logo Header
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + 0.03 * _pulseController.value;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                // Jewel Crown Icon
                                const Icon(
                                  Icons.diamond,
                                  size: 64,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(height: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFF5252),
                                        Color(0xFF00E5FF),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    strings.appTitle.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 18,
                                          color: Colors.purpleAccent,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    strings.levelLabel(highestUnlocked),
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          //  const Spacer(),
                          const SizedBox(height: AppSpacing.xl),

                          // Menu Action Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: Column(
                              children: [
                                // Play / Continue Button
                                _buildPrimaryButton(
                                  title: strings.continueGame.toUpperCase(),
                                  icon: Icons.play_arrow,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E676),
                                      Color(0xFF00B0FF),
                                    ],
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LevelSelectScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Level Map Button
                                /*                   _buildMenuButton(
                          title: strings.levelMap,
                          icon: Icons.map,
                          color: const Color(0xFF9C27B0),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LevelSelectScreen(),
                            ),
                          ),
                        ),*/
                                // const SizedBox(height: AppSpacing.md),

                                // Daily Reward & Shop Row
                                Row(
                                  children: [
                                    // Daily Reward Button with Badge
                                    Expanded(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          _buildMenuButton(
                                            title: strings.dailyReward,
                                            icon: Icons.card_giftcard,
                                            color: const Color(0xFFFF9800),
                                            onPressed: () =>
                                                DailyRewardDialog.show(context),
                                          ),
                                          if (canClaimDaily)
                                            Positioned(
                                              right: -4,
                                              top: -4,
                                              child: AnimatedBuilder(
                                                animation: _pulseController,
                                                builder: (context, child) {
                                                  return Transform.scale(
                                                    scale:
                                                        1.0 +
                                                        0.2 *
                                                            _pulseController
                                                                .value,
                                                    child: child,
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.redAccent,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .redAccent,
                                                            blurRadius: 6,
                                                          ),
                                                        ],
                                                      ),
                                                  child: const Icon(
                                                    Icons.priority_high,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    // Shop Button
                                    Expanded(
                                      child: _buildMenuButton(
                                        title: strings.shop,
                                        icon: Icons.store,
                                        color: const Color(0xFFE91E63),
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ShopScreen(),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // AdMob Banner Container at bottom
                          if (!isRemoveAds)
                            Container(
                              width: double.infinity,
                              height: 50,
                              color: Colors.black26,
                              child: Center(
                                child: Text(
                                  'AdMob Banner',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = 0.3 + 0.2 * _pulseController.value;
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: glowAlpha),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF221E42),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for atmospheric background floating gems.
class _FloatingGemsPainter extends CustomPainter {
  final double progress;

  _FloatingGemsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final pieces = PieceType.values;
    final paint = Paint()..style = PaintingStyle.fill;

    // 10 floating gems at deterministic positions
    for (var i = 0; i < 10; i++) {
      final seedX = ((i * 73) % 100) / 100.0;
      final seedSpeed = 0.5 + ((i * 37) % 50) / 100.0;
      final piece = pieces[i % pieces.length];

      final yOffset = ((progress * seedSpeed + (i * 0.1)) % 1.0) * size.height;
      final xOffset = (seedX * size.width) + sin(progress * 2 * pi + i) * 20.0;

      final color = GemPalette.gemColor(piece).withValues(alpha: 0.15);
      paint.color = color;

      canvas.drawCircle(Offset(xOffset, yOffset), 12.0 + (i % 4) * 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingGemsPainter oldDelegate) => true;
}
