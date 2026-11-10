import 'package:match3_game/core/constants/app_constants.dart';
import 'package:match3_game/core/constants/game_config.dart';
import 'package:match3_game/features/game/domain/models/board.dart';
import 'package:match3_game/features/game/domain/models/cell.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/game/domain/models/game_state.dart';
import 'package:match3_game/features/game/domain/models/level_config.dart';
import 'package:match3_game/features/game/domain/models/piece.dart';
import 'package:match3_game/features/game/domain/models/position.dart';
import 'package:match3_game/features/levels/data/level_definitions.dart';
import 'package:match3_game/services/storage/storage_service.dart';
import '../domain/repositories/game_repository.dart';

// Production implementation of [GameRepository] that serializes board states,
// player currency, and booster stockpiles to [StorageService].
class GameRepositoryImpl implements GameRepository {
  static const String _gameStatePrefix = 'saved_game_state_level_';

  final StorageService _storage;
  final List<LevelConfig> _levels;

  GameRepositoryImpl(
    this._storage, {
    List<LevelConfig>? levels,
  }) : _levels = levels ?? kLevelDefinitions;

  @override
  Future<void> saveGameState(int levelId, GameState state) async {
    final key = '$_gameStatePrefix$levelId';
    final json = {
      'levelId': levelId,
      'score': state.score,
      'movesLeft': state.movesLeft,
      'timeLeft': state.timeLeft,
      'status': state.status.name,
      'goalProgress': state.goalProgress,
      'comboMultiplier': state.comboMultiplier,
      'boosterInventory': state.boosterInventory.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'board': {
        'rows': state.board.rows,
        'cols': state.board.cols,
        'cells': state.board.cells
            .map((row) => row.map(_cellToJson).toList())
            .toList(),
      },
    };

    await _storage.setJson(key, json);
  }

  @override
  Future<GameState?> loadGameState(int levelId) async {
    final key = '$_gameStatePrefix$levelId';
    final json = await _storage.getJson(key);
    if (json == null) return null;

    try {
      final levelConfig = _levels.firstWhere(
        (l) => l.id == levelId,
        orElse: () => throw ArgumentError('Level $levelId not found'),
      );

      final score = json['score'] as int? ?? 0;
      final movesLeft = json['movesLeft'] as int? ?? levelConfig.maxMoves;
      final timeLeft = json['timeLeft'] as int?;
      final statusName = json['status'] as String? ?? GameStatus.playing.name;
      final status = GameStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => GameStatus.playing,
      );

      final rawGoals = json['goalProgress'] as Map<String, dynamic>? ?? {};
      final goalProgress = rawGoals.map(
        (key, value) => MapEntry(key, value as int),
      );

      final comboMultiplier =
          (json['comboMultiplier'] as num?)?.toDouble() ?? 1.0;

      final rawBoosters =
          json['boosterInventory'] as Map<String, dynamic>? ?? {};
      final boosterInventory = <BoosterType, int>{};
      for (final entry in rawBoosters.entries) {
        final bType = BoosterType.values.firstWhere(
          (b) => b.name == entry.key,
          orElse: () => BoosterType.hammer,
        );
        boosterInventory[bType] = entry.value as int;
      }

      final boardJson = json['board'] as Map<String, dynamic>;
      final rows = boardJson['rows'] as int;
      final cols = boardJson['cols'] as int;
      final cellsRaw = boardJson['cells'] as List<dynamic>;

      final grid = <List<CellState>>[];
      for (final rowItem in cellsRaw) {
        final rowList = (rowItem as List<dynamic>)
            .map((c) => _cellFromJson(c as Map<String, dynamic>))
            .toList();
        grid.add(rowList);
      }

      final board = Board(rows: rows, cols: cols, cells: grid);

      return GameState(
        board: board,
        levelConfig: levelConfig,
        score: score,
        movesLeft: movesLeft,
        timeLeft: timeLeft,
        status: status,
        goalProgress: goalProgress,
        comboMultiplier: comboMultiplier,
        boosterInventory: boosterInventory,
      );
    } catch (_) {
      // If persisted session is corrupted or invalid, clear and return null
      await clearGameState(levelId);
      return null;
    }
  }

  @override
  Future<void> clearGameState(int levelId) async {
    final key = '$_gameStatePrefix$levelId';
    await _storage.remove(key);
  }

  @override
  Future<Map<BoosterType, int>> getBoosterInventory() async {
    final json = await _storage.getJson(AppConstants.keyBoosterInventory);
    if (json == null || json.isEmpty) {
      final initial = {
        BoosterType.hammer: GameConfig.initialHammerBoosters,
        BoosterType.shuffle: GameConfig.initialShuffleBoosters,
        BoosterType.plusFiveMoves: GameConfig.initialPlusFiveMovesBoosters,
        BoosterType.colorSwap: GameConfig.initialColorSwapBoosters,
      };
      await saveBoosterInventory(initial);
      return initial;
    }

    final inventory = <BoosterType, int>{};
    for (final bType in BoosterType.values) {
      final count = json[bType.name] as int? ?? 0;
      inventory[bType] = count < 99 ? 99 : count;
    }
    return inventory;
  }

  @override
  Future<void> saveBoosterInventory(Map<BoosterType, int> inventory) async {
    final json = inventory.map((key, value) => MapEntry(key.name, value));
    await _storage.setJson(AppConstants.keyBoosterInventory, json);
  }

  @override
  Future<void> useBooster(BoosterType type) async {
    final inventory = await getBoosterInventory();
    final current = inventory[type] ?? 99;
    inventory[type] = current > 1 ? current - 1 : 99;
    await saveBoosterInventory(inventory);
  }

  @override
  Future<int> getCoins() async {
    final stored = await _storage.getInt(AppConstants.keyCoinBalance);
    if (stored == null || stored < 99999) {
      await _storage.setInt(AppConstants.keyCoinBalance, 99999);
      return 99999;
    }
    return stored;
  }

  @override
  Future<void> addCoins(int amount) async {
    if (amount < 0) {
      throw ArgumentError('Coin increment amount must be non-negative');
    }
    final current = await getCoins();
    await _storage.setInt(AppConstants.keyCoinBalance, current + amount);
  }

  @override
  Future<void> spendCoins(int amount) async {
    if (amount < 0) {
      throw ArgumentError('Coin spend amount must be non-negative');
    }
    final current = await getCoins();
    if (current < amount) {
      throw StateError(
        'Insufficient coins: required $amount but player only has $current',
      );
    }
    await _storage.setInt(AppConstants.keyCoinBalance, current - amount);
  }

  // ---------------------------------------------------------------------------
  // Serialization Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _cellToJson(CellState cell) {
    final contentJson = switch (cell.content) {
      EmptyCell() => {'type': 'empty'},
      BlockedCell() => {'type': 'blocked'},
      ObstacleCell(:final type, :final hp) => {
          'type': 'obstacle',
          'obstacleType': type.name,
          'hp': hp,
        },
      NormalCell(:final piece) => {
          'type': 'normal',
          'piece': {
            'id': piece.id,
            'pieceType': piece.pieceType.name,
            'specialType': switch (piece.specialType) {
              NoneSpecial() => 'none',
              StripedHSpecial() => 'stripedH',
              StripedVSpecial() => 'stripedV',
              WrappedSpecial() => 'wrapped',
              ColorBombSpecial() => 'colorBomb',
            },
          },
        },
    };

    return {
      'row': cell.position.row,
      'col': cell.position.col,
      'jellyLayers': cell.jellyLayers,
      'hasIce': cell.hasIce,
      'hasCrate': cell.hasCrate,
      'isLocked': cell.isLocked,
      'content': contentJson,
    };
  }

  CellState _cellFromJson(Map<String, dynamic> json) {
    final row = json['row'] as int;
    final col = json['col'] as int;
    final jellyLayers = json['jellyLayers'] as int? ?? 0;
    final hasIce = json['hasIce'] as bool? ?? false;
    final hasCrate = json['hasCrate'] as bool? ?? false;
    final isLocked = json['isLocked'] as bool? ?? false;

    final contentMap = json['content'] as Map<String, dynamic>;
    final contentType = contentMap['type'] as String;

    final CellContent content;
    switch (contentType) {
      case 'empty':
        content = const EmptyCell();
      case 'blocked':
        content = const BlockedCell();
      case 'obstacle':
        final obsTypeName =
            contentMap['obstacleType'] as String? ?? ObstacleType.crate.name;
        final obsType = ObstacleType.values.firstWhere(
          (o) => o.name == obsTypeName,
          orElse: () => ObstacleType.crate,
        );
        final hp = contentMap['hp'] as int? ?? 1;
        content = ObstacleCell(type: obsType, hp: hp);
      case 'normal':
      default:
        final pMap = contentMap['piece'] as Map<String, dynamic>;
        final pId = pMap['id'] as String;
        final pTypeName = pMap['pieceType'] as String;
        final pType = PieceType.values.firstWhere(
          (pt) => pt.name == pTypeName,
          orElse: () => PieceType.red,
        );
        final sTypeName = pMap['specialType'] as String? ?? 'none';
        final SpecialType sType = switch (sTypeName) {
          'stripedH' => SpecialType.stripedH,
          'stripedV' => SpecialType.stripedV,
          'wrapped' => SpecialType.wrapped,
          'colorBomb' => SpecialType.colorBomb,
          _ => SpecialType.none,
        };
        content =
            NormalCell(Piece(id: pId, pieceType: pType, specialType: sType));
    }

    return CellState(
      position: Position(row, col),
      content: content,
      jellyLayers: jellyLayers,
      hasIce: hasIce,
      hasCrate: hasCrate,
      isLocked: isLocked,
    );
  }
}
