import 'dart:math';

import 'blokus_logic.dart';
import 'blokus_pieces.dart';

/// Greedy heuristic placer for Blokus.
class BlokusAi {
  BlokusAi({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Returns a legal placement or null if the AI should pass.
  BlokusPlacement? choosePlacement(BlokusGame game) {
    final color = game.turn;
    final remaining = game.remaining[color];
    if (remaining == null || remaining.isEmpty) return null;

    final candidates = _candidatePlacements(game, color);
    if (candidates.isEmpty) return null;

    BlokusPlacement? best;
    var bestScore = -1e9;
    for (final p in candidates) {
      final noisy = _score(game, p) + _random.nextDouble() * 0.15;
      if (noisy > bestScore) {
        bestScore = noisy;
        best = p;
      }
    }
    return best;
  }

  List<BlokusPlacement> _candidatePlacements(
    BlokusGame game,
    BlokusColor color,
  ) {
    final remaining = game.remaining[color]!;
    final ordered = remaining.toList()
      ..sort(
        (a, b) =>
            BlokusPieces.byId(b).size.compareTo(BlokusPieces.byId(a).size),
      );

    final anchors = <BlokusCell>{};
    final first = !(game.hasPlaced[color] ?? false);
    if (first) {
      anchors.add(cornerFor(color));
    } else {
      for (var r = 0; r < BlokusGame.boardSize; r++) {
        for (var c = 0; c < BlokusGame.boardSize; c++) {
          if (game.board[r][c] != color) continue;
          for (final d in const [
            BlokusCell(-1, -1),
            BlokusCell(-1, 1),
            BlokusCell(1, -1),
            BlokusCell(1, 1),
          ]) {
            final n = BlokusCell(r, c) + d;
            if (game.inBounds(n) && game.board[n.row][n.col] == null) {
              anchors.add(n);
            }
          }
        }
      }
    }

    final out = <BlokusPlacement>[];
    const maxCandidates = 80;

    for (final id in ordered) {
      final orients = game.orientationsOf(id);
      final before = out.length;
      for (var oi = 0; oi < orients.length; oi++) {
        final orient = orients[oi];
        for (final anchor in anchors) {
          for (var ci = 0; ci < orient.length; ci++) {
            final p = game.placementAtAnchor(
              color: color,
              pieceId: id,
              orientationIndex: oi,
              anchor: anchor,
              cellIndex: ci,
            );
            if (p != null && game.isLegalPlacement(p)) {
              out.add(p);
              if (out.length >= maxCandidates) return out;
            }
          }
        }
      }
      // Prefer keeping large-piece options; stop after a few sizes if we have enough.
      if (out.length - before > 0 &&
          BlokusPieces.byId(id).size >= 4 &&
          out.length >= 24) {
        break;
      }
    }

    if (out.length > 40) {
      out.shuffle(_random);
      return out.take(40).toList();
    }
    return out;
  }

  double _score(BlokusGame game, BlokusPlacement p) {
    final cells = p.cells.length.toDouble();
    var cornerAdj = 0;
    var edgeExposure = 0;
    var center = 0.0;
    const mid = (BlokusGame.boardSize - 1) / 2.0;

    for (final c in p.cells) {
      center += 1.0 - ((c.row - mid).abs() + (c.col - mid).abs()) / (mid * 2);

      for (final d in const [
        BlokusCell(-1, -1),
        BlokusCell(-1, 1),
        BlokusCell(1, -1),
        BlokusCell(1, 1),
      ]) {
        final n = c + d;
        if (game.at(n) == p.color) cornerAdj++;
      }
      for (final d in const [
        BlokusCell(-1, 0),
        BlokusCell(1, 0),
        BlokusCell(0, -1),
        BlokusCell(0, 1),
      ]) {
        final n = c + d;
        final occ = game.at(n);
        if (occ != null && occ != p.color) edgeExposure++;
      }
    }

    return cells + 0.3 * cornerAdj - 0.2 * edgeExposure + 0.15 * center;
  }
}
