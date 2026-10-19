import 'package:flutter/material.dart';

/// Colors, assets, and motion timings for Memory Match.
abstract final class MemoryMatchTheme {
  static const back = Color(0xFF2563EB);
  static const backEdge = Color(0xFF1D4ED8);
  static const face = Color(0xFFFFFBF2);
  static const boardBg = Color(0xFF0F2744);
  static const glow = Color(0xFFFACC15);
  static const match = Color(0xFF34D399);
  static const miss = Color(0xFFF87171);
  static const panel = Color(0xFF163A5F);

  static const cardBackAsset = 'assets/memory_match/card_back.png';

  static const flipDuration = Duration(milliseconds: 280);
  static const matchPulseDuration = Duration(milliseconds: 420);
  static const peekStagger = Duration(milliseconds: 40);

  static const faces = <MemoryMatchFace>[
    MemoryMatchFace('assets/memory_match/faces/face_00.png', Color(0xFFFACC15)),
    MemoryMatchFace('assets/memory_match/faces/face_01.png', Color(0xFFF43F5E)),
    MemoryMatchFace('assets/memory_match/faces/face_02.png', Color(0xFFFB923C)),
    MemoryMatchFace('assets/memory_match/faces/face_03.png', Color(0xFF38BDF8)),
    MemoryMatchFace('assets/memory_match/faces/face_04.png', Color(0xFFA78BFA)),
    MemoryMatchFace('assets/memory_match/faces/face_05.png', Color(0xFFFB7185)),
    MemoryMatchFace('assets/memory_match/faces/face_06.png', Color(0xFF4ADE80)),
    MemoryMatchFace('assets/memory_match/faces/face_07.png', Color(0xFF818CF8)),
    MemoryMatchFace('assets/memory_match/faces/face_08.png', Color(0xFFFBBF24)),
    MemoryMatchFace('assets/memory_match/faces/face_09.png', Color(0xFF22D3EE)),
    MemoryMatchFace('assets/memory_match/faces/face_10.png', Color(0xFFF472B6)),
    MemoryMatchFace('assets/memory_match/faces/face_11.png', Color(0xFF60A5FA)),
    MemoryMatchFace('assets/memory_match/faces/face_12.png', Color(0xFFFDE047)),
    MemoryMatchFace('assets/memory_match/faces/face_13.png', Color(0xFF67E8F9)),
    MemoryMatchFace('assets/memory_match/faces/face_14.png', Color(0xFFEF4444)),
    MemoryMatchFace('assets/memory_match/faces/face_15.png', Color(0xFF4ADE80)),
    MemoryMatchFace('assets/memory_match/faces/face_16.png', Color(0xFFC084FC)),
    MemoryMatchFace('assets/memory_match/faces/face_17.png', Color(0xFF2DD4BF)),
  ];

  static MemoryMatchFace faceFor(int pairId) =>
      faces[pairId % faces.length];
}

class MemoryMatchFace {
  const MemoryMatchFace(this.asset, this.color);

  final String asset;
  final Color color;
}
