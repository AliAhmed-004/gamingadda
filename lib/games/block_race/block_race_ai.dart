import 'dart:math';

import 'block_race_config.dart';
import 'block_race_logic.dart';

/// Basic AI for the computer player (Blue). Prefers advancing when ahead;
/// otherwise places a wall that most increases Red's path length.
class BlockRaceAi {
  BlockRaceAi({
    this._difficulty = BlockRaceAiDifficulty.medium,
    Random? random,
    this.player = BlockRacePlayer.blue,
  }) : _random = random ?? Random();

  final BlockRaceAiDifficulty _difficulty;
  final Random _random;
  final BlockRacePlayer player;

  BlockRacePlayer get _opponent => player == BlockRacePlayer.blue
      ? BlockRacePlayer.red
      : BlockRacePlayer.blue;

  BlockRaceAiChoice choose(BlockRaceGame game) {
    if (!_shouldPlayOptimally()) {
      return _randomChoice(game);
    }

    final myPath = game.pathLengthToGoal(player) ?? 99;
    final foePath = game.pathLengthToGoal(_opponent) ?? 99;

    final shouldWall =
        game.wallsLeftFor(player) > 0 &&
        (foePath <= myPath + 1 || foePath <= 4) &&
        _shouldConsiderWall();

    if (shouldWall) {
      final wall = _bestWall(game);
      if (wall != null) return BlockRaceAiChoice.wall(wall);
    }

    final move = _bestMove(game);
    if (move != null) return BlockRaceAiChoice.move(move);

    final wall = _bestWall(game);
    if (wall != null) return BlockRaceAiChoice.wall(wall);

    return _randomChoice(game);
  }

  BlockRaceAiChoice _randomChoice(BlockRaceGame game) {
    final moves = game.legalMoves();
    final walls = game.wallsLeftFor(player) > 0
        ? game.allValidWalls()
        : const <Wall>[];

    if (moves.isNotEmpty && (walls.isEmpty || _random.nextBool())) {
      return BlockRaceAiChoice.move(moves[_random.nextInt(moves.length)]);
    }
    if (walls.isNotEmpty) {
      return BlockRaceAiChoice.wall(walls[_random.nextInt(walls.length)]);
    }
    if (moves.isNotEmpty) {
      return BlockRaceAiChoice.move(moves.first);
    }
    return BlockRaceAiChoice.move(game.positionOf(player));
  }

  BoardPos? _bestMove(BlockRaceGame game) {
    final moves = game.legalMoves();
    if (moves.isEmpty) return null;

    BoardPos? best;
    var bestScore = 1 << 30;
    for (final m in moves) {
      final saved = game.positionOf(player);
      _setPos(game, m);
      final len = game.pathLengthToGoal(player) ?? 99;
      _setPos(game, saved);
      final score = len * 10 + _manhattanToGoal(m);
      if (score < bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  void _setPos(BlockRaceGame game, BoardPos pos) {
    if (player == BlockRacePlayer.blue) {
      game.bluePos = pos;
    } else {
      game.redPos = pos;
    }
  }

  Wall? _bestWall(BlockRaceGame game) {
    if (game.wallsLeftFor(player) <= 0) return null;

    final candidates = game.allValidWalls();
    if (candidates.isEmpty) return null;

    final sampleSize = switch (_difficulty) {
      BlockRaceAiDifficulty.easy => min(12, candidates.length),
      BlockRaceAiDifficulty.medium => min(40, candidates.length),
      BlockRaceAiDifficulty.hard => candidates.length,
    };

    final pool = List<Wall>.from(candidates)..shuffle(_random);
    final sample = pool.take(sampleSize);

    final baseFoe = game.pathLengthToGoal(_opponent) ?? 0;
    final baseMe = game.pathLengthToGoal(player) ?? 0;

    Wall? best;
    var bestGain = -999;

    for (final wall in sample) {
      game.walls.add(wall);
      final foe = game.pathLengthToGoal(_opponent) ?? 99;
      final me = game.pathLengthToGoal(player) ?? 99;
      game.walls.removeLast();

      final gain = (foe - baseFoe) * 3 - (me - baseMe);
      if (gain > bestGain) {
        bestGain = gain;
        best = wall;
      }
    }

    if (bestGain <= 0 && _difficulty != BlockRaceAiDifficulty.hard) {
      return null;
    }
    return best;
  }

  int _manhattanToGoal(BoardPos pos) {
    final goalRow = player == BlockRacePlayer.blue
        ? BlockRaceGame.boardSize - 1
        : 0;
    return (pos.row - goalRow).abs();
  }

  bool _shouldPlayOptimally() {
    return switch (_difficulty) {
      BlockRaceAiDifficulty.easy => _random.nextDouble() > 0.4,
      BlockRaceAiDifficulty.medium => _random.nextDouble() > 0.18,
      BlockRaceAiDifficulty.hard => true,
    };
  }

  bool _shouldConsiderWall() {
    return switch (_difficulty) {
      BlockRaceAiDifficulty.easy => _random.nextDouble() > 0.55,
      BlockRaceAiDifficulty.medium => _random.nextDouble() > 0.3,
      BlockRaceAiDifficulty.hard => true,
    };
  }
}

class BlockRaceAiChoice {
  const BlockRaceAiChoice._({this.move, this.wall});

  factory BlockRaceAiChoice.move(BoardPos pos) =>
      BlockRaceAiChoice._(move: pos);

  factory BlockRaceAiChoice.wall(Wall wall) => BlockRaceAiChoice._(wall: wall);

  final BoardPos? move;
  final Wall? wall;

  bool get isMove => move != null;
  bool get isWall => wall != null;
}
