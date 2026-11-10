import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/domain/models/game_state.dart';
import 'package:match3_game/features/game/presentation/providers/game_providers.dart';
import 'package:match3_game/features/game/presentation/widgets/booster_bar.dart';
import 'package:match3_game/features/game/presentation/widgets/game_board_widget.dart';
import 'package:match3_game/features/game/presentation/widgets/goal_indicator.dart';
import 'package:match3_game/features/game/presentation/widgets/hud_widget.dart';
import 'package:match3_game/features/levels/presentation/providers/level_providers.dart';
import 'package:match3_game/features/settings/presentation/providers/settings_providers.dart';

const double _kMaxPortraitWidth = 560;
const double _kMaxLandscapeWidth = 1100;

// Full gameplay screen coordinating board interaction, HUD updates,
// booster controls, ad banners, pause flows, and victory/defeat modals.
class GameScreen extends ConsumerStatefulWidget {
  final int levelId;

  const GameScreen({
    super.key,
    required this.levelId,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  bool _isModalShowing = false;

  /// Key used to persist whether the booster tip has been shown at least once.
  static const String _boosterTipKey = 'boosterTipSeen';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final config = ref.read(levelByIdProvider(widget.levelId));
      ref
          .read(gameNotifierProvider(widget.levelId).notifier)
          .startLevel(config);
      // Show one-time booster tip after level starts.
      await _maybeShowBoosterTip();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(gameNotifierProvider(widget.levelId).notifier).pauseGame();
      ref.read(audioServiceProvider).pauseMusic();
      if (!_isModalShowing && mounted) {
        _showPauseDialog();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Auto-resume music (the game dialog still keeps game paused until player taps Resume)
      ref.read(audioServiceProvider).resumeMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Shows the one-time booster tip popup on the very first game screen visit.
  ///
  /// Storage: uses the existing [storageServiceProvider] (SharedPreferences-backed)
  /// with the bool key `boosterTipSeen`.  No new dependency is required.
  Future<void> _maybeShowBoosterTip() async {
    if (!mounted || _isModalShowing) return;

    final storage = ref.read(storageServiceProvider);
    final alreadySeen = await storage.getBool(_boosterTipKey) ?? false;
    if (alreadySeen || !mounted || _isModalShowing) return;

    // Mark as seen BEFORE showing, so a crash/back-button doesn't re-show it.
    await storage.setBool(_boosterTipKey, true);

    if (!mounted) return;
    _isModalShowing = true;
    ref.read(gameNotifierProvider(widget.levelId).notifier).pauseGame();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close booster tip',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        return _BoosterTipDialog(
          onGotIt: () => Navigator.of(ctx).pop(),
        );
      },
    ).then((_) {
      _isModalShowing = false;
      if (mounted) {
        ref.read(gameNotifierProvider(widget.levelId).notifier).resumeGame();
      }
    });
  }

  void _showPauseDialog() {
    if (_isModalShowing) return;
    _isModalShowing = true;
    ref.read(gameNotifierProvider(widget.levelId).notifier).pauseGame();
    ref.read(audioServiceProvider).pauseMusic();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PauseDialog(
          onResume: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            ref
                .read(gameNotifierProvider(widget.levelId).notifier)
                .resumeGame();
            ref.read(audioServiceProvider).resumeMusic();
          },
          onRestart: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            final config = ref.read(levelByIdProvider(widget.levelId));
            ref
                .read(gameNotifierProvider(widget.levelId).notifier)
                .startLevel(config);
            ref.read(audioServiceProvider).resumeMusic();
          },
          onQuit: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            ref
                .read(gameNotifierProvider(widget.levelId).notifier)
                .saveProgress();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    ).then((_) {
      _isModalShowing = false;
    });
  }

  void _showWinDialog(GameState state) {
    if (_isModalShowing) return;
    _isModalShowing = true;

    final thresholds = state.levelConfig.starThresholds;
    final stars = state.score >= thresholds[2]
        ? 3
        : (state.score >= thresholds[1] ? 2 : 1);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _WinDialog(
          levelId: widget.levelId,
          score: state.score,
          stars: stars,
          onNextLevel: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            final nextLevelId = widget.levelId + 1;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => GameScreen(levelId: nextLevelId),
              ),
            );
          },
          onReplay: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            final config = ref.read(levelByIdProvider(widget.levelId));
            ref
                .read(gameNotifierProvider(widget.levelId).notifier)
                .startLevel(config);
          },
          onQuit: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    ).then((_) {
      _isModalShowing = false;
    });
  }

  void _showLoseDialog(GameState state) {
    if (_isModalShowing) return;
    _isModalShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _LoseDialog(
          score: state.score,
          onWatchAdForMoves: () async {
            final adService = ref.read(adServiceProvider);
            final success = await adService.showRewarded(
              rewardType: 'extra_moves_continue',
              onRewarded: () {
                _isModalShowing = false;
                Navigator.of(dialogContext).pop();
                ref
                    .read(gameNotifierProvider(widget.levelId).notifier)
                    .useBooster(BoosterType.plusFiveMoves, null);
              },
            );
            if (!success && mounted) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('No rewarded video available right now.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onRetry: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            final config = ref.read(levelByIdProvider(widget.levelId));
            ref
                .read(gameNotifierProvider(widget.levelId).notifier)
                .startLevel(config);
          },
          onQuit: () {
            _isModalShowing = false;
            Navigator.of(dialogContext).pop();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    ).then((_) {
      _isModalShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(levelByIdProvider(widget.levelId));
    final settings = ref.watch(settingsNotifierProvider).value;
    final isRemoveAds = settings?.removeAdsPurchased ?? false;
    final adService = ref.watch(adServiceProvider);

    // Listen to level outcome state transitions
    ref.listen<GameState>(gameNotifierProvider(widget.levelId), (prev, next) {
      if (prev?.status != GameStatus.won && next.status == GameStatus.won) {
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) _showWinDialog(next);
        });
      } else if (prev?.status != GameStatus.lost &&
          next.status == GameStatus.lost) {
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) _showLoseDialog(next);
        });
      }
    });

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF150D2B),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A1A52), Color(0xFF150D2B)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isLandscape) {
                  return Center(
                    child: ConstrainedBox(
                      constraints:
                      const BoxConstraints(maxWidth: _kMaxLandscapeWidth),
                      child: Row(
                        children: [
                          // Landscape Left Panel: HUD, Goals, Boosters
                          SizedBox(
                            width: min(constraints.maxWidth * 0.32, 280),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Column(
                                children: [
                                  HudWidget(
                                    levelId: widget.levelId,
                                    onPause: _showPauseDialog,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  GoalIndicator(levelId: widget.levelId),
                                  const Spacer(),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFF2C1B4D), Color(0xFF1E1338)],
                                      ),
                                      borderRadius: AppRadius.borderXl,
                                      border: Border.all(
                                        color: const Color(0x1AFFFFFF),
                                        width: 1.0,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x40000000),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: BoosterBar(levelId: widget.levelId),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Landscape Center: Game Board
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: GameBoardWidget(
                                  levelId: widget.levelId,
                                  config: config,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Portrait layout
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kMaxPortraitWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Top HUD
                        HudWidget(
                          levelId: widget.levelId,
                          onPause: _showPauseDialog,
                        ),

                        // 2. Goal Progress
                        GoalIndicator(levelId: widget.levelId),

                        // 3. Board
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: GameBoardWidget(
                                levelId: widget.levelId,
                                config: config,
                              ),
                            ),
                          ),
                        ),

                        // 4. Booster dock
                        _BoosterDock(levelId: widget.levelId),

                        // 5. Banner (fixed size hota hai, isliye Center mein)
                        if (!isRemoveAds && adService.getBannerWidget() != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xxs),
                              child: adService.getBannerWidget()!,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booster Dock Widget
// ---------------------------------------------------------------------------

class _BoosterDock extends StatelessWidget {
  final int levelId;
  const _BoosterDock({required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C1B4D), Color(0xFF1E1338)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      foregroundDecoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(
          top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: BoosterBar(levelId: levelId),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog Implementations
// ---------------------------------------------------------------------------

class _PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const _PauseDialog({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C1B4D),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME PAUSED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('RESUME', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRestart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text('RESTART LEVEL'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onQuit,
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
              child: const Text('QUIT TO MENU'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinDialog extends StatefulWidget {
  final int levelId;
  final int score;
  final int stars;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onQuit;

  const _WinDialog({
    required this.levelId,
    required this.score,
    required this.stars,
    required this.onNextLevel,
    required this.onReplay,
    required this.onQuit,
  });

  @override
  State<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<_WinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C1B4D),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'VICTORY!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD54F),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Level ${widget.levelId} Cleared',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Cascading Star Award Animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final startInterval = 0.2 + (index * 0.25);
                final starAnimation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    startInterval,
                    min(1.0, startInterval + 0.3),
                    curve: Curves.elasticOut,
                  ),
                );

                final isEarned = index < widget.stars;

                return ScaleTransition(
                  scale: starAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isEarned
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: index == 1 ? 54 : 42,
                      color: isEarned
                          ? const Color(0xFFFFD54F)
                          : Colors.white24,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.md),

            // Score Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: AppRadius.borderMd,
              ),
              child: Text(
                'Score: ${widget.score}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Next Level Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onNextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text(
                  'NEXT LEVEL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: widget.onReplay,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Replay'),
                ),
                TextButton.icon(
                  onPressed: widget.onQuit,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoseDialog extends StatelessWidget {
  final int score;
  final VoidCallback onWatchAdForMoves;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const _LoseDialog({
    required this.score,
    required this.onWatchAdForMoves,
    required this.onRetry,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C1B4D),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 56,
              color: Color(0xFFEF5350),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'OUT OF MOVES',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Don\'t give up! Keep your streak alive.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Watch Ad for +5 Moves Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWatchAdForMoves,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                icon: const Icon(Icons.ondemand_video_rounded, size: 22),
                label: const Text(
                  '+5 MOVES (WATCH AD)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('RETRY LEVEL'),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            TextButton(
              onPressed: onQuit,
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
              child: const Text('QUIT'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One-time Booster Tip Dialog
// ---------------------------------------------------------------------------

/// Animated dialog shown once on first play to teach booster mechanics.
class _BoosterTipDialog extends StatelessWidget {
  final VoidCallback onGotIt;

  const _BoosterTipDialog({required this.onGotIt});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF2C1B4D),
              borderRadius: AppRadius.borderLg,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Title ──
                  Semantics(
                    label: 'BOOSTER TIP dialog',
                    header: true,
                    child: const Text(
                      'BOOSTER TIP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD54F),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── 4 booster icons in a row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _TipIconChip(icon: Icons.hardware_rounded, label: 'Hammer'),
                      _TipIconChip(icon: Icons.shuffle_rounded, label: 'Shuffle'),
                      _TipIconChip(icon: Icons.add_circle_rounded, label: '+5'),
                      _TipIconChip(icon: Icons.palette_rounded, label: 'Color'),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── 3-step guide ──
                  const _TipStep(
                    number: 1,
                    text: 'Select Booster',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _TipStep(
                    number: 2,
                    text: 'Tap on any gem',
                  ),
            /*      const SizedBox(height: AppSpacing.sm),
                  const _TipStep(
                    number: 3,
                    text: 'Tap the booster again to cancel',
                  ),*/

/*                  const SizedBox(height: AppSpacing.md),

                  // ── Urdu line ──
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'Tap on any gem',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),*/

                  const SizedBox(height: AppSpacing.lg),

                  // ── GOT IT button ──
                  Semantics(
                    button: true,
                    label: 'Got it, close booster tip',
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onGotIt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMd,
                          ),
                        ),
                        child: const Text(
                          'GOT IT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
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
    );
  }
}

// A small circular icon + label chip used in the tip dialog's icon row.
class _TipIconChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TipIconChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0x2EFFFFFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.amberAccent, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }
}

/// A numbered step row used in the tip dialog.
class _TipStep extends StatelessWidget {
  final int number;
  final String text;

  const _TipStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF5E35B1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
