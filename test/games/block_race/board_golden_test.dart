import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/block_race/block_race_board.dart';
import 'package:gaming_adda/games/block_race/block_race_logic.dart';

void main() {
  testWidgets('board renders mid-game wall layout', (tester) async {
    final game = BlockRaceGame()..startGame();
    final owners = <Wall, BlockRacePlayer>{};

    void place(int row, int col, WallOrientation o, BlockRacePlayer owner) {
      final wall = Wall(row: row, col: col, orientation: o);
      game.currentPlayer = owner;
      expect(game.placeWall(wall), isTrue, reason: 'wall $row,$col,$o');
      owners[wall] = owner;
      game.phase = BlockRacePhase.choosing;
    }

    // Roughly the layout from the screenshot: blue walls hugging the top,
    // a vertical red wall mid-board, red walls mid, blue near the bottom.
    place(0, 3, WallOrientation.horizontal, BlockRacePlayer.blue);
    place(0, 6, WallOrientation.horizontal, BlockRacePlayer.blue);
    place(1, 3, WallOrientation.vertical, BlockRacePlayer.red);
    place(3, 3, WallOrientation.vertical, BlockRacePlayer.red);
    place(4, 3, WallOrientation.horizontal, BlockRacePlayer.red);
    place(7, 4, WallOrientation.horizontal, BlockRacePlayer.blue);

    game.redPos = const BoardPos(6, 4);
    game.bluePos = const BoardPos(0, 4);
    game.currentPlayer = BlockRacePlayer.red;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Center(
          child: RepaintBoundary(
            key: const ValueKey('board'),
            child: SizedBox(
              width: 560,
              height: 560,
              child: BlockRaceBoard(
                game: game,
                wallOwners: owners,
                interactive: true,
                wallMode: false,
                onCellTap: (_) {},
                onWallTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    // Let placement animations settle; precache asset images.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(BlockRaceBoard));
          for (final asset in [
            'assets/block_race/board_panel.png',
            'assets/block_race/goti_red.png',
            'assets/block_race/goti_blue.png',
            'assets/block_race/move_target.png',
            'assets/block_race/wall_h_red.png',
            'assets/block_race/wall_h_blue.png',
            'assets/block_race/wall_v_red.png',
            'assets/block_race/wall_v_blue.png',
            'assets/block_race/wall_pillar_red.png',
            'assets/block_race/wall_pillar_blue.png',
          ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byKey(const ValueKey('board')),
      matchesGoldenFile('goldens/board_midgame.png'),
    );
  });
}
