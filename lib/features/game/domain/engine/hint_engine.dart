import '../models/board.dart';
import '../models/position.dart';
import 'match_detector.dart';

/// Pure Dart hint engine that identifies the most advantageous move for the player,
/// prioritizing special piece combos and higher-order match creations.
class HintEngine {
  final MatchDetector matchDetector;

  const HintEngine([this.matchDetector = const MatchDetector()]);

  /// Finds the highest-value valid move available on [board].
  ///
  /// Returns a tuple `(from, to)` representing the recommended swap,
  /// or `null` if no valid moves exist.
  (Position from, Position to)? findBestHint(Board board) {
    final validMoves = matchDetector.findAllValidMoves(board);
    if (validMoves.isEmpty) return null;

    (Position from, Position to)? bestMove;
    var highestScore = -1;

    for (final move in validMoves) {
      final from = move.$1;
      final to = move.$2;

      final pieceA = board.pieceAt(from);
      final pieceB = board.pieceAt(to);

      var score = 0;

      // Special combos receive highest recommendation weight
      if (pieceA != null && pieceB != null) {
        if (pieceA.specialType.isColorBomb && pieceB.specialType.isColorBomb) {
          score = 1500;
        } else if (pieceA.specialType.isColorBomb || pieceB.specialType.isColorBomb) {
          score = 1000;
        } else if (pieceA.specialType.isSpecial && pieceB.specialType.isSpecial) {
          score = 800;
        }
      }

      // If not a pre-existing special combo, evaluate matches formed by the swap
      if (score == 0) {
        final swapped = board.swapPieces(from, to);
        final matches = matchDetector.findAllMatches(swapped);

        for (final match in matches) {
          final special = matchDetector.getSpecialTypeForMatch(match);
          if (special.isColorBomb) {
            score = maxScore(score, 600 + match.length * 10);
          } else if (special.isWrapped) {
            score = maxScore(score, 500 + match.length * 10);
          } else if (special.isStriped) {
            score = maxScore(score, 400 + match.length * 10);
          } else {
            score = maxScore(score, 100 + match.length * 10);
          }
        }
      }

      if (score > highestScore) {
        highestScore = score;
        bestMove = move;
      }
    }

    return bestMove ?? validMoves.first;
  }

  static int maxScore(int a, int b) => a > b ? a : b;
}
