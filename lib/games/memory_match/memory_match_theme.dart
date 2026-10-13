import 'package:flutter/material.dart';

/// Colors and motion timings for Memory Match.
abstract final class MemoryMatchTheme {
  static const back = Color(0xFF2563EB);
  static const backEdge = Color(0xFF1D4ED8);
  static const face = Color(0xFFFFFBF2);
  static const boardBg = Color(0xFF0F2744);
  static const glow = Color(0xFFFACC15);
  static const match = Color(0xFF34D399);
  static const miss = Color(0xFFF87171);
  static const panel = Color(0xFF163A5F);

  static const flipDuration = Duration(milliseconds: 280);
  static const matchPulseDuration = Duration(milliseconds: 420);
  static const peekStagger = Duration(milliseconds: 40);

  static const faces = <MemoryMatchFace>[
    MemoryMatchFace(Icons.star_rounded, Color(0xFFFACC15)),
    MemoryMatchFace(Icons.favorite_rounded, Color(0xFFF43F5E)),
    MemoryMatchFace(Icons.bolt_rounded, Color(0xFFFB923C)),
    MemoryMatchFace(Icons.water_drop_rounded, Color(0xFF38BDF8)),
    MemoryMatchFace(Icons.local_florist_rounded, Color(0xFFA78BFA)),
    MemoryMatchFace(Icons.pets_rounded, Color(0xFFFB7185)),
    MemoryMatchFace(Icons.sports_soccer_rounded, Color(0xFF4ADE80)),
    MemoryMatchFace(Icons.music_note_rounded, Color(0xFF818CF8)),
    MemoryMatchFace(Icons.emoji_emotions_rounded, Color(0xFFFBBF24)),
    MemoryMatchFace(Icons.rocket_launch_rounded, Color(0xFF22D3EE)),
    MemoryMatchFace(Icons.cake_rounded, Color(0xFFF472B6)),
    MemoryMatchFace(Icons.anchor_rounded, Color(0xFF60A5FA)),
    MemoryMatchFace(Icons.brightness_high_rounded, Color(0xFFFDE047)),
    MemoryMatchFace(Icons.ac_unit_rounded, Color(0xFF67E8F9)),
    MemoryMatchFace(Icons.local_fire_department_rounded, Color(0xFFEF4444)),
    MemoryMatchFace(Icons.eco_rounded, Color(0xFF4ADE80)),
    MemoryMatchFace(Icons.nightlight_round, Color(0xFFC084FC)),
    MemoryMatchFace(Icons.diamond_rounded, Color(0xFF2DD4BF)),
  ];
}

class MemoryMatchFace {
  const MemoryMatchFace(this.icon, this.color);

  final IconData icon;
  final Color color;
}
