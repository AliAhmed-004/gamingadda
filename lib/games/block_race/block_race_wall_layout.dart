import 'block_race_logic.dart';

enum WallEnd { start, end }

/// Fence lattice point in cell-edge units (0‥boardSize on each axis).
/// Screen position: (col * cellSize, row * cellSize).
class FencePoint {
  const FencePoint(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is FencePoint && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

class WallCorner {
  const WallCorner({
    required this.point,
    required this.horizontal,
    required this.vertical,
    required this.turns,
    required this.owner,
  });

  final FencePoint point;
  final Wall horizontal;
  final Wall vertical;

  /// Quarter-turns applied to a corner sprite whose arms leave east + south.
  final int turns;
  final BlockRacePlayer owner;
}

/// Computes wall joints for rendering:
/// - free ends → end-tower caps
/// - H+V meetings → corner hub pillars (straights tuck under the hub)
class WallLayout {
  WallLayout(this.walls, this.owners);

  final List<Wall> walls;
  final Map<Wall, BlockRacePlayer> owners;

  /// Horizontal wall (r,c) sits on row r+1, from col c → c+2.
  static FencePoint hStart(Wall w) => FencePoint(w.row + 1, w.col);
  static FencePoint hEnd(Wall w) => FencePoint(w.row + 1, w.col + 2);

  /// Vertical wall (r,c) sits on col c+1, from row r → r+2.
  static FencePoint vStart(Wall w) => FencePoint(w.row, w.col + 1);
  static FencePoint vEnd(Wall w) => FencePoint(w.row + 2, w.col + 1);

  static FencePoint endPoint(Wall w, WallEnd end) {
    if (w.orientation == WallOrientation.horizontal) {
      return end == WallEnd.start ? hStart(w) : hEnd(w);
    }
    return end == WallEnd.start ? vStart(w) : vEnd(w);
  }

  Set<WallEnd> connectedEnds(Wall wall) {
    final result = <WallEnd>{};
    if (wall.orientation == WallOrientation.horizontal) {
      final s = hStart(wall);
      final e = hEnd(wall);
      for (final other in walls) {
        if (other.orientation != WallOrientation.vertical) continue;
        // Skip geometric cross at shared origin (illegal anyway).
        if (other.row == wall.row && other.col == wall.col) continue;
        final vs = vStart(other);
        final ve = vEnd(other);
        if (vs == s || ve == s) result.add(WallEnd.start);
        if (vs == e || ve == e) result.add(WallEnd.end);
      }
    } else {
      final s = vStart(wall);
      final e = vEnd(wall);
      for (final other in walls) {
        if (other.orientation != WallOrientation.horizontal) continue;
        if (other.row == wall.row && other.col == wall.col) continue;
        final hs = hStart(other);
        final he = hEnd(other);
        if (hs == s || he == s) result.add(WallEnd.start);
        if (hs == e || he == e) result.add(WallEnd.end);
      }
    }
    return result;
  }

  List<WallCorner> corners() {
    final byPoint = <FencePoint, WallCorner>{};
    final hs = walls.where((w) => w.orientation == WallOrientation.horizontal);
    final vs = walls.where((w) => w.orientation == WallOrientation.vertical);

    for (final h in hs) {
      for (final v in vs) {
        if (h.row == v.row && h.col == v.col) continue;

        for (final isHStart in [true, false]) {
          final hPoint = isHStart ? hStart(h) : hEnd(h);
          for (final isVStart in [true, false]) {
            final vPoint = isVStart ? vStart(v) : vEnd(v);
            if (hPoint != vPoint) continue;

            // Arms leaving the hub along each wall:
            final goEast = isHStart; // H continues toward +col
            final goWest = !isHStart;
            final goSouth = isVStart; // V continues toward +row
            final goNorth = !isVStart;

            final int turns;
            if (goEast && goSouth) {
              turns = 0;
            } else if (goWest && goSouth) {
              turns = 1;
            } else if (goWest && goNorth) {
              turns = 2;
            } else if (goEast && goNorth) {
              turns = 3;
            } else {
              continue;
            }

            final owner = owners[h] ?? owners[v] ?? BlockRacePlayer.red;
            byPoint.putIfAbsent(
              hPoint,
              () => WallCorner(
                point: hPoint,
                horizontal: h,
                vertical: v,
                turns: turns,
                owner: owner,
              ),
            );
          }
        }
      }
    }
    return byPoint.values.toList();
  }
}
