import 'package:flutter/material.dart';

import 'block_race_logic.dart';
import 'block_race_theme.dart';

/// Grey stone + teal-tile roof palette, with a player accent for ownership.
class CastleWallPalette {
  const CastleWallPalette({
    required this.stoneLight,
    required this.stone,
    required this.stoneDark,
    required this.outline,
    required this.roofLight,
    required this.roof,
    required this.roofDark,
    required this.wood,
    required this.accent,
  });

  final Color stoneLight;
  final Color stone;
  final Color stoneDark;
  final Color outline;
  final Color roofLight;
  final Color roof;
  final Color roofDark;
  final Color wood;
  final Color accent;

  static CastleWallPalette of(BlockRacePlayer owner) {
    final accent = BlockRaceTheme.wallColor(owner);
    return CastleWallPalette(
      stoneLight: const Color(0xFFD8DCE2),
      stone: const Color(0xFFB0B6BE),
      stoneDark: const Color(0xFF7E868F),
      outline: const Color(0xFF3F4650),
      roofLight: const Color(0xFF6EC8C4),
      roof: const Color(0xFF3AA8A4),
      roofDark: const Color(0xFF1F7A78),
      wood: const Color(0xFF6B4A2E),
      accent: accent,
    );
  }

  /// Soft ghost used while dragging over an illegal slot.
  static CastleWallPalette ghost({required bool legal}) {
    final base = of(BlockRacePlayer.red);
    if (legal) {
      return CastleWallPalette(
        stoneLight: Color.lerp(
          base.stoneLight,
          BlockRaceTheme.validGhost,
          0.25,
        )!,
        stone: Color.lerp(base.stone, BlockRaceTheme.validGhost, 0.2)!,
        stoneDark: base.stoneDark,
        outline: BlockRaceTheme.validGhost,
        roofLight: base.roofLight,
        roof: base.roof,
        roofDark: base.roofDark,
        wood: base.wood,
        accent: BlockRaceTheme.validGhost,
      );
    }
    return CastleWallPalette(
      stoneLight: Color.lerp(
        base.stoneLight,
        BlockRaceTheme.invalidGhost,
        0.35,
      )!,
      stone: Color.lerp(base.stone, BlockRaceTheme.invalidGhost, 0.3)!,
      stoneDark: base.stoneDark,
      outline: BlockRaceTheme.invalidGhost,
      roofLight: Color.lerp(base.roofLight, BlockRaceTheme.invalidGhost, 0.2)!,
      roof: Color.lerp(base.roof, BlockRaceTheme.invalidGhost, 0.25)!,
      roofDark: base.roofDark,
      wood: base.wood,
      accent: BlockRaceTheme.invalidGhost,
    );
  }
}

/// Paints a Quoridor-length castle wall: stone body + teal tiled roof.
class CastleWallPainter extends CustomPainter {
  CastleWallPainter({
    required this.horizontal,
    required this.palette,
    this.opacity = 1,
  });

  final bool horizontal;
  final CastleWallPalette palette;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    if (horizontal) {
      _paintHorizontal(canvas, size);
    } else {
      _paintVertical(canvas, size);
    }
    canvas.restore();
  }

  void _paintHorizontal(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final bodyTop = h * 0.34;
    final body = Rect.fromLTRB(0, bodyTop, w, h);

    // Drop shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(Offset(0, h * 0.08)),
        Radius.circular(h * 0.08),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.08),
    );

    // Stone body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.06)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.stoneLight, palette.stone, palette.stoneDark],
        ).createShader(body),
    );

    // Brick seams.
    final seam = Paint()
      ..color = palette.outline.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final rowH = (h - bodyTop) / 2.2;
    canvas.drawLine(
      Offset(2, bodyTop + rowH),
      Offset(w - 2, bodyTop + rowH),
      seam,
    );
    for (var i = 1; i < 6; i++) {
      final x = w * i / 6;
      final shift = i.isOdd ? rowH * 0.5 : 0.0;
      canvas.drawLine(Offset(x, bodyTop + 2 + shift), Offset(x, h - 2), seam);
    }

    // Accent banner stripe (owner color).
    final banner = Rect.fromLTWH(
      w * 0.12,
      bodyTop + rowH * 0.55,
      w * 0.76,
      rowH * 0.55,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(banner, Radius.circular(rowH * 0.12)),
      Paint()..color = palette.accent.withValues(alpha: 0.85),
    );

    // Wooden eaves under the roof.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.26, w, h * 0.1),
      Paint()..color = palette.wood,
    );

    // Teal tiled roof (slightly overhanging).
    final roof = Path()
      ..moveTo(-w * 0.02, h * 0.28)
      ..lineTo(w * 0.08, h * 0.04)
      ..lineTo(w * 0.92, h * 0.04)
      ..lineTo(w * 1.02, h * 0.28)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.roofLight, palette.roof, palette.roofDark],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.3)),
    );

    // Scale tiles.
    final tilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = palette.roofDark.withValues(alpha: 0.55);
    for (var row = 0; row < 3; row++) {
      final y = h * (0.08 + row * 0.07);
      final inset = w * (0.06 + row * 0.015);
      for (var i = 0; i < 8; i++) {
        final x0 = inset + (w - inset * 2) * i / 8;
        final x1 = inset + (w - inset * 2) * (i + 1) / 8;
        canvas.drawArc(
          Rect.fromLTRB(x0, y, x1, y + h * 0.08),
          0,
          3.14,
          false,
          tilePaint,
        );
      }
    }

    // Roof ridge.
    canvas.drawLine(
      Offset(w * 0.1, h * 0.05),
      Offset(w * 0.9, h * 0.05),
      Paint()
        ..color = palette.outline
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Outline body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.06)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = palette.outline,
    );
  }

  void _paintVertical(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Roof sits on the "camera-facing" (bottom) side of a top-down vertical wall.
    final body = Rect.fromLTRB(w * 0.22, 0, w * 0.78, h);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(Offset(0, w * 0.06)),
        Radius.circular(w * 0.08),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.08)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [palette.stoneLight, palette.stone, palette.stoneDark],
        ).createShader(body),
    );

    final seam = Paint()
      ..color = palette.outline.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final colW = body.width / 2.2;
    canvas.drawLine(
      Offset(body.left + colW, 2),
      Offset(body.left + colW, h - 2),
      seam,
    );
    for (var i = 1; i < 6; i++) {
      final y = h * i / 6;
      final shift = i.isOdd ? colW * 0.5 : 0.0;
      canvas.drawLine(
        Offset(body.left + 2 + shift, y),
        Offset(body.right - 2, y),
        seam,
      );
    }

    // Owner accent stripe down the face.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left + colW * 0.55, h * 0.12, colW * 0.55, h * 0.76),
        Radius.circular(colW * 0.12),
      ),
      Paint()..color = palette.accent.withValues(alpha: 0.85),
    );

    // Wooden eaves + teal roof along the near edge.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.14, 0, w * 0.12, h),
      Paint()..color = palette.wood,
    );

    final roof = Path()
      ..moveTo(w * 0.02, -h * 0.02)
      ..lineTo(w * 0.28, h * 0.06)
      ..lineTo(w * 0.28, h * 0.94)
      ..lineTo(w * 0.02, h * 1.02)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [palette.roofLight, palette.roof, palette.roofDark],
        ).createShader(Rect.fromLTWH(0, 0, w * 0.3, h)),
    );

    final tilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = palette.roofDark.withValues(alpha: 0.55);
    for (var col = 0; col < 3; col++) {
      final x = w * (0.06 + col * 0.06);
      for (var i = 0; i < 8; i++) {
        final y0 = h * (0.06 + i * 0.11);
        canvas.drawArc(
          Rect.fromLTWH(x - w * 0.04, y0, w * 0.1, h * 0.1),
          -1.2,
          2.4,
          false,
          tilePaint,
        );
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.08)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = palette.outline,
    );
  }

  @override
  bool shouldRepaint(CastleWallPainter old) =>
      old.horizontal != horizontal ||
      old.opacity != opacity ||
      old.palette.accent != palette.accent ||
      old.palette.outline != palette.outline;
}

/// Small stone pillar with a pointed teal roof — free end / corner hub.
class CastlePillarPainter extends CustomPainter {
  CastlePillarPainter({required this.palette, this.opacity = 1});

  final CastleWallPalette palette;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    final s = size.shortestSide;
    final cx = size.width / 2;
    final body = Rect.fromCenter(
      center: Offset(cx, size.height * 0.62),
      width: s * 0.55,
      height: s * 0.58,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(Offset(0, s * 0.06)),
        Radius.circular(s * 0.08),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 0.08)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.stoneLight, palette.stone, palette.stoneDark],
        ).createShader(body),
    );

    // Accent gem / door niche.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height * 0.64),
          width: s * 0.22,
          height: s * 0.28,
        ),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = palette.accent.withValues(alpha: 0.9),
    );

    // Pointed teal roof.
    final roof = Path()
      ..moveTo(cx, size.height * 0.06)
      ..lineTo(cx + s * 0.42, size.height * 0.42)
      ..lineTo(cx - s * 0.42, size.height * 0.42)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.roofLight, palette.roof, palette.roofDark],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45)),
    );
    canvas.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = palette.outline,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 0.08)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = palette.outline,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(CastlePillarPainter old) =>
      old.opacity != opacity || old.palette.accent != palette.accent;
}

/// Snaps a local board-grid offset to the nearest fence wall of [orientation].
Wall snapWallAt(Offset local, double cell, WallOrientation orientation) {
  final max = BlockRaceGame.fenceSize - 1;
  // Centers of both H and V walls sit on lattice points (col+1, row+1).
  final row = ((local.dy / cell) - 1).round().clamp(0, max);
  final col = ((local.dx / cell) - 1).round().clamp(0, max);
  return Wall(row: row, col: col, orientation: orientation);
}

/// Compact wall token used in the drag tray / feedback chip.
class CastleWallToken extends StatelessWidget {
  const CastleWallToken({
    super.key,
    required this.horizontal,
    required this.owner,
    this.width = 92,
    this.height = 36,
  });

  final bool horizontal;
  final BlockRacePlayer owner;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: horizontal ? width : height,
      height: horizontal ? height : width,
      child: Image.asset(
        BlockRaceTheme.wallAsset(owner, horizontal: horizontal),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
