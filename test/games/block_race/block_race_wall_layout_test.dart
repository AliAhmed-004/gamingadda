import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/block_race/block_race_logic.dart';
import 'package:gaming_adda/games/block_race/block_race_wall_layout.dart';

void main() {
  group('WallLayout', () {
    test('isolated wall has both ends free', () {
      final h = Wall(row: 3, col: 2, orientation: WallOrientation.horizontal);
      final layout = WallLayout([h], {h: BlockRacePlayer.red});
      expect(layout.connectedEnds(h), isEmpty);
      expect(layout.corners(), isEmpty);
    });

    test('H east meeting V north forms one corner', () {
      // H(3,2) east at (row:4, col:4); V(4,3) north at (row:4, col:4)
      final h = Wall(row: 3, col: 2, orientation: WallOrientation.horizontal);
      final v = Wall(row: 4, col: 3, orientation: WallOrientation.vertical);
      final layout = WallLayout(
        [h, v],
        {h: BlockRacePlayer.red, v: BlockRacePlayer.blue},
      );

      expect(layout.connectedEnds(h), contains(WallEnd.end));
      expect(layout.connectedEnds(h), isNot(contains(WallEnd.start)));
      expect(layout.connectedEnds(v), contains(WallEnd.start));
      expect(layout.corners(), hasLength(1));
      expect(layout.corners().single.point, const FencePoint(4, 4));
    });

    test('H west meeting V south forms a corner', () {
      // H(3,2) west (4,2); V(2,1) south (4,2)
      final h = Wall(row: 3, col: 2, orientation: WallOrientation.horizontal);
      final v = Wall(row: 2, col: 1, orientation: WallOrientation.vertical);
      final layout = WallLayout([h, v], {});
      expect(layout.corners(), hasLength(1));
      expect(layout.connectedEnds(h), contains(WallEnd.start));
      expect(layout.connectedEnds(v), contains(WallEnd.end));
    });

    test('crossing same-origin walls are ignored', () {
      final h = Wall(row: 3, col: 2, orientation: WallOrientation.horizontal);
      final v = Wall(row: 3, col: 2, orientation: WallOrientation.vertical);
      final layout = WallLayout([h, v], {});
      expect(layout.corners(), isEmpty);
      expect(layout.connectedEnds(h), isEmpty);
    });
  });
}
