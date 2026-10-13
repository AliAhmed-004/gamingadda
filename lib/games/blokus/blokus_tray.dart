import 'package:flutter/material.dart';

import 'blokus_board.dart';
import 'blokus_logic.dart';
import 'blokus_pieces.dart';
import 'blokus_theme.dart';

class BlokusTray extends StatelessWidget {
  const BlokusTray({
    super.key,
    required this.game,
    required this.color,
    required this.selectedPieceId,
    required this.onSelect,
    this.enabled = true,
  });

  final BlokusGame game;
  final BlokusColor color;
  final String? selectedPieceId;
  final ValueChanged<String> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final remaining = game.remaining[color] ?? {};
    final pieces = BlokusPieces.all
        .where((p) => remaining.contains(p.id))
        .toList()
      ..sort((a, b) => b.size.compareTo(a.size));

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BlokusTheme.face(color).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: pieces.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, i) {
            final p = pieces[i];
            final selected = p.id == selectedPieceId;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: enabled ? () => onSelect(p.id) : null,
                child: AnimatedContainer(
                  duration: BlokusTheme.placePopDuration,
                  width: selected ? 56 : 48,
                  height: selected ? 60 : 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? BlokusTheme.face(color).withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: BlokusPieceSilhouette(
                    cells: p.cells,
                    color: color,
                    selected: selected,
                    size: selected ? 48 : 40,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
