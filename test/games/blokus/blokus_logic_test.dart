import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/blokus/blokus_ai.dart';
import 'package:gaming_adda/games/blokus/blokus_logic.dart';
import 'package:gaming_adda/games/blokus/blokus_pieces.dart';

void main() {
  group('BlokusPieces', () {
    test('21 pieces totaling 89 squares', () {
      expect(BlokusPieces.all.length, 21);
      expect(BlokusPieces.totalSquares, 89);
      expect(BlokusPieces.ids.length, 21);
    });

    test('orientations are normalized and unique', () {
      final o4 = uniqueOrientations(BlokusPieces.byId('o4'));
      expect(o4.length, 1);
      final i5 = uniqueOrientations(BlokusPieces.byId('i5'));
      expect(i5.length, 2); // horizontal + vertical
      final x = uniqueOrientations(BlokusPieces.byId('x'));
      expect(x.length, 1);
      for (final orient in i5) {
        expect(orient.first, const BlokusCell(0, 0));
        expect(cellsKey(orient), cellsKey(normalizeCells(orient)));
      }
    });
  });

  group('seats', () {
    test('player counts map to active colors', () {
      expect(activeColorsForPlayerCount(4).length, 4);
      expect(activeColorsForPlayerCount(3), [
        BlokusColor.blue,
        BlokusColor.yellow,
        BlokusColor.red,
      ]);
      expect(activeColorsForPlayerCount(2).length, 4);
    });

    test('2p dual-color ownership is diagonal', () {
      expect(
        colorsOwnedBySeat(BlokusColor.blue, 2),
        {BlokusColor.blue, BlokusColor.red},
      );
      expect(
        colorsOwnedBySeat(BlokusColor.yellow, 2),
        {BlokusColor.yellow, BlokusColor.green},
      );
      expect(colorsOwnedBySeat(BlokusColor.blue, 4), {BlokusColor.blue});
    });
  });

  group('BlokusGame placement', () {
    test('first move must cover corner', () {
      final game = BlokusGame();
      expect(game.turn, BlokusColor.blue);
      final bad = game.placementAtAnchor(
        color: BlokusColor.blue,
        pieceId: '1',
        orientationIndex: 0,
        anchor: const BlokusCell(5, 5),
      )!;
      expect(game.canPlace(bad), isFalse);

      final good = game.placementAtAnchor(
        color: BlokusColor.blue,
        pieceId: '1',
        orientationIndex: 0,
        anchor: const BlokusCell(0, 0),
      )!;
      expect(game.canPlace(good), isTrue);
      expect(game.place(good), isTrue);
      expect(game.scores[BlokusColor.blue], 1);
      expect(game.turn, BlokusColor.yellow);
    });

    test('second piece must corner-touch and not edge-touch', () {
      final game = BlokusGame();
      expect(
        game.place(
          game.placementAtAnchor(
            color: BlokusColor.blue,
            pieceId: '1',
            orientationIndex: 0,
            anchor: const BlokusCell(0, 0),
          )!,
        ),
        isTrue,
      );
      // Skip other colors' first moves by placing monominoes.
      for (final color in [
        BlokusColor.yellow,
        BlokusColor.red,
        BlokusColor.green,
      ]) {
        final corner = cornerFor(color);
        expect(
          game.place(
            game.placementAtAnchor(
              color: color,
              pieceId: '1',
              orientationIndex: 0,
              anchor: corner,
            )!,
          ),
          isTrue,
        );
      }
      expect(game.turn, BlokusColor.blue);

      // Edge-adjacent to (0,0) at (0,1) — illegal.
      final edge = game.placementAtAnchor(
        color: BlokusColor.blue,
        pieceId: '2',
        orientationIndex: 0,
        anchor: const BlokusCell(0, 1),
      )!;
      expect(game.isLegalPlacement(edge), isFalse);

      // Corner at (1,1) — legal for monomino... use piece '2' covering (1,1).
      final cornerTouch = game.placementAtAnchor(
        color: BlokusColor.blue,
        pieceId: '2',
        orientationIndex: 0,
        anchor: const BlokusCell(1, 1),
      )!;
      // '2' horizontal from (1,1) covers (1,1)(1,2) — corner touches (0,0).
      expect(game.isLegalPlacement(cornerTouch), isTrue);
      expect(game.place(cornerTouch), isTrue);
      expect(game.scores[BlokusColor.blue], 3);
    });

    test('overlap and OOB rejected', () {
      final game = BlokusGame();
      game.place(
        game.placementAtAnchor(
          color: BlokusColor.blue,
          pieceId: '1',
          orientationIndex: 0,
          anchor: const BlokusCell(0, 0),
        )!,
      );
      final overlap = BlokusPlacement(
        color: BlokusColor.blue,
        pieceId: '2',
        orientationIndex: 0,
        origin: const BlokusCell(0, 0),
        cells: const [BlokusCell(0, 0), BlokusCell(0, 1)],
      );
      expect(game.isLegalPlacement(overlap), isFalse);

      final oob = BlokusPlacement(
        color: BlokusColor.blue,
        pieceId: 'i5',
        orientationIndex: 0,
        origin: const BlokusCell(0, 18),
        cells: const [
          BlokusCell(0, 18),
          BlokusCell(0, 19),
          BlokusCell(0, 20),
          BlokusCell(0, 21),
          BlokusCell(0, 22),
        ],
      );
      expect(game.isLegalPlacement(oob), isFalse);
    });

    test('pass and all-passed ends game', () {
      final game = BlokusGame(playerCount: 3);
      expect(game.activeColors.length, 3);
      expect(game.pass(), isTrue);
      expect(game.passed.contains(BlokusColor.blue), isTrue);
      expect(game.turn, BlokusColor.yellow);
      expect(game.pass(), isTrue);
      expect(game.pass(), isTrue);
      expect(game.gameOver, isTrue);
    });

    test('score tracks placed cells', () {
      final game = BlokusGame();
      final p = game.legalPlacements(BlokusColor.blue, 'v5').first;
      expect(game.place(p), isTrue);
      expect(game.scores[BlokusColor.blue], 5);
      expect(game.remaining[BlokusColor.blue]!.contains('v5'), isFalse);
    });

    test('findAnyLegalPlacement finds opening move', () {
      final game = BlokusGame();
      final p = game.findAnyLegalPlacement(BlokusColor.blue);
      expect(p, isNotNull);
      expect(p!.cells.any((c) => c == const BlokusCell(0, 0)), isTrue);
    });
  });

  group('BlokusAi', () {
    test('chooses a legal opening placement', () {
      final game = BlokusGame();
      final ai = BlokusAi(random: Random(1));
      final move = ai.choosePlacement(game);
      expect(move, isNotNull);
      expect(game.canPlace(move!), isTrue);
      expect(game.place(move), isTrue);
    });
  });
}
