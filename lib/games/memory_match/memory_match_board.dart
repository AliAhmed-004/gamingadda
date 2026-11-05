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
        final gap = 10.0;
        final pad = 12.0;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final cellW = (maxW - pad * 2 - gap * (columns - 1)) / columns;
        final cellHFromW = cellW / 0.72;
        final cellHCap = (maxH - pad * 2 - gap * (rows - 1)) / rows;
        final cellH = cellHFromW < cellHCap ? cellHFromW : cellHCap;
        final cellWFinal = cellH * 0.72;
        final boardW = pad * 2 + cellWFinal * columns + gap * (columns - 1);
        final boardH = pad * 2 + cellH * rows + gap * (rows - 1);

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MemoryMatchTheme.boardBg.withValues(alpha: 0.75),
                    const Color(0xFF0A1628).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
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
                    childAspectRatio: 0.72,
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
    final face = MemoryMatchTheme.faceFor(card.pairId);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: onTap != null && !faceUp,
      label: faceUp
          ? (card.isMatched ? 'Matched card' : 'Face-up card')
          : 'Face-down card',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: highlighted ? 1.07 : 1.0,
          duration: MemoryMatchTheme.matchPulseDuration,
          curve: Curves.easeOutBack,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: faceUp ? 1.0 : 0.0),
            duration: reduceMotion
                ? Duration.zero
                : MemoryMatchTheme.flipDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, t, _) {
              final angle = t * math.pi;
              final showFace = t >= 0.5;
              final lift = math.sin(t * math.pi) * 8;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..translateByDouble(0, -lift, lift * 0.4, 1)
                  ..rotateY(angle),
                child: showFace
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _CardImage(
                          asset: face.asset,
                          accent: face.color,
                          matched: card.isMatched,
                          highlighted: highlighted,
                        ),
                      )
                    : _CardImage(
                        asset: MemoryMatchTheme.cardBackAsset,
                        accent: MemoryMatchTheme.back,
                        matched: false,
                        highlighted: highlighted,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.asset,
    required this.accent,
    required this.matched,
    required this.highlighted,
  });

  final String asset;
  final Color accent;
  final bool matched;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final rim = matched || highlighted ? MemoryMatchTheme.match : accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          if (matched || highlighted)
            BoxShadow(
              color: MemoryMatchTheme.match.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: MemoryMatchTheme.face,
                child: Icon(Icons.broken_image_outlined, color: accent),
              ),
            ),
            // Soft gloss.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-0.9, -1),
                    end: const Alignment(0.5, 0.4),
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.14),
                    ],
                    stops: const [0.0, 0.22, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Accent rim.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: rim.withValues(alpha: matched ? 0.95 : 0.55),
                    width: matched || highlighted ? 3 : 2,
                  ),
                ),
              ),
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
