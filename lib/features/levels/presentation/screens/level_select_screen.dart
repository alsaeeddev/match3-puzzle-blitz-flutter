import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/game/presentation/screens/game_screen.dart';
import 'package:match3_game/features/levels/domain/models/level_progress.dart';
import 'package:match3_game/features/levels/presentation/providers/level_providers.dart';
import 'package:match3_game/features/shop/presentation/providers/shop_providers.dart';
import 'package:match3_game/features/shop/presentation/screens/shop_screen.dart';

/// Saga-style meandering map of all 50 levels with star progression,
/// custom path drawing, and pre-level booster loadout modals.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Auto-scroll to current active level after initial layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveLevel());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToActiveLevel() {
    final progressList = ref.read(levelProgressProvider).value ?? [];
    final highestUnlocked = progressList
        .where((p) => p.isUnlocked)
        .map((p) => p.levelId)
        .fold(1, max);

    // Invert because level 1 is at bottom and level 50 at top
    final targetOffset = (50 - highestUnlocked) * 85.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openLevelPreview(LevelConfig level, LevelProgress? progress) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LevelPreviewDialog(level: level, progress: progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final levels = ref.watch(levelConfigsProvider);
    final progressAsync = ref.watch(levelProgressProvider);
    final lives = ref.watch(livesCountProvider).value ?? 5;

    final progressList = progressAsync.value ?? [];
    final progressMap = {for (final p in progressList) p.levelId: p};

    final totalStars = progressList
        .map((p) => p.stars)
        .fold(0, (a, b) => a + b);
    final maxStars = levels.length * 3;

    return Scaffold(
      backgroundColor: const Color(0xFF131127),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E38),
        elevation: 0,
        title: Text(
          strings.levelSelectTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Total Stars
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$totalStars / $maxStars',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Lives Chip
          InkWell(
            // onTap: () => ShopScreen.showAsModal(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: const Color(0xFFFF5252)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF5252),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$lives/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        tooltip: 'Scroll to Current',
        onPressed: _scrollToActiveLevel,
        child: const Icon(Icons.my_location),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const nodeHeight = 90.0;
          final totalHeight = levels.length * nodeHeight + 100.0;

          // Compute horizontal center offsets in a smooth sine wave
          final nodeOffsets = <Offset>[];
          for (var i = 0; i < levels.length; i++) {
            // Level 1 is at index 0 (bottom of map)
            final y = totalHeight - 80.0 - (i * nodeHeight);
            final x = (width / 2) + sin(i * 0.7) * (width * 0.28);
            nodeOffsets.add(Offset(x, y));
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              width: width,
              height: totalHeight,
              child: Stack(
                children: [
                  // Winding Trail Painter
                  CustomPaint(
                    size: Size(width, totalHeight),
                    painter: _SagaTrailPainter(nodeOffsets: nodeOffsets),
                  ),

                  // Level Nodes
                  for (var i = 0; i < levels.length; i++) ...[
                    _buildLevelNode(
                      level: levels[i],
                      progress: progressMap[levels[i].id],
                      offset: nodeOffsets[i],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelNode({
    required LevelConfig level,
    required LevelProgress? progress,
    required Offset offset,
  }) {
    // Level 1 is always unlocked by default
    final isUnlocked = level.id == 1 || (progress?.isUnlocked ?? false);
    final stars = progress?.stars ?? 0;
    final isCompleted = stars > 0;

    return Positioned(
      left: offset.dx - 36,
      top: offset.dy - 36,
      child: GestureDetector(
        onTap: () {
          if (isUnlocked) {
            _openLevelPreview(level, progress);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete previous levels to unlock!'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Node Button
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final isCurrent = isUnlocked && !isCompleted;
                final scale = isCurrent
                    ? (1.0 + 0.08 * _pulseController.value)
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? (isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFF00E676), Color(0xFF00897B)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                              ))
                      : const LinearGradient(
                          colors: [Color(0xFF424242), Color(0xFF212121)],
                        ),
                  border: Border.all(
                    color: isUnlocked
                        ? (isCompleted ? const Color(0xFFFFD700) : Colors.white)
                        : Colors.white24,
                    width: isUnlocked ? 3.0 : 1.5,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color:
                                (isCompleted
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent)
                                    .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isUnlocked
                      ? Text(
                          '${level.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Color(0xCC000000),
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        )
                      : const Icon(Icons.lock, color: Colors.white38, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 3),

            // Stars Row for Completed Levels
            if (isCompleted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var s = 1; s <= 3; s++)
                    Icon(
                      s <= stars ? Icons.star : Icons.star_border,
                      size: 14,
                      color: s <= stars
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                    ),
                ],
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

/// Modal preview card for inspecting goals and picking boosters before playing.
class _LevelPreviewDialog extends ConsumerStatefulWidget {
  final LevelConfig level;
  final LevelProgress? progress;

  const _LevelPreviewDialog({required this.level, required this.progress});

  @override
  ConsumerState<_LevelPreviewDialog> createState() =>
      _LevelPreviewDialogState();
}

class _LevelPreviewDialogState extends ConsumerState<_LevelPreviewDialog> {
  final Set<BoosterType> _selectedBoosters = {};

  void _startGame() async {
    final livesService = ref.read(livesServiceProvider);
    final lives =
        ref.read(livesCountProvider).value ?? await livesService.getLives();

    if (lives <= 0) {
      // Capture context-dependent objects synchronously before any async gap.
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context, rootNavigator: true);
      final strings = ref.read(stringsProvider);

      navigator.pop(); // preview dialog band

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(strings.noLivesTitle),
          duration: const Duration(seconds: 4),
          persist: false,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          action: SnackBarAction(
            label: strings.shop,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              navigator.push(
                MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    // Consume 1 life
    await livesService.consumeLife();

    // Consume pre-selected boosters from inventory
    for (final booster in _selectedBoosters) {
      await ref.read(boosterInventoryProvider.notifier).useBooster(booster);
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Close preview

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(levelId: widget.level.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final inventory = ref.watch(boosterInventoryProvider).value ?? {};
    final bestScore = widget.progress?.bestScore ?? 0;
    final stars = widget.progress?.stars ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E38),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFFF9800), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level Title
            Text(
              strings.levelLabel(widget.level.id),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Goal Description
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    widget.level.goals
                        .map((g) => _formatGoal(g, strings))
                        .join('\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.level.timerSeconds != null
                        ? '${widget.level.timerSeconds}s ${strings.timeLeft}'
                        : '${widget.level.maxMoves} ${strings.movesLeft}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Best Score & Stars
            if (bestScore > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var s = 1; s <= 3; s++)
                    Icon(
                      s <= stars ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFD700),
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${strings.bestScore}: $bestScore',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Pre-Game Booster Prep
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pre-select Boosters:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBoosterToggle(
                  BoosterType.hammer,
                  Icons.gavel,
                  inventory[BoosterType.hammer] ?? 0,
                ),
                _buildBoosterToggle(
                  BoosterType.shuffle,
                  Icons.shuffle,
                  inventory[BoosterType.shuffle] ?? 0,
                ),
                _buildBoosterToggle(
                  BoosterType.plusFiveMoves,
                  Icons.add_circle,
                  inventory[BoosterType.plusFiveMoves] ?? 0,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Play Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 28),
                    const SizedBox(width: 6),
                    Text(
                      strings.playCost,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoosterToggle(BoosterType type, IconData icon, int count) {
    final isSelected = _selectedBoosters.contains(type);
    final hasInventory = count > 0;

    return InkWell(
      onTap: hasInventory
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedBoosters.remove(type);
                } else {
                  _selectedBoosters.add(type);
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9800).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9800)
                : (hasInventory ? Colors.white24 : Colors.white10),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: hasInventory ? Colors.white : Colors.white24,
                size: 24,
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Text(
                '$count',
                style: TextStyle(
                  color: hasInventory
                      ? const Color(0xFFFFD700)
                      : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGoal(LevelGoal goal, AppStrings strings) {
    return switch (goal) {
      TargetScore(:final targetScore) => '${strings.targetScore}: $targetScore',
      ClearAllJelly() => strings.clearJelly,
      CollectPieces(:final count, :final pieceType) =>
        '${strings.collectPieces}: $count ${pieceType.name}',
      DropIngredients(:final count) => '${strings.dropIngredients}: $count',
    };
  }
}

/// Custom painter rendering the meandering path connecting all 50 saga nodes.
class _SagaTrailPainter extends CustomPainter {
  final List<Offset> nodeOffsets;

  _SagaTrailPainter({required this.nodeOffsets});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeOffsets.length < 2) return;

    final path = Path();
    path.moveTo(nodeOffsets.first.dx, nodeOffsets.first.dy);

    for (var i = 0; i < nodeOffsets.length - 1; i++) {
      final p1 = nodeOffsets[i];
      final p2 = nodeOffsets[i + 1];

      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;

      path.quadraticBezierTo(p1.dx, midY, midX, midY);
      path.quadraticBezierTo(p2.dx, midY, p2.dx, p2.dy);
    }

    // Outer glow path
    final glowPaint = Paint()
      ..color = const Color(0x33FF9800)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // Inner dashed or solid road
    final roadPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant _SagaTrailPainter oldDelegate) => false;
}
