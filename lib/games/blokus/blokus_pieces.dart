/// One cell on a Blokus piece or board (row, col).
class BlokusCell {
  const BlokusCell(this.row, this.col);

  final int row;
  final int col;

  BlokusCell operator +(BlokusCell o) => BlokusCell(row + o.row, col + o.col);

  @override
  bool operator ==(Object other) =>
      other is BlokusCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// A polyomino shape with a stable id and base cells (normalized).
class BlokusPieceDef {
  const BlokusPieceDef(this.id, this.cells);

  final String id;
  final List<BlokusCell> cells;

  int get size => cells.length;
}

/// Normalize so min row/col are 0, then sort for stable comparison.
List<BlokusCell> normalizeCells(Iterable<BlokusCell> raw) {
  final list = raw.toList();
  if (list.isEmpty) return const [];
  var minR = list.first.row;
  var minC = list.first.col;
  for (final c in list) {
    if (c.row < minR) minR = c.row;
    if (c.col < minC) minC = c.col;
  }
  final shifted = [
    for (final c in list) BlokusCell(c.row - minR, c.col - minC),
  ];
  shifted.sort((a, b) {
    final dr = a.row.compareTo(b.row);
    return dr != 0 ? dr : a.col.compareTo(b.col);
  });
  return shifted;
}

String cellsKey(List<BlokusCell> cells) =>
    cells.map((c) => '${c.row},${c.col}').join(';');

List<BlokusCell> rotate90(List<BlokusCell> cells) => normalizeCells([
  for (final c in cells) BlokusCell(c.col, -c.row),
]);

List<BlokusCell> flipH(List<BlokusCell> cells) => normalizeCells([
  for (final c in cells) BlokusCell(c.row, -c.col),
]);

/// All unique orientations (up to 8) for a piece definition.
List<List<BlokusCell>> uniqueOrientations(BlokusPieceDef def) {
  final seen = <String>{};
  final out = <List<BlokusCell>>[];
  var shape = normalizeCells(def.cells);
  for (var flip = 0; flip < 2; flip++) {
    var cur = shape;
    for (var r = 0; r < 4; r++) {
      final key = cellsKey(cur);
      if (seen.add(key)) out.add(cur);
      cur = rotate90(cur);
    }
    shape = flipH(shape);
  }
  return out;
}

/// The 21 free polyominoes used in classic Blokus (89 squares total).
abstract final class BlokusPieces {
  static const all = <BlokusPieceDef>[
    // 1
    BlokusPieceDef('1', [BlokusCell(0, 0)]),
    // 2
    BlokusPieceDef('2', [BlokusCell(0, 0), BlokusCell(0, 1)]),
    // 3
    BlokusPieceDef('3', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(0, 2),
    ]),
    BlokusPieceDef('v3', [
      BlokusCell(0, 0),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
    ]),
    // 4
    BlokusPieceDef('i4', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(0, 2),
      BlokusCell(0, 3),
    ]),
    BlokusPieceDef('o4', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
    ]),
    BlokusPieceDef('t4', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(0, 2),
      BlokusCell(1, 1),
    ]),
    BlokusPieceDef('l4', [
      BlokusCell(0, 0),
      BlokusCell(1, 0),
      BlokusCell(2, 0),
      BlokusCell(2, 1),
    ]),
    BlokusPieceDef('s4', [
      BlokusCell(0, 1),
      BlokusCell(0, 2),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
    ]),
    // 5 — pentominoes
    BlokusPieceDef('f', [
      BlokusCell(0, 1),
      BlokusCell(0, 2),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
      BlokusCell(2, 1),
    ]),
    BlokusPieceDef('i5', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(0, 2),
      BlokusCell(0, 3),
      BlokusCell(0, 4),
    ]),
    BlokusPieceDef('l5', [
      BlokusCell(0, 0),
      BlokusCell(1, 0),
      BlokusCell(2, 0),
      BlokusCell(3, 0),
      BlokusCell(3, 1),
    ]),
    BlokusPieceDef('n', [
      BlokusCell(0, 1),
      BlokusCell(1, 1),
      BlokusCell(2, 0),
      BlokusCell(2, 1),
      BlokusCell(3, 0),
    ]),
    BlokusPieceDef('p', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
      BlokusCell(2, 0),
    ]),
    BlokusPieceDef('t5', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(0, 2),
      BlokusCell(1, 1),
      BlokusCell(2, 1),
    ]),
    BlokusPieceDef('u', [
      BlokusCell(0, 0),
      BlokusCell(0, 2),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
      BlokusCell(1, 2),
    ]),
    BlokusPieceDef('v5', [
      BlokusCell(0, 0),
      BlokusCell(1, 0),
      BlokusCell(2, 0),
      BlokusCell(2, 1),
      BlokusCell(2, 2),
    ]),
    BlokusPieceDef('w', [
      BlokusCell(0, 0),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
      BlokusCell(2, 1),
      BlokusCell(2, 2),
    ]),
    BlokusPieceDef('x', [
      BlokusCell(0, 1),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
      BlokusCell(1, 2),
      BlokusCell(2, 1),
    ]),
    BlokusPieceDef('y', [
      BlokusCell(0, 1),
      BlokusCell(1, 0),
      BlokusCell(1, 1),
      BlokusCell(1, 2),
      BlokusCell(1, 3),
    ]),
    BlokusPieceDef('z', [
      BlokusCell(0, 0),
      BlokusCell(0, 1),
      BlokusCell(1, 1),
      BlokusCell(2, 1),
      BlokusCell(2, 2),
    ]),
  ];

  static BlokusPieceDef byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    throw ArgumentError.value(id, 'id', 'Unknown Blokus piece');
  }

  static final Set<String> ids = {for (final p in all) p.id};

  static int get totalSquares =>
      all.fold<int>(0, (sum, p) => sum + p.size);
}
