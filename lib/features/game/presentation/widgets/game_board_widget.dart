import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/constants/game_config.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/core/theme/gem_palette.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/game/domain/models/position.dart';
import 'package:match3_game/features/game/presentation/painters/board_painter.dart';
import 'package:match3_game/features/game/presentation/painters/particle_painter.dart';
import 'package:match3_game/features/game/presentation/providers/game_providers.dart';
import 'package:match3_game/features/game/presentation/widgets/gem_widget.dart';
import 'package:match3_game/features/settings/presentation/providers/settings_providers.dart';

/// Temporary floating score visual token that ascends and fades out.
class _ScorePopupItem {
  final String text;
  final Offset position;
  final DateTime createdAt;

  _ScorePopupItem({
    required this.text,
    required this.position,
    required this.createdAt,
  });
}

/// The main interactive puzzle grid widget.
///
/// Handles touch swipes, piece taps, particle physics tickers, screen shakes,
/// and layered absolute positioning of all animated gem cells.
class GameBoardWidget extends ConsumerStatefulWidget {
  final int levelId;
  final LevelConfig config;

  const GameBoardWidget({
    super.key,
    required this.levelId,
    required this.config,
  });

  @override
  ConsumerState<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends ConsumerState<GameBoardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _glowController;
  late final ParticleSystem _particleSystem;
  Ticker? _particleTicker;
  Duration _lastTickerTime = Duration.zero;

  StreamSubscription<GameEvent>? _eventSub;

  final Set<Position> _clearingPositions = {};
  final Map<Position, Offset> _fallOffsets = {};
  final Set<Position> _spawnPositions = {};
  final List<_ScorePopupItem> _scorePopups = [];

  Offset? _panStartOffset;
  Position? _panStartPosition;
  bool _swipeHandled = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Subtle pulse/glow when a booster is armed – pure paint level, no layout.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particleSystem = ParticleSystem();
    _particleTicker = createTicker(_onParticleTick);

    // Subscribe to domain cascade engine events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToEvents();
    });
  }

  void _listenToEvents() {
    final notifier = ref.read(gameNotifierProvider(widget.levelId).notifier);
    _eventSub?.cancel();
    _eventSub = notifier.events.listen(_handleGameEvent);
  }

  void _handleGameEvent(GameEvent event) {
    if (!mounted) return;

    final gameState = ref.read(gameNotifierProvider(widget.levelId));
    final board = gameState.board;
    final cellSize = _computeCellSize();

    switch (event) {
      case ClearEvent(:final positions):
        setState(() {
          _clearingPositions.addAll(positions);
        });

        for (final pos in positions) {
          final cell = board.cellOrNull(pos);
          final color = cell?.content.piece != null
              ? GemPalette.gemColor(cell!.content.piece!.pieceType)
              : Colors.amberAccent;
          final center = Offset(
            (pos.col + 0.5) * cellSize,
            (pos.row + 0.5) * cellSize,
          );
          _particleSystem.emitMatchParticles(center, color, 12);
        }
        _startParticleTicker();

        Future.delayed(
          const Duration(milliseconds: GameConfig.matchClearDurationMs),
          () {
            if (mounted) {
              setState(() {
                _clearingPositions.removeAll(positions);
              });
            }
          },
        );

      case ComboEvent(:final multiplier):
        if (multiplier >= 3) {
          _shakeController.forward(from: 0.0);
          final boardW = widget.config.cols * cellSize;
          final boardH = widget.config.rows * cellSize;
          _particleSystem.emitComboParticles(
            Offset(boardW / 2, boardH / 2),
            multiplier,
          );
          _startParticleTicker();
        }

      case GravityFallEvent(:final moves):
        setState(() {
          for (final move in moves) {
            final from = move.$1;
            final to = move.$2;
            _fallOffsets[to] = Offset(0, (from.row - to.row) * cellSize);
          }
        });

        Future.delayed(
          const Duration(milliseconds: GameConfig.gravityFallDurationMs),
          () {
            if (mounted) {
              setState(() {
                _fallOffsets.clear();
              });
            }
          },
        );

      case RefillEvent(:final pieces):
        setState(() {
          for (final (pos, _) in pieces) {
            _spawnPositions.add(pos);
          }
        });

        Future.delayed(
          const Duration(milliseconds: GameConfig.refillFallDurationMs),
          () {
            if (mounted) {
              setState(() {
                _spawnPositions.clear();
              });
            }
          },
        );

      case MatchEvent(:final positions):
        if (positions.isNotEmpty) {
          final centerPos = positions[positions.length ~/ 2];
          final posOffset = Offset(
            (centerPos.col + 0.5) * cellSize,
            (centerPos.row + 0.5) * cellSize,
          );
          _addScorePopup(posOffset, positions.length * 60);
        }

      default:
        break;
    }
  }

  void _addScorePopup(Offset position, int points) {
    final item = _ScorePopupItem(
      text: '+$points',
      position: position,
      createdAt: DateTime.now(),
    );
    setState(() {
      _scorePopups.add(item);
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _scorePopups.remove(item);
        });
      }
    });
  }

  void _startParticleTicker() {
    if (_particleTicker != null && !_particleTicker!.isActive) {
      _lastTickerTime = Duration.zero;
      _particleTicker!.start();
    }
  }

  void _onParticleTick(Duration elapsed) {
    if (_lastTickerTime == Duration.zero) {
      _lastTickerTime = elapsed;
      return;
    }

    final dt = (elapsed - _lastTickerTime).inMicroseconds / 1000000.0;
    _lastTickerTime = elapsed;

    if (_particleSystem.hasActiveParticles) {
      _particleSystem.update(dt.clamp(0.0, 0.05));
      setState(() {});
    } else {
      _particleTicker?.stop();
    }
  }

  double _computeCellSize() {
    // Fallback dimension calculation if called outside layout builder
    return 48.0;
  }

  Position? _positionToCell(Offset localOffset, double cellSize) {
    final col = (localOffset.dx / cellSize).floor();
    final row = (localOffset.dy / cellSize).floor();

    if (row >= 0 &&
        row < widget.config.rows &&
        col >= 0 &&
        col < widget.config.cols) {
      return Position(row, col);
    }
    return null;
  }

  void _onSwap(Position from, Position to) {
    ref
        .read(gameNotifierProvider(widget.levelId).notifier)
        .swapPieces(from, to);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _particleTicker?.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider(widget.levelId));
    final isAnimating = ref.watch(isAnimatingProvider(widget.levelId));
    final selectedPos = ref.watch(selectedPositionProvider(widget.levelId));
    final hintMove = ref.watch(hintPositionProvider(widget.levelId));
    final settings = ref.watch(settingsNotifierProvider).value;
    final colorBlindMode = settings?.colorBlindMode ?? false;

    // Drive the glow pulse based on armed state – no layout change.
    final isArmed = gameState.activeBooster != null;
    if (isArmed && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!isArmed && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Frame constants (no magic numbers except the frame itself)
        const double framePadding = 6.0;
        const double frameBorderW = 1.5;
        const double frameInset = framePadding + frameBorderW; // = 7.5

        final availableW = constraints.maxWidth - 2 * frameInset;
        final availableH = constraints.maxHeight - 2 * frameInset;
        final cellSize = min(
          availableW / widget.config.cols,
          availableH / widget.config.rows, // use rows not maxDimension
        ).floorToDouble();
        // NO clamp

        final boardWidth = widget.config.cols * cellSize;
        final boardHeight = widget.config.rows * cellSize;

        return Center(
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shakeProgress = _shakeController.value;
              final shakeOffset = Offset(
                sin(shakeProgress * pi * 8) * 6.0 * (1.0 - shakeProgress),
                cos(shakeProgress * pi * 8) * 3.0 * (1.0 - shakeProgress),
              );

              return Transform.translate(
                offset: shakeOffset,
                child: child,
              );
            },
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glowT = isArmed ? _glowController.value : 0.0;

                // Frame border color: lerp between white18% and amberAccent85% when armed
                final frameBorderColor = Color.lerp(
                  Colors.white.withValues(alpha: 0.18),
                  Colors.amberAccent.withValues(alpha: 0.85),
                  glowT,
                )!;

                final frameBoxShadow = isArmed
                    ? [
                        BoxShadow(
                          color: Colors.amberAccent
                              .withValues(alpha: 0.35 + 0.25 * glowT),
                          blurRadius: 14,
                            offset: Offset.zero,
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 12,
                            offset: Offset.zero
                        ),
                      ];

                return Container(
                  // Frame is exactly board + 2*frameInset each side
                  width: boardWidth + 2 * (framePadding + frameBorderW),
                  height: boardHeight + 2 * (framePadding + frameBorderW),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A2468), Color(0xFF231640)],
                    ),
                    borderRadius: AppRadius.borderXl,
                    border:
                        Border.all(color: frameBorderColor, width: frameBorderW),
                    boxShadow: frameBoxShadow,
                  ),
                  padding: const EdgeInsets.all(framePadding),
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: isArmed
                          ? (0.85 + 0.15 * _glowController.value)
                          : 1.0,
                      child: SizedBox(
                        width: boardWidth,
                        height: boardHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: isAnimating
                              ? null
                              : (details) {
                                  _panStartOffset = details.localPosition;
                                  _panStartPosition = _positionToCell(
                                    details.localPosition,
                                    cellSize,
                                  );
                                  _swipeHandled = false;
                                },
                          onPanUpdate: isAnimating
                              ? null
                              : (details) {
                                  if (_swipeHandled ||
                                      _panStartOffset == null ||
                                      _panStartPosition == null) {
                                    return;
                                  }

                                  final delta =
                                      details.localPosition - _panStartOffset!;
                                  if (delta.distance >= 14.0) {
                                    final from = _panStartPosition!;
                                    final Position to;
                                    if (delta.dx.abs() > delta.dy.abs()) {
                                      to = Position(
                                        from.row,
                                        from.col + (delta.dx > 0 ? 1 : -1),
                                      );
                                    } else {
                                      to = Position(
                                        from.row + (delta.dy > 0 ? 1 : -1),
                                        from.col,
                                      );
                                    }

                                    if (gameState.board.isValidPosition(to)) {
                                      _onSwap(from, to);
                                      _swipeHandled = true;
                                    }
                                  }
                                },
                          onTapUp: isAnimating
                              ? null
                              : (details) {
                                  if (_swipeHandled) return;
                                  final pos = _positionToCell(
                                    details.localPosition,
                                    cellSize,
                                  );
                                  if (pos != null) {
                                    ref
                                        .read(
                                          gameNotifierProvider(widget.levelId)
                                              .notifier,
                                        )
                                        .selectPiece(pos);
                                  }
                                },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 1. Static Board Background Grid (Isolated via RepaintBoundary)
                              RepaintBoundary(
                                child: CustomPaint(
                                  size: Size(boardWidth, boardHeight),
                                  painter: BoardPainter(
                                    board: gameState.board,
                                    cellSize: cellSize,
                                  ),
                                ),
                              ),

                              // 2. Interactive Gem Layer
                              // Each gem occupies its full cell; visual gap is
                              // achieved by Padding INSIDE the GestureDetector
                              // so the full cell area is tappable.
                              for (var r = 0; r < widget.config.rows; r++)
                                for (var c = 0; c < widget.config.cols; c++)
                                  if (!gameState.board
                                      .isBlocked(Position(r, c)))
                                    Positioned(
                                      left: c * cellSize,
                                      top: r * cellSize,
                                      width: cellSize,
                                      height: cellSize,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: isAnimating
                                            ? null
                                            : () {
                                                ref
                                                    .read(
                                                      gameNotifierProvider(
                                                        widget.levelId,
                                                      ).notifier,
                                                    )
                                                    .selectPiece(
                                                      Position(r, c),
                                                    );
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: GemWidget(
                                            key: ValueKey('gem_${r}_$c'),
                                            size: cellSize - 4,
                                            cell: gameState.board.cells[r][c],
                                            position: Position(r, c),
                                            isSelected:
                                                selectedPos == Position(r, c),
                                            isHinted:
                                                hintMove?.$1 ==
                                                    Position(r, c) ||
                                                hintMove?.$2 == Position(r, c),
                                            colorBlindMode: colorBlindMode,
                                            fallFromOffset:
                                                _fallOffsets[Position(r, c)],
                                            isClearAnimating: _clearingPositions
                                                .contains(Position(r, c)),
                                            isSpawnAnimating: _spawnPositions
                                                .contains(Position(r, c)),
                                            // onTap handled by outer GestureDetector
                                            onTap: null,
                                          ),
                                        ),
                                      ),
                                    ),

                              // 3. Foreground Particle Effects (Isolated via RepaintBoundary)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: ParticlePainter(
                                        _particleSystem.particles,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 4. Floating Score Popups
                              for (final popup in _scorePopups)
                                _ScorePopupWidget(
                                  key: ObjectKey(popup),
                                  item: popup,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: null,
            ),
          ),
        );
      },
    );
  }
}

/// Floating animated text for points awarded during clears.
class _ScorePopupWidget extends StatefulWidget {
  final _ScorePopupItem item;

  const _ScorePopupWidget({
    super.key,
    required this.item,
  });

  @override
  State<_ScorePopupWidget> createState() => _ScorePopupWidgetState();
}

class _ScorePopupWidgetState extends State<_ScorePopupWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _translateAnimation = Tween<double>(begin: 0.0, end: -35.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.item.position.dx - 24,
          top: widget.item.position.dy + _translateAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Text(
              widget.item.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD54F),
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
