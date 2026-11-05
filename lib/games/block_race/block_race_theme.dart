import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'block_race_logic.dart';

/// Light cartoon tabletop theme + assets for Barricade Clash.
abstract final class BlockRaceTheme {
  // —— Assets ——
  static const gotiRed = 'assets/block_race/goti_red.png';
  static const gotiBlue = 'assets/block_race/goti_blue.png';
  static const moveTarget = 'assets/block_race/move_target.png';
  static const boardPanel = 'assets/block_race/board_panel.png';
  static const wallHRed = 'assets/block_race/wall_h_red.png';
  static const wallHBlue = 'assets/block_race/wall_h_blue.png';
  static const wallVRed = 'assets/block_race/wall_v_red.png';
  static const wallVBlue = 'assets/block_race/wall_v_blue.png';
  static const wallPillarRed = 'assets/block_race/wall_pillar_red.png';
  static const wallPillarBlue = 'assets/block_race/wall_pillar_blue.png';

  static String gotiAsset(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? gotiBlue : gotiRed;

  static String wallHAsset(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? wallHBlue : wallHRed;

  static String wallVAsset(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? wallVBlue : wallVRed;

  static String wallAsset(BlockRacePlayer player, {required bool horizontal}) =>
      horizontal ? wallHAsset(player) : wallVAsset(player);

  static String wallPillarAsset(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? wallPillarBlue : wallPillarRed;

  /// Player color used by painted ghosts / accents.
  static Color wallColor(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? bluePlayer : redPlayer;

  // —— Light palette (no neon) ——
  static const Color background = Color(0xFFF4EFE6);
  static const Color backgroundMid = Color(0xFFE8DFD0);
  static const Color foreground = Color(0xFF3A2F28);
  static const Color muted = Color(0xFF7A6A5C);
  static const Color boardBase = Color(0xFFE8D7B8);
  static const Color boardElevated = Color(0xFFF3E6CF);
  static const Color gridLine = Color(0xFFD2C0A4);
  static const Color panel = Color(0xFFFFFBF5);
  static const Color chipFill = Color(0xFFFFF8F0);

  static const Color bluePlayer = Color(0xFF5694DC);
  static const Color redPlayer = Color(0xFFE86056);
  static const Color barricade = Color(0xFFC4945C);
  static const Color validGhost = Color(0xFF5AAF6E);
  static const Color invalidGhost = Color(0xFFD96A6A);

  /// Kept as aliases so older call sites keep compiling.
  static const Color neonCyan = bluePlayer;
  static const Color neonRed = redPlayer;
  static const Color neonMagenta = barricade;

  static const Duration moveDuration = Duration(milliseconds: 180);
  static const Duration wallDuration = Duration(milliseconds: 140);
  static const Duration aiThinkDuration = Duration(milliseconds: 280);
  static const Duration uiDuration = Duration(milliseconds: 160);

  static TextStyle display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = foreground,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.4,
    );
  }

  static TextStyle body({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color color = foreground,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.2,
    );
  }

  static TextStyle comfortaa({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color color = foreground,
  }) => body(fontSize: fontSize, fontWeight: fontWeight, color: color);
}
