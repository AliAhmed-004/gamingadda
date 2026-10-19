import 'package:flutter/material.dart';

import 'blokus_logic.dart';

abstract final class BlokusTheme {
  static const boardSize = 20;
  static const extrusionRatio = 0.14;
  static const cellGap = 0.08;
  static const panelRadius = 18.0;
  static const placePopDuration = Duration(milliseconds: 220);
  static const aiTurnDelay = Duration(milliseconds: 420);
  static const resultOverlayDelay = Duration(milliseconds: 400);

  static const bgTop = Color(0xFF0C3D4A);
  static const bgBottom = Color(0xFF071E28);
  static const panelFill = Color(0xFF2A1F18);
  static const panelRim = Color(0xFF5C4033);
  static const gridLight = Color(0xFFE8D5B5);
  static const gridDark = Color(0xFFD4BC94);
  static const statusText = Color(0xFFE8F4F8);

  static Color face(BlokusColor c) => switch (c) {
    BlokusColor.blue => const Color(0xFF3B82F6),
    BlokusColor.yellow => const Color(0xFFFACC15),
    BlokusColor.red => const Color(0xFFEF4444),
    BlokusColor.green => const Color(0xFF22C55E),
  };

  static Color faceDeep(BlokusColor c) => switch (c) {
    BlokusColor.blue => const Color(0xFF1D4ED8),
    BlokusColor.yellow => const Color(0xFFCA8A04),
    BlokusColor.red => const Color(0xFFB91C1C),
    BlokusColor.green => const Color(0xFF15803D),
  };

  static Color faceLite(BlokusColor c) => switch (c) {
    BlokusColor.blue => const Color(0xFF93C5FD),
    BlokusColor.yellow => const Color(0xFFFEF08A),
    BlokusColor.red => const Color(0xFFFCA5A5),
    BlokusColor.green => const Color(0xFF86EFAC),
  };
}
