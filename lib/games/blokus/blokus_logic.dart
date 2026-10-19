import 'blokus_pieces.dart';

enum BlokusColor { blue, yellow, red, green }

extension BlokusColorX on BlokusColor {
  String get label => switch (this) {
    BlokusColor.blue => 'Blue',
    BlokusColor.yellow => 'Yellow',
    BlokusColor.red => 'Red',
    BlokusColor.green => 'Green',
  };

  BlokusColor get next => switch (this) {
    BlokusColor.blue => BlokusColor.yellow,
    BlokusColor.yellow => BlokusColor.red,
    BlokusColor.red => BlokusColor.green,
    BlokusColor.green => BlokusColor.blue,
  };
}

/// Starting corner for each color (row, col) on a 20×20 board.
BlokusCell cornerFor(BlokusColor color) => switch (color) {
  BlokusColor.blue => const BlokusCell(0, 0),
  BlokusColor.yellow => const BlokusCell(0, 19),
  BlokusColor.red => const BlokusCell(19, 19),
  BlokusColor.green => const BlokusCell(19, 0),
};

/// Active seats: 4 = all; 3 = drop green; 2 = all four (dual-color ownership).
List<BlokusColor> activeColorsForPlayerCount(int playerCount) {
  switch (playerCount) {
    case 2:
    case 4:
      return List<BlokusColor>.from(BlokusColor.values);
    case 3:
      return const [
        BlokusColor.blue,
        BlokusColor.yellow,
        BlokusColor.red,
      ];
    default:
      throw ArgumentError.value(
        playerCount,
        'playerCount',
        'Must be 2, 3, or 4',
      );
  }
}

/// In 2-player, each seat owns a diagonal pair.
Set<BlokusColor> colorsOwnedBySeat(BlokusColor seat, int playerCount) {
  if (playerCount != 2) return {seat};
  // Blue+Red vs Yellow+Green (diagonals).
  if (seat == BlokusColor.blue || seat == BlokusColor.red) {
    return {BlokusColor.blue, BlokusColor.red};
  }
  return {BlokusColor.yellow, BlokusColor.green};
}

/// Primary seat color for picking a human side in setup (2p uses blue or yellow).
List<BlokusColor> seatChoicesForPlayerCount(int playerCount) {
  if (playerCount == 2) {
    return const [BlokusColor.blue, BlokusColor.yellow];
  }
  return activeColorsForPlayerCount(playerCount);
}

class BlokusPlacement {
  const BlokusPlacement({
    required this.color,
    required this.pieceId,
    required this.orientationIndex,
    required this.origin,
    required this.cells,
  });

  final BlokusColor color;
  final String pieceId;
  final int orientationIndex;

  /// Board position of the piece's (0,0) after normalization.
  final BlokusCell origin;
  final List<BlokusCell> cells;
}

class BlokusGame {
  BlokusGame({this.playerCount = 4}) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError.value(playerCount, 'playerCount');
    }
    reset();
  }

  static const boardSize = 20;

  final int playerCount;

  late List<BlokusColor> activeColors;
  late List<List<BlokusColor?>> board;
  late Map<BlokusColor, Set<String>> remaining;
  late Map<BlokusColor, int> scores;
  late Map<BlokusColor, bool> hasPlaced;
  late Set<BlokusColor> passed;
  late BlokusColor turn;
  bool gameOver = false;

  void reset() {
    activeColors = activeColorsForPlayerCount(playerCount);
    board = List.generate(
      boardSize,
      (_) => List<BlokusColor?>.filled(boardSize, null),
    );
    remaining = {
      for (final c in activeColors)
        c: {...BlokusPieces.ids},
    };
    scores = {for (final c in activeColors) c: 0};
    hasPlaced = {for (final c in activeColors) c: false};
    passed = {};
    turn = activeColors.first;
    gameOver = false;
  }

  bool inBounds(BlokusCell c) =>
      c.row >= 0 &&
      c.row < boardSize &&
      c.col >= 0 &&
      c.col < boardSize;

  BlokusColor? at(BlokusCell c) =>
      inBounds(c) ? board[c.row][c.col] : null;

  List<List<BlokusCell>> orientationsOf(String pieceId) =>
      uniqueOrientations(BlokusPieces.byId(pieceId));

  List<BlokusCell> absoluteCells(
    List<BlokusCell> orientation,
    BlokusCell origin,
  ) =>
      [for (final c in orientation) c + origin];

  /// Whether [placement] obeys board rules (ignores whose turn it is).
  bool isLegalPlacement(BlokusPlacement placement) {
    if (!(remaining[placement.color]?.contains(placement.pieceId) ?? false)) {
      return false;
    }

    final cells = placement.cells;
    if (cells.isEmpty) return false;

    for (final c in cells) {
      if (!inBounds(c)) return false;
      if (board[c.row][c.col] != null) return false;
    }

    final color = placement.color;
    final first = !(hasPlaced[color] ?? false);

    if (first) {
      final corner = cornerFor(color);
      return cells.any((c) => c == corner);
    }

    // Must touch own color by at least one corner; must not share an edge.
    var cornerTouch = false;
    for (final c in cells) {
      for (final d in const [
        BlokusCell(-1, 0),
        BlokusCell(1, 0),
        BlokusCell(0, -1),
        BlokusCell(0, 1),
      ]) {
        final n = c + d;
        if (at(n) == color) return false;
      }
      for (final d in const [
        BlokusCell(-1, -1),
        BlokusCell(-1, 1),
        BlokusCell(1, -1),
        BlokusCell(1, 1),
      ]) {
        final n = c + d;
        if (at(n) == color) cornerTouch = true;
      }
    }
    return cornerTouch;
  }

  bool canPlace(BlokusPlacement placement) {
    if (gameOver) return false;
    if (placement.color != turn) return false;
    return isLegalPlacement(placement);
  }

  /// All legal placements for [color] + [pieceId] across orientations.
  List<BlokusPlacement> legalPlacements(BlokusColor color, String pieceId) {
    if (!(remaining[color]?.contains(pieceId) ?? false)) return const [];
    final orients = orientationsOf(pieceId);
    final out = <BlokusPlacement>[];
    for (var oi = 0; oi < orients.length; oi++) {
      final orient = orients[oi];
      final maxR = orient.map((c) => c.row).reduce((a, b) => a > b ? a : b);
      final maxC = orient.map((c) => c.col).reduce((a, b) => a > b ? a : b);
      for (var r = 0; r < boardSize - maxR; r++) {
        for (var c = 0; c < boardSize - maxC; c++) {
          final origin = BlokusCell(r, c);
          final abs = absoluteCells(orient, origin);
          final p = BlokusPlacement(
            color: color,
            pieceId: pieceId,
            orientationIndex: oi,
            origin: origin,
            cells: abs,
          );
          if (isLegalPlacement(p)) out.add(p);
        }
      }
    }
    return out;
  }

  /// Placement with [pieceId] at [orientationIndex] such that one of the
  /// piece cells covers [anchor] on the board.
  BlokusPlacement? placementAtAnchor({
    required BlokusColor color,
    required String pieceId,
    required int orientationIndex,
    required BlokusCell anchor,
    int cellIndex = 0,
  }) {
    final orients = orientationsOf(pieceId);
    if (orientationIndex < 0 || orientationIndex >= orients.length) {
      return null;
    }
    final orient = orients[orientationIndex];
    if (cellIndex < 0 || cellIndex >= orient.length) return null;
    final local = orient[cellIndex];
    final origin = BlokusCell(anchor.row - local.row, anchor.col - local.col);
    final abs = absoluteCells(orient, origin);
    return BlokusPlacement(
      color: color,
      pieceId: pieceId,
      orientationIndex: orientationIndex,
      origin: origin,
      cells: abs,
    );
  }

  /// Faster than enumerating every origin: scans candidates near corner / own corners.
  BlokusPlacement? findAnyLegalPlacement(BlokusColor color) {
    final pieces = remaining[color];
    if (pieces == null || pieces.isEmpty) return null;
    final ordered = pieces.toList()
      ..sort(
        (a, b) =>
            BlokusPieces.byId(b).size.compareTo(BlokusPieces.byId(a).size),
      );

    final first = !(hasPlaced[color] ?? false);
    if (first) {
      final corner = cornerFor(color);
      for (final id in ordered) {
        final orients = orientationsOf(id);
        for (var oi = 0; oi < orients.length; oi++) {
          final orient = orients[oi];
          for (var ci = 0; ci < orient.length; ci++) {
            final p = placementAtAnchor(
              color: color,
              pieceId: id,
              orientationIndex: oi,
              anchor: corner,
              cellIndex: ci,
            );
            if (p != null && isLegalPlacement(p)) return p;
          }
        }
      }
      return null;
    }

    // Candidate empty cells that diagonally touch our color.
    final anchors = <BlokusCell>{};
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        if (board[r][c] != color) continue;
        for (final d in const [
          BlokusCell(-1, -1),
          BlokusCell(-1, 1),
          BlokusCell(1, -1),
          BlokusCell(1, 1),
        ]) {
          final n = BlokusCell(r, c) + d;
          if (inBounds(n) && board[n.row][n.col] == null) {
            anchors.add(n);
          }
        }
      }
    }

    for (final id in ordered) {
      final orients = orientationsOf(id);
      for (var oi = 0; oi < orients.length; oi++) {
        final orient = orients[oi];
        for (final anchor in anchors) {
          for (var ci = 0; ci < orient.length; ci++) {
            final p = placementAtAnchor(
              color: color,
              pieceId: id,
              orientationIndex: oi,
              anchor: anchor,
              cellIndex: ci,
            );
            if (p != null && isLegalPlacement(p)) return p;
          }
        }
      }
    }
    return null;
  }

  bool hasAnyLegalMove(BlokusColor color) =>
      findAnyLegalPlacement(color) != null;

  bool place(BlokusPlacement placement) {
    if (!canPlace(placement)) return false;
    for (final c in placement.cells) {
      board[c.row][c.col] = placement.color;
    }
    remaining[placement.color]!.remove(placement.pieceId);
    scores[placement.color] =
        (scores[placement.color] ?? 0) + placement.cells.length;
    hasPlaced[placement.color] = true;
    passed.remove(placement.color);
    _advanceAfterAction();
    return true;
  }

  bool pass() {
    if (gameOver) return false;
    passed.add(turn);
    _advanceAfterAction();
    return true;
  }

  void _advanceAfterAction() {
    if (_allPassedOrDone()) {
      gameOver = true;
      return;
    }
    var next = turn.next;
    for (var i = 0; i < 4; i++) {
      if (activeColors.contains(next) && !passed.contains(next)) {
        // Skip colors that have no remaining pieces.
        final rem = remaining[next];
        if (rem != null && rem.isEmpty) {
          passed.add(next);
          next = next.next;
          continue;
        }
        turn = next;
        return;
      }
      next = next.next;
    }
    gameOver = true;
  }

  bool _allPassedOrDone() {
    if (activeColors.every((c) => passed.contains(c))) return true;
    if (activeColors.every((c) => (remaining[c]?.isEmpty ?? true))) {
      return true;
    }
    // Everyone either passed or has empty remaining.
    return activeColors.every(
      (c) => passed.contains(c) || (remaining[c]?.isEmpty ?? true),
    );
  }

  /// Combined score for a 2-player seat (sum of owned colors).
  int seatScore(BlokusColor seat) {
    final owned = colorsOwnedBySeat(seat, playerCount);
    return owned.fold<int>(0, (s, c) => s + (scores[c] ?? 0));
  }

  List<BlokusColor> ranking() {
    final colors = List<BlokusColor>.from(activeColors);
    colors.sort((a, b) {
      final ds = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
      return ds != 0 ? ds : a.index.compareTo(b.index);
    });
    return colors;
  }
}
