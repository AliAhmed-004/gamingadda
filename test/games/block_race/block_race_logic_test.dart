import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/block_race/block_race_ai.dart';
import 'package:gaming_adda/games/block_race/block_race_config.dart';
import 'package:gaming_adda/games/block_race/block_race_logic.dart';

void main() {
  group('BlockRaceGame setup', () {
    test('players start on opposite sides of a 9x9 board', () {
      final game = BlockRaceGame()..startGame();
      expect(BlockRaceGame.boardSize, 9);
      expect(game.redPos, BlockRaceGame.redStart);
      expect(game.bluePos, BlockRaceGame.blueStart);
      expect(game.redPos.row, 8);
      expect(game.bluePos.row, 0);
      expect(game.currentPlayer, BlockRacePlayer.red);
      expect(game.redWallsLeft, 10);
      expect(game.blueWallsLeft, 10);
    });
  });

  group('BlockRaceGame movement', () {
    test('orthogonal step is legal', () {
      final game = BlockRaceGame()..startGame();
      final moves = game.legalMoves();
      expect(moves, contains(const BoardPos(7, 4)));
      expect(moves, contains(const BoardPos(8, 3)));
      expect(moves, contains(const BoardPos(8, 5)));
      expect(moves, isNot(contains(const BoardPos(8, 4))));
    });

    test('applyMove advances piece and ends turn animation', () {
      final game = BlockRaceGame()..startGame();
      final result = game.applyMove(const BoardPos(7, 4));
      expect(result, isNotNull);
      expect(game.redPos, const BoardPos(7, 4));
      expect(game.phase, BlockRacePhase.animating);
      game.finishAnimations();
      expect(game.currentPlayer, BlockRacePlayer.blue);
      expect(game.phase, BlockRacePhase.choosing);
    });

    test('reaching goal ends the game', () {
      final game = BlockRaceGame()..startGame();
      game.redPos = const BoardPos(1, 4);
      game.bluePos = const BoardPos(0, 0); // clear the goal cell
      final result = game.applyMove(const BoardPos(0, 4));
      expect(result, isNotNull);
      expect(result!.won, isTrue);
      expect(game.winner, BlockRacePlayer.red);
      expect(game.phase, BlockRacePhase.gameOver);
    });

    test('jump over adjacent opponent when beyond is free', () {
      final game = BlockRaceGame()..startGame();
      game.redPos = const BoardPos(4, 4);
      game.bluePos = const BoardPos(3, 4);
      final moves = game.legalMoves();
      expect(moves, contains(const BoardPos(2, 4)));
      expect(moves, isNot(contains(const BoardPos(3, 4))));
    });

    test('sideways jump when straight jump is blocked', () {
      final game = BlockRaceGame()..startGame();
      game.redPos = const BoardPos(4, 4);
      game.bluePos = const BoardPos(3, 4);
      // Wall behind blue blocks the straight jump to (2,4).
      game.walls.add(
        const Wall(row: 2, col: 4, orientation: WallOrientation.horizontal),
      );
      final moves = game.legalMoves();
      expect(moves, isNot(contains(const BoardPos(2, 4))));
      expect(moves, contains(const BoardPos(3, 3)));
      expect(moves, contains(const BoardPos(3, 5)));
    });

    test('cannot walk through a wall', () {
      final game = BlockRaceGame()..startGame();
      game.walls.add(
        const Wall(row: 7, col: 4, orientation: WallOrientation.horizontal),
      );
      final moves = game.legalMoves();
      expect(moves, isNot(contains(const BoardPos(7, 4))));
      expect(moves, contains(const BoardPos(8, 3)));
      expect(moves, contains(const BoardPos(8, 5)));
    });
  });

  group('BlockRaceGame walls', () {
    test('horizontal wall blocks vertical passage', () {
      final game = BlockRaceGame()..startGame();
      game.actionMode = BlockRaceActionMode.wall;
      final wall = const Wall(
        row: 7,
        col: 3,
        orientation: WallOrientation.horizontal,
      );
      expect(game.placeWall(wall), isTrue);
      expect(game.isEdgeBlocked(const BoardPos(7, 4), const BoardPos(8, 4)), isTrue);
      expect(game.isEdgeBlocked(const BoardPos(7, 3), const BoardPos(8, 3)), isTrue);
    });

    test('wall that seals a player is illegal', () {
      final game = BlockRaceGame()..startGame();
      // Trap red at start: block north, east, and west (south is the board edge).
      game.walls.addAll(const [
        Wall(row: 7, col: 3, orientation: WallOrientation.horizontal),
        Wall(row: 7, col: 3, orientation: WallOrientation.vertical),
        Wall(row: 7, col: 4, orientation: WallOrientation.vertical),
      ]);
      expect(game.hasPathToGoal(BlockRacePlayer.red), isFalse);
      expect(game.hasPathToGoal(BlockRacePlayer.blue), isTrue);

      game.walls.clear();
      game.actionMode = BlockRaceActionMode.wall;
      expect(
        game.canPlaceWall(
          const Wall(row: 3, col: 3, orientation: WallOrientation.vertical),
        ),
        isTrue,
      );

      // Completing a near-seal must be rejected by canPlaceWall.
      game.walls.addAll(const [
        Wall(row: 7, col: 3, orientation: WallOrientation.horizontal),
        Wall(row: 7, col: 3, orientation: WallOrientation.vertical),
      ]);
      expect(
        game.canPlaceWall(
          const Wall(row: 7, col: 4, orientation: WallOrientation.vertical),
        ),
        isFalse,
      );
    });

    test('overlapping walls conflict', () {
      final game = BlockRaceGame()..startGame();
      game.walls.add(
        const Wall(row: 3, col: 3, orientation: WallOrientation.horizontal),
      );
      expect(
        game.wallConflicts(
          const Wall(row: 3, col: 4, orientation: WallOrientation.horizontal),
        ),
        isTrue,
      );
      expect(
        game.wallConflicts(
          const Wall(row: 3, col: 3, orientation: WallOrientation.vertical),
        ),
        isTrue,
      );
    });

    test('placing wall consumes stock', () {
      final game = BlockRaceGame()..startGame();
      game.actionMode = BlockRaceActionMode.wall;
      expect(
        game.placeWall(
          const Wall(row: 2, col: 2, orientation: WallOrientation.vertical),
        ),
        isTrue,
      );
      expect(game.redWallsLeft, 9);
    });
  });

  group('pathfinding', () {
    test('open board has path for both', () {
      final game = BlockRaceGame()..startGame();
      expect(game.hasPathToGoal(BlockRacePlayer.red), isTrue);
      expect(game.hasPathToGoal(BlockRacePlayer.blue), isTrue);
      expect(game.pathLengthToGoal(BlockRacePlayer.red), 8);
      expect(game.pathLengthToGoal(BlockRacePlayer.blue), 8);
    });
  });

  group('full game simulation', () {
    test('two AIs always finish a legal game', () {
      final rng = Random(42);
      for (var run = 0; run < 3; run++) {
        final game = BlockRaceGame()..startGame();
        final redAi = BlockRaceAi(
          difficulty: BlockRaceAiDifficulty.medium,
          random: Random(rng.nextInt(1 << 30)),
          player: BlockRacePlayer.red,
        );
        final blueAi = BlockRaceAi(
          difficulty: BlockRaceAiDifficulty.medium,
          random: Random(rng.nextInt(1 << 30)),
          player: BlockRacePlayer.blue,
        );

        var turns = 0;
        while (game.phase != BlockRacePhase.gameOver && turns < 400) {
          final ai =
              game.currentPlayer == BlockRacePlayer.red ? redAi : blueAi;
          final choice = ai.choose(game);
          var acted = false;
          if (choice.isMove) {
            acted = game.applyMove(choice.move!) != null;
          } else if (choice.isWall) {
            acted = game.placeWall(choice.wall!);
          }
          if (!acted) {
            final moves = game.legalMoves();
            expect(moves, isNotEmpty,
                reason: 'a player must always have a legal move');
            expect(game.applyMove(moves.first), isNotNull);
          }
          game.finishAnimations();
          turns++;
        }

        expect(game.phase, BlockRacePhase.gameOver,
            reason: 'game should finish within 400 turns');
        expect(game.winner, isNotNull);
        expect(game.hasReachedGoal(game.winner!), isTrue);
      }
    });
  });
}
