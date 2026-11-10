import '../engine/match_detector.dart';
import '../models/game_state.dart';
import '../models/level_config.dart';
import '../models/piece.dart';
import '../models/position.dart';

/// Pure Dart scoring calculator handling piece match points, special bonuses,
/// combo multipliers, star ratings, and goal progress counters.
class ScoreCalculator {
  const ScoreCalculator();

  /// Calculates the base score earned by clearing a [match] (60 points per gem).
  int baseScore(BoardMatch match) => match.length * 60;

  /// Extra bonus awarded when a special piece is created or detonated.
  int specialBonus(SpecialType special) => switch (special) {
        StripedHSpecial() || StripedVSpecial() => 200,
        WrappedSpecial() => 400,
        ColorBombSpecial() => 1000,
        NoneSpecial() => 0,
      };

  /// Returns the cascade combo multiplier: 1.0x, 1.5x, 2.0x, 3.0x, 4.0x, etc.
  double comboMultiplier(int cascadeLevel) {
    if (cascadeLevel <= 1) return 1.0;
    if (cascadeLevel == 2) return 1.5;
    if (cascadeLevel == 3) return 2.0;
    if (cascadeLevel == 4) return 3.0;
    return 4.0 + (cascadeLevel - 5).clamp(0, 10) * 1.0;
  }

  /// Calculates end-of-game victory bonus for remaining unspent moves (100 pts per move).
  int calculateBonus(int movesLeft) => movesLeft > 0 ? movesLeft * 100 : 0;

  /// Evaluates 1, 2, or 3 star rating against level thresholds.
  int starRating(int score, List<int> thresholds) {
    if (thresholds.length != 3) {
      thresholds = const [1000, 2500, 4500];
    }
    if (score >= thresholds[2]) return 3;
    if (score >= thresholds[1]) return 2;
    if (score >= thresholds[0]) return 1;
    return 0;
  }

  /// Updates the progress map for all goals defined in [state.levelConfig].
  Map<String, int> updateGoalProgress(
    GameState state, {
    required List<Position> clearedPositions,
    required List<Piece> clearedPieces,
    int clearedJellyLayers = 0,
  }) {
    final updated = Map<String, int>.from(state.goalProgress);

    for (final goal in state.levelConfig.goals) {
      switch (goal) {
        case TargetScore():
          updated[goal.id] = state.score;
          break;
        case CollectPieces(:final pieceType):
          final count =
              clearedPieces.where((p) => p.pieceType == pieceType).length;
          updated[goal.id] = (updated[goal.id] ?? 0) + count;
          break;
        case ClearAllJelly():
          updated[goal.id] = (updated[goal.id] ?? 0) + clearedJellyLayers;
          break;
        case DropIngredients():
          break;
      }
    }

    return updated;
  }
}
