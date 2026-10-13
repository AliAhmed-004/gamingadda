import 'dart:collection';

/// Quoridor-style Barricade Clash core rules.
///
/// Board is 9×9 cells. Walls sit on the 8×8 fence grid and each wall spans
/// two adjacent fences. Players alternate: move one step (or jump) **or**
/// place one wall. First to the opposite side wins. Wall placement must leave
/// both players a path to their goal.

enum BlockRacePlayer { blue, red }

enum BlockRacePhase { ready, choosing, animating, gameOver }

enum BlockRaceActionMode { move, wall }

enum WallOrientation { horizontal, vertical }

class BoardPos {
  const BoardPos(this.row, this.col);

  final int row;
  final int col;

  bool get inBounds =>
      row >= 0 &&
      row < BlockRaceGame.boardSize &&
      col >= 0 &&
      col < BlockRaceGame.boardSize;

  BoardPos operator +(BoardPos o) => BoardPos(row + o.row, col + o.col);

  @override
  bool operator ==(Object other) =>
      other is BoardPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// A wall occupies one slot on the 8×8 fence lattice and blocks two edges.
class Wall {
  const Wall({required this.row, required this.col, required this.orientation});

  /// Top-left fence intersection of the wall (0..7).
  final int row;
  final int col;
  final WallOrientation orientation;

  bool get inBounds =>
      row >= 0 &&
      row < BlockRaceGame.fenceSize &&
      col >= 0 &&
      col < BlockRaceGame.fenceSize;

  @override
  bool operator ==(Object other) =>
      other is Wall &&
      other.row == row &&
      other.col == col &&
      other.orientation == orientation;

  @override
  int get hashCode => Object.hash(row, col, orientation);
}

class BlockRaceMoveResult {
  const BlockRaceMoveResult({
    required this.from,
    required this.to,
    required this.won,
  });

  final BoardPos from;
  final BoardPos to;
  final bool won;
}

class BlockRaceGame {
  BlockRaceGame();

  static const boardSize = 9;
  static const fenceSize = 8;
  static const wallsPerPlayer = 10;

  /// Blue starts at the top edge (row 0), races to bottom (row 8).
  static const blueStart = BoardPos(0, 4);

  /// Red starts at the bottom edge (row 8), races to top (row 0).
  static const redStart = BoardPos(8, 4);

  BlockRacePhase phase = BlockRacePhase.ready;
  BlockRacePlayer currentPlayer = BlockRacePlayer.red;
  BlockRacePlayer? winner;
  BlockRaceActionMode actionMode = BlockRaceActionMode.move;
  WallOrientation wallOrientation = WallOrientation.horizontal;

  BoardPos bluePos = blueStart;
  BoardPos redPos = redStart;

  final List<Wall> walls = [];
  int blueWallsLeft = wallsPerPlayer;
  int redWallsLeft = wallsPerPlayer;
  int moveCount = 0;

  String get statusMessage {
    if (winner != null) return '${_label(winner!)} wins!';
    return switch (phase) {
      BlockRacePhase.ready => 'Get ready…',
      BlockRacePhase.choosing => '${_label(currentPlayer)}\'s turn',
      BlockRacePhase.animating => '…',
      BlockRacePhase.gameOver => '${_label(winner!)} wins!',
    };
  }

  static String _label(BlockRacePlayer p) =>
      p == BlockRacePlayer.blue ? 'Blue' : 'Red';

  BoardPos positionOf(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? bluePos : redPos;

  int wallsLeftFor(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? blueWallsLeft : redWallsLeft;

  int goalRowFor(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? boardSize - 1 : 0;

  bool hasReachedGoal(BlockRacePlayer player) =>
      positionOf(player).row == goalRowFor(player);

  void startGame() {
    bluePos = blueStart;
    redPos = redStart;
    walls.clear();
    blueWallsLeft = wallsPerPlayer;
    redWallsLeft = wallsPerPlayer;
    currentPlayer = BlockRacePlayer.red;
    winner = null;
    moveCount = 0;
    actionMode = BlockRaceActionMode.move;
    wallOrientation = WallOrientation.horizontal;
    phase = BlockRacePhase.choosing;
  }

  void setActionMode(BlockRaceActionMode mode) {
    if (phase != BlockRacePhase.choosing) return;
    if (mode == BlockRaceActionMode.wall && wallsLeftFor(currentPlayer) <= 0) {
      return;
    }
    actionMode = mode;
  }

  void toggleWallOrientation() {
    wallOrientation = wallOrientation == WallOrientation.horizontal
        ? WallOrientation.vertical
        : WallOrientation.horizontal;
  }

  void setWallOrientation(WallOrientation orientation) {
    wallOrientation = orientation;
  }

  /// Whether the edge between [a] and [b] (orthogonal neighbors) is blocked.
  bool isEdgeBlocked(BoardPos a, BoardPos b) {
    final dr = b.row - a.row;
    final dc = b.col - a.col;
    if ((dr.abs() + dc.abs()) != 1) return true;

    if (dr == 1) {
      // Moving down: horizontal fence between a.row and a.row+1 at col a.col
      return _hasHorizontalFence(a.row, a.col);
    }
    if (dr == -1) {
      return _hasHorizontalFence(b.row, a.col);
    }
    if (dc == 1) {
      return _hasVerticalFence(a.row, a.col);
    }
    // dc == -1
    return _hasVerticalFence(a.row, b.col);
  }

  bool _hasHorizontalFence(int fenceRow, int cellCol) {
    if (fenceRow < 0 || fenceRow >= fenceSize) return false;
    for (final w in walls) {
      if (w.orientation != WallOrientation.horizontal) continue;
      if (w.row != fenceRow) continue;
      if (cellCol == w.col || cellCol == w.col + 1) return true;
    }
    return false;
  }

  bool _hasVerticalFence(int cellRow, int fenceCol) {
    if (fenceCol < 0 || fenceCol >= fenceSize) return false;
    for (final w in walls) {
      if (w.orientation != WallOrientation.vertical) continue;
      if (w.col != fenceCol) continue;
      if (cellRow == w.row || cellRow == w.row + 1) return true;
    }
    return false;
  }

  /// True if [candidate] overlaps or crosses any existing wall.
  bool wallConflicts(Wall candidate) {
    if (!candidate.inBounds) return true;
    for (final w in walls) {
      if (w == candidate) return true;
      if (w.orientation == candidate.orientation) {
        if (w.orientation == WallOrientation.horizontal) {
          if (w.row == candidate.row && (w.col - candidate.col).abs() <= 1) {
            return true;
          }
        } else {
          if (w.col == candidate.col && (w.row - candidate.row).abs() <= 1) {
            return true;
          }
        }
      } else {
        // Crossing at the same intersection point.
        if (w.orientation == WallOrientation.horizontal) {
          if (candidate.row == w.row &&
              candidate.col == w.col &&
              candidate.orientation == WallOrientation.vertical) {
            return true;
          }
        } else {
          if (candidate.row == w.row &&
              candidate.col == w.col &&
              candidate.orientation == WallOrientation.horizontal) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool wallLeavesPathsOpen(Wall candidate) {
    walls.add(candidate);
    final ok =
        hasPathToGoal(BlockRacePlayer.blue) &&
        hasPathToGoal(BlockRacePlayer.red);
    walls.removeLast();
    return ok;
  }

  bool canPlaceWall(Wall wall) {
    if (phase != BlockRacePhase.choosing) return false;
    if (wallsLeftFor(currentPlayer) <= 0) return false;
    if (wallConflicts(wall)) return false;
    return wallLeavesPathsOpen(wall);
  }

  /// Validity without requiring it to be the current player's turn to place
  /// (used for ghost preview while choosing).
  bool isWallPlacementLegal(Wall wall) {
    if (wallsLeftFor(currentPlayer) <= 0) return false;
    if (wallConflicts(wall)) return false;
    return wallLeavesPathsOpen(wall);
  }

  List<Wall> allValidWalls() {
    final result = <Wall>[];
    for (var r = 0; r < fenceSize; r++) {
      for (var c = 0; c < fenceSize; c++) {
        for (final o in WallOrientation.values) {
          final wall = Wall(row: r, col: c, orientation: o);
          if (isWallPlacementLegal(wall)) result.add(wall);
        }
      }
    }
    return result;
  }

  bool hasPathToGoal(BlockRacePlayer player) {
    final start = positionOf(player);
    final goalRow = goalRowFor(player);
    final visited = <BoardPos>{};
    final queue = Queue<BoardPos>()..add(start);
    visited.add(start);

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      if (cur.row == goalRow) return true;
      for (final n in _orthogonalNeighbors(cur)) {
        if (visited.contains(n)) continue;
        if (isEdgeBlocked(cur, n)) continue;
        visited.add(n);
        queue.add(n);
      }
    }
    return false;
  }

  /// Shortest-path length to goal, or null if unreachable.
  int? pathLengthToGoal(BlockRacePlayer player) {
    final start = positionOf(player);
    final goalRow = goalRowFor(player);
    final visited = <BoardPos>{start};
    final queue = Queue<(BoardPos, int)>()..add((start, 0));

    while (queue.isNotEmpty) {
      final (cur, dist) = queue.removeFirst();
      if (cur.row == goalRow) return dist;
      for (final n in _orthogonalNeighbors(cur)) {
        if (visited.contains(n)) continue;
        if (isEdgeBlocked(cur, n)) continue;
        visited.add(n);
        queue.add((n, dist + 1));
      }
    }
    return null;
  }

  List<BoardPos> _orthogonalNeighbors(BoardPos p) {
    const deltas = [
      BoardPos(-1, 0),
      BoardPos(1, 0),
      BoardPos(0, -1),
      BoardPos(0, 1),
    ];
    return [
      for (final d in deltas)
        if ((p + d).inBounds) p + d,
    ];
  }

  BoardPos get _opponentPos =>
      currentPlayer == BlockRacePlayer.blue ? redPos : bluePos;

  /// Legal destination cells for the current player (Quoridor moves + jumps).
  List<BoardPos> legalMoves() {
    if (phase != BlockRacePhase.choosing && phase != BlockRacePhase.ready) {
      return const [];
    }
    final from = positionOf(currentPlayer);
    final opponent = _opponentPos;
    final moves = <BoardPos>{};

    for (final n in _orthogonalNeighbors(from)) {
      if (isEdgeBlocked(from, n)) continue;
      if (n == opponent) {
        moves.addAll(_jumpDestinations(from, opponent));
      } else {
        moves.add(n);
      }
    }
    return moves.toList();
  }

  List<BoardPos> _jumpDestinations(BoardPos from, BoardPos opponent) {
    final dr = opponent.row - from.row;
    final dc = opponent.col - from.col;
    final beyond = BoardPos(opponent.row + dr, opponent.col + dc);

    if (beyond.inBounds && !isEdgeBlocked(opponent, beyond)) {
      return [beyond];
    }

    // Sideways jumps when straight jump is blocked or off-board.
    final sides = <BoardPos>[];
    if (dr != 0) {
      // Vertical approach → lateral horizontal jumps
      for (final sideCol in [opponent.col - 1, opponent.col + 1]) {
        final side = BoardPos(opponent.row, sideCol);
        if (!side.inBounds) continue;
        if (isEdgeBlocked(opponent, side)) continue;
        if (side == from) continue;
        sides.add(side);
      }
    } else {
      for (final sideRow in [opponent.row - 1, opponent.row + 1]) {
        final side = BoardPos(sideRow, opponent.col);
        if (!side.inBounds) continue;
        if (isEdgeBlocked(opponent, side)) continue;
        if (side == from) continue;
        sides.add(side);
      }
    }
    return sides;
  }

  bool canMoveTo(BoardPos to) => legalMoves().contains(to);

  BlockRaceMoveResult? applyMove(BoardPos to) {
    if (phase != BlockRacePhase.choosing) return null;
    if (!canMoveTo(to)) return null;

    final from = positionOf(currentPlayer);
    if (currentPlayer == BlockRacePlayer.blue) {
      bluePos = to;
    } else {
      redPos = to;
    }
    moveCount++;

    if (hasReachedGoal(currentPlayer)) {
      winner = currentPlayer;
      phase = BlockRacePhase.gameOver;
      return BlockRaceMoveResult(from: from, to: to, won: true);
    }

    phase = BlockRacePhase.animating;
    return BlockRaceMoveResult(from: from, to: to, won: false);
  }

  bool placeWall(Wall wall) {
    if (phase != BlockRacePhase.choosing) return false;
    if (!canPlaceWall(wall)) return false;

    walls.add(wall);
    if (currentPlayer == BlockRacePlayer.blue) {
      blueWallsLeft--;
    } else {
      redWallsLeft--;
    }
    moveCount++;
    phase = BlockRacePhase.animating;
    return true;
  }

  void finishAnimations() {
    if (phase != BlockRacePhase.animating) return;
    if (winner != null) {
      phase = BlockRacePhase.gameOver;
      return;
    }
    currentPlayer = currentPlayer == BlockRacePlayer.blue
        ? BlockRacePlayer.red
        : BlockRacePlayer.blue;
    actionMode = BlockRaceActionMode.move;
    phase = BlockRacePhase.choosing;
  }
}
