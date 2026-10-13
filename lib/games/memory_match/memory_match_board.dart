import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'memory_match_logic.dart';
import 'memory_match_theme.dart';

class MemoryMatchBoard extends StatelessWidget {
  const MemoryMatchBoard({
    super.key,
    required this.game,
    required this.columns,
    required this.onTap,
    this.highlightMatched = const {},
  });

  final MemoryMatchGame game;
  final int columns;
  final ValueChanged<int> onTap;
  final Set<int> highlightMatched;

  static const glow = MemoryMatchTheme.glow;
  static const frameLight = Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (game.cards.length / columns).ceil();
        final gap = 8.0;
        final pad = 10.0;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final cellW = (maxW - pad * 2 - gap * (columns - 1)) / columns;
        final cellHFromW = cellW / 0.78;
        final cellHCap = (maxH - pad * 2 - gap * (rows - 1)) / rows;
        final cellH = cellHFromW < cellHCap ? cellHFromW : cellHCap;
        final cellWFinal = cellH * 0.78;
        final boardW = pad * 2 + cellWFinal * columns + gap * (columns - 1);
        final boardH = pad * 2 + cellH * rows + gap * (rows - 1);

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: MemoryMatchTheme.boardBg.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: game.cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final card = game.cards[index];
                    return _FlipCard(
                      key: ValueKey('card-$index-${card.pairId}'),
                      card: card,
                      highlighted: highlightMatched.contains(index),
                      onTap: game.inputLocked || game.isOver
                          ? null
                          : () => onTap(index),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    super.key,
    required this.card,
    required this.highlighted,
    this.onTap,
  });

  final MemoryCard card;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final faceUp = card.isFaceUp;
    final face = MemoryMatchTheme.faces[card.pairId % MemoryMatchTheme.faces.length];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: onTap != null && !faceUp,
      label: faceUp
          ? (card.isMatched ? 'Matched card' : 'Face-up card')
          : 'Face-down card',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: highlighted ? 1.06 : 1.0,
          duration: MemoryMatchTheme.matchPulseDuration,
          curve: Curves.easeOutBack,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: faceUp ? 1.0 : 0.0),
            duration: reduceMotion
                ? Duration.zero
                : MemoryMatchTheme.flipDuration,
            curve: Curves.easeInOut,
            builder: (context, t, _) {
              final angle = t * math.pi;
              final showFace = t >= 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: showFace
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _Face(
                          face: face,
                          matched: card.isMatched,
                          highlighted: highlighted,
                        ),
                      )
                    : const _Back(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), MemoryMatchTheme.back, MemoryMatchTheme.backEdge],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
          ),
          child: Icon(
            Icons.question_mark_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.face,
    required this.matched,
    required this.highlighted,
  });

  final MemoryMatchFace face;
  final bool matched;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final border = matched || highlighted
        ? MemoryMatchTheme.match
        : face.color;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: MemoryMatchTheme.face,
        border: Border.all(color: border, width: matched ? 3 : 2.5),
        boxShadow: [
          if (highlighted || matched)
            BoxShadow(
              color: MemoryMatchTheme.match.withValues(alpha: 0.45),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Center(
        child: Icon(
          face.icon,
          size: 34,
          color: face.color,
          shadows: [
            Shadow(
              color: face.color.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact HUD chip used above the board.
class MemoryMatchHudChip extends StatelessWidget {
  const MemoryMatchHudChip({
    super.key,
    required this.icon,
    required this.label,
    this.accent = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
