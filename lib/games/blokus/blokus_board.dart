import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'blokus_logic.dart';
import 'blokus_pieces.dart';
import 'blokus_theme.dart';

/// Ghost piece preview while aiming.
class BlokusGhost {
  const BlokusGhost({
    required this.cells,
    required this.color,
    required this.legal,
  });

  final List<BlokusCell> cells;
  final BlokusColor color;
  final bool legal;
}

/// Faux-3D 20×20 Blokus board with raised polyomino tiles.
class BlokusBoard extends StatelessWidget {
  const BlokusBoard({
    super.key,
    required this.game,
    this.ghost,
    this.onCellTap,
    this.onHover,
    this.interactive = true,
  });

  final BlokusGame game;
  final BlokusGhost? ghost;
  final ValueChanged<BlokusCell>? onCellTap;
  final ValueChanged<BlokusCell>? onHover;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: MouseRegion(
              onHover: interactive && onHover != null
                  ? (event) {
                      final cell = _hitTest(event.localPosition, side);
                      if (cell != null) onHover!(cell);
                    }
                  : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: interactive && onCellTap != null
                    ? (details) {
                        final cell = _hitTest(details.localPosition, side);
                        if (cell != null) onCellTap!(cell);
                      }
                    : null,
                child: CustomPaint(
                  size: Size.square(side),
                  painter: BlokusBoardPainter(
                    game: game,
                    ghost: ghost,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static BlokusCell? _hitTest(Offset local, double side) {
    const pad = 14.0;
    final inner = side - pad * 2;
    if (inner <= 0) return null;
    final cell = inner / BlokusTheme.boardSize;
    final x = local.dx - pad;
    final y = local.dy - pad;
    if (x < 0 || y < 0 || x >= inner || y >= inner) return null;
    final col = (x / cell).floor().clamp(0, BlokusTheme.boardSize - 1);
    final row = (y / cell).floor().clamp(0, BlokusTheme.boardSize - 1);
    return BlokusCell(row, col);
  }
}

class BlokusBoardPainter extends CustomPainter {
  BlokusBoardPainter({required this.game, this.ghost});

  final BlokusGame game;
  final BlokusGhost? ghost;

  static const _pad = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _drawPanel(canvas, rect);

    final inner = Rect.fromLTWH(
      _pad,
      _pad,
      size.width - _pad * 2,
      size.height - _pad * 2,
    );
    final cell = inner.width / BlokusTheme.boardSize;
    final extrude = cell * BlokusTheme.extrusionRatio;

    _drawGrid(canvas, inner, cell);
    _drawCornerMarkers(canvas, inner, cell);

    // Collect occupied cells per color for raised faces.
    for (final color in BlokusColor.values) {
      final cells = <BlokusCell>[];
      for (var r = 0; r < BlokusTheme.boardSize; r++) {
        for (var c = 0; c < BlokusTheme.boardSize; c++) {
          if (game.board[r][c] == color) {
            cells.add(BlokusCell(r, c));
          }
        }
      }
      if (cells.isNotEmpty) {
        _drawRaisedCells(canvas, inner, cell, extrude, cells, color, 1);
      }
    }

    final g = ghost;
    if (g != null && g.cells.isNotEmpty) {
      final tint = g.legal ? g.color : BlokusColor.red;
      _drawRaisedCells(
        canvas,
        inner,
        cell,
        extrude,
        g.cells,
        tint,
        g.legal ? 0.55 : 0.4,
        forceIllegal: !g.legal,
      );
    }
  }

  void _drawPanel(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(BlokusTheme.panelRadius),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const [Color(0xFF3D2A1F), Color(0xFF1A120E)],
        ),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = BlokusTheme.panelRim,
    );
  }

  void _drawGrid(Canvas canvas, Rect inner, double cell) {
    for (var r = 0; r < BlokusTheme.boardSize; r++) {
      for (var c = 0; c < BlokusTheme.boardSize; c++) {
        final rect = Rect.fromLTWH(
          inner.left + c * cell,
          inner.top + r * cell,
          cell,
          cell,
        ).deflate(cell * BlokusTheme.cellGap * 0.5);
        final base = (r + c).isEven
            ? BlokusTheme.gridLight
            : BlokusTheme.gridDark;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.12)),
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topLeft,
              rect.bottomRight,
              [
                Color.lerp(base, Colors.white, 0.18)!,
                Color.lerp(base, Colors.black, 0.12)!,
              ],
            ),
        );
      }
    }
  }

  void _drawCornerMarkers(Canvas canvas, Rect inner, double cell) {
    for (final color in game.activeColors) {
      final corner = cornerFor(color);
      final cx = inner.left + (corner.col + 0.5) * cell;
      final cy = inner.top + (corner.row + 0.5) * cell;
      canvas.drawCircle(
        Offset(cx, cy),
        cell * 0.18,
        Paint()..color = BlokusTheme.face(color).withValues(alpha: 0.55),
      );
    }
  }

  void _drawRaisedCells(
    Canvas canvas,
    Rect inner,
    double cell,
    double extrude,
    List<BlokusCell> cells,
    BlokusColor color,
    double opacity, {
    bool forceIllegal = false,
  }) {
    final face = forceIllegal
        ? const Color(0xFFEF4444)
        : BlokusTheme.face(color);
    final deep = forceIllegal
        ? const Color(0xFF991B1B)
        : BlokusTheme.faceDeep(color);
    final lite = forceIllegal
        ? const Color(0xFFFCA5A5)
        : BlokusTheme.faceLite(color);

    // Soft collective shadow.
    final shadowPath = Path();
    for (final c in cells) {
      final rect = Rect.fromLTWH(
        inner.left + c.col * cell,
        inner.top + c.row * cell,
        cell,
        cell,
      ).deflate(cell * BlokusTheme.cellGap * 0.35);
      shadowPath.addRRect(
        RRect.fromRectAndRadius(
          rect.shift(Offset(extrude * 0.35, extrude)),
          Radius.circular(cell * 0.14),
        ),
      );
    }
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.2),
    );

    for (final c in cells) {
      final faceRect = Rect.fromLTWH(
        inner.left + c.col * cell,
        inner.top + c.row * cell - extrude * 0.15,
        cell,
        cell,
      ).deflate(cell * BlokusTheme.cellGap * 0.35);

      // Side band (fake extrusion).
      final sideRect = Rect.fromLTWH(
        faceRect.left,
        faceRect.bottom - extrude * 0.2,
        faceRect.width,
        extrude,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(sideRect, Radius.circular(cell * 0.08)),
        Paint()..color = deep.withValues(alpha: opacity),
      );

      final rr = RRect.fromRectAndRadius(
        faceRect,
        Radius.circular(cell * 0.14),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = ui.Gradient.linear(
            faceRect.topLeft,
            faceRect.bottomRight,
            [
              lite.withValues(alpha: opacity),
              face.withValues(alpha: opacity),
              deep.withValues(alpha: opacity),
            ],
            const [0.0, 0.45, 1.0],
          ),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06
          ..color = Colors.white.withValues(alpha: 0.35 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BlokusBoardPainter oldDelegate) => true;
}

/// Mini faux-3D silhouette of a piece for the tray.
class BlokusPieceSilhouette extends StatelessWidget {
  const BlokusPieceSilhouette({
    super.key,
    required this.cells,
    required this.color,
    this.selected = false,
    this.size = 44,
  });

  final List<BlokusCell> cells;
  final BlokusColor color;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SilhouettePainter(
        cells: cells,
        color: color,
        selected: selected,
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({
    required this.cells,
    required this.color,
    required this.selected,
  });

  final List<BlokusCell> cells;
  final BlokusColor color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;
    var maxR = 0;
    var maxC = 0;
    for (final c in cells) {
      if (c.row > maxR) maxR = c.row;
      if (c.col > maxC) maxC = c.col;
    }
    final cols = maxC + 1;
    final rows = maxR + 1;
    final side = size.shortestSide;
    final unit = (side * 0.82) / (cols > rows ? cols : rows);
    final totalW = cols * unit;
    final totalH = rows * unit;
    final ox = (size.width - totalW) / 2;
    final oy = (size.height - totalH) / 2;
    final face = BlokusTheme.face(color);
    final deep = BlokusTheme.faceDeep(color);
    final extrude = unit * 0.18;

    for (final c in cells) {
      final rect = Rect.fromLTWH(
        ox + c.col * unit,
        oy + c.row * unit - extrude * 0.2,
        unit,
        unit,
      ).deflate(unit * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(Offset(0, extrude * 0.6)),
          Radius.circular(unit * 0.12),
        ),
        Paint()..color = deep,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(unit * 0.12)),
        Paint()..color = face,
      );
    }
    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(8),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) =>
      oldDelegate.cells != cells ||
      oldDelegate.color != color ||
      oldDelegate.selected != selected;
}
