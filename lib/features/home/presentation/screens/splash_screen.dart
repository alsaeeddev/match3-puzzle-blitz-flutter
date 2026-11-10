import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/core/theme/gem_palette.dart';
import 'package:match3_game/features/game/domain/models/piece.dart';
import 'package:match3_game/features/home/presentation/screens/home_screen.dart';
import 'package:match3_game/features/levels/presentation/providers/level_providers.dart';
import 'package:match3_game/features/rewards/presentation/providers/reward_providers.dart';
import 'package:match3_game/features/shop/presentation/providers/shop_providers.dart';

const double _emblemSize = 180;

// Animated splash: asset-free vector logo + parallel service initialization.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final _SplashEmblemPainter _painter;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _painter = _SplashEmblemPainter(_animController);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeServices());
  }

  @override
  void dispose() {
    _animController.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Min branding time, loading ke saath parallel
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 800));

    const totalTasks = 6;
    var doneTasks = 0;

    Future<T> track<T>(Future<T> task) async {
      final result = await task;
      doneTasks++;
      _progress.value = doneTasks / totalTasks * 0.95;
      return result;
    }

    final audio = ref.read(audioServiceProvider);
    final settingsFuture = ref.read(settingsProvider.future);

    try {
      await Future.wait<Object?>([
        track(settingsFuture),
        track(ref.read(levelProgressProvider.future)),
        track(ref.read(rewardNotifierProvider.future)),
        track(ref.read(coinsProvider.future)),
        track(ref.read(boosterInventoryProvider.future)),
        track(() async {
          await audio.init();
          final settings = await settingsFuture;
          if (settings.musicEnabled) {
            unawaited(audio.startMusic()); // splash ko block nahi karega
          }
        }()),
        minSplash,
      ]);
    } catch (e, st) {
      debugPrint('[Splash] init error: $e\n$st');
    }

    if (!mounted) return;
    _progress.value = 1.0;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => const HomeScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated emblem: widget rebuild nahi, sirf repaint
              RepaintBoundary(
                child: CustomPaint(
                  size: const Size(_emblemSize, _emblemSize),
                  painter: _painter,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Static title
              RepaintBoundary(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFF6B6B),
                        Color(0xFF4DEEEA),
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    strings.appTitle.toUpperCase(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 16.0,
                          color: Colors.cyanAccent,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'PUZZLE ADVENTURE',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        height: 10,
                        width: double.infinity,
                        color: Colors.white12,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _progress,
                          builder: (context, value, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value.clamp(0.0, 1.0),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFFFEB3B),
                                      Color(0xFF00E676),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x8000E676),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      strings.loading,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// Rotating gem constellation. Shaders cached, per-frame allocation minimal.
class _SplashEmblemPainter extends CustomPainter {
  _SplashEmblemPainter(this.animation) : super(repaint: animation) {
    final pieces = PieceType.values;
    _gemColors = [for (final p in pieces) GemPalette.gemColor(p)];

    // Sab shaders origin (0,0) pe bane hain, canvas translate karke use hote hain
    _haloShader = RadialGradient(
      colors: const [
        Color(0x40FFD700),
        Color(0x10FF6B6B),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: _haloRadius));

    _gemShaders = [
      for (final c in _gemColors)
        RadialGradient(
          colors: [Colors.white, c],
          stops: const [0.1, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: _gemRadius)),
    ];
    _glowColors = [for (final c in _gemColors) c.withValues(alpha: 0.3)];

    _coreShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD54F), Color(0xFFFF6F00)],
    ).createShader(
      Rect.fromCircle(center: Offset.zero, radius: _primaryRadius * 1.08),
    );
  }

  final Animation<double> animation;

  static const double _primaryRadius = _emblemSize * 0.22;
  static const double _orbitRadius = _emblemSize * 0.38;
  static const double _gemRadius = _emblemSize * 0.08;
  static const double _haloRadius = _orbitRadius * 1.3;

  late final List<Color> _gemColors;
  late final List<Color> _glowColors;
  late final List<Shader> _gemShaders;
  late final Shader _haloShader;
  late final Shader _coreShader;

  final Paint _paint = Paint()..isAntiAlias = true;
  final Path _corePath = Path();
  final Path _innerPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    // Halo
    _paint
      ..shader = _haloShader
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, _haloRadius, _paint);

    // Orbiting gems
    final total = _gemColors.length;
    final baseAngle = progress * 2 * pi;
    final step = 2 * pi / total;

    for (var i = 0; i < total; i++) {
      final angle = baseAngle + i * step;
      canvas.save();
      canvas.translate(_orbitRadius * cos(angle), _orbitRadius * sin(angle));

      _paint
        ..shader = null
        ..color = _glowColors[i];
      canvas.drawCircle(Offset.zero, _gemRadius * 1.6, _paint);

      _paint.shader = _gemShaders[i];
      canvas.drawCircle(Offset.zero, _gemRadius, _paint);

      canvas.restore();
    }

    // Center diamond (pulse)
    final r = _primaryRadius * (1.0 + 0.08 * sin(progress * 4 * pi));
    _corePath
      ..reset()
      ..moveTo(0, -r)
      ..lineTo(r, 0)
      ..lineTo(0, r)
      ..lineTo(-r, 0)
      ..close();
    _paint.shader = _coreShader;
    canvas.drawPath(_corePath, _paint);

    // Inner facet
    final ir = r * 0.55;
    _innerPath
      ..reset()
      ..moveTo(0, -ir)
      ..lineTo(ir, 0)
      ..lineTo(0, ir)
      ..lineTo(-ir, 0)
      ..close();
    _paint
      ..shader = null
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawPath(_innerPath, _paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashEmblemPainter oldDelegate) => false;
}