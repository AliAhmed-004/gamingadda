import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/memory_match/memory_match_config.dart';
import 'package:gaming_adda/games/memory_match/memory_match_levels.dart';
import 'package:gaming_adda/games/memory_match/memory_match_logic.dart';

void main() {
  group('MemoryMatchLevels', () {
    test('has 365 levels with growing pairs', () {
      expect(MemoryMatchLevels.maxLevel, 365);
      expect(MemoryMatchLevels.pairsFor(1), 2);
      expect(MemoryMatchLevels.pairsFor(365), MemoryMatchLevels.maxPairs);
      expect(
        MemoryMatchLevels.pairsFor(100),
        lessThan(MemoryMatchLevels.pairsFor(300)),
      );
    });

    test('columns keep an even card count', () {
      for (var level = 1; level <= MemoryMatchLevels.maxLevel; level++) {
        final pairs = MemoryMatchLevels.pairsFor(level);
        final cols = MemoryMatchLevels.columnsFor(pairs);
        expect(pairs * 2 % cols, 0, reason: 'level $level');
        expect(cols, inInclusiveRange(2, 6));
      }
    });

    test('campaign specs include move limits and seeds', () {
      final easy = MemoryMatchLevels.specForLevel(1);
      final hard = MemoryMatchLevels.specForLevel(365);
      expect(easy.pairs, 2);
      expect(easy.peekDuration, isNotNull);
      expect(easy.moveLimit, isNotNull);
      expect(hard.pairs, MemoryMatchLevels.maxPairs);
      expect(hard.peekDuration, isNull);
      expect(hard.mismatchDelay.inMilliseconds,
          lessThan(easy.mismatchDelay.inMilliseconds));
    });

    test('free-play difficulties map to fixed pair counts', () {
      expect(
        MemoryMatchLevels.specForDifficulty(MemoryMatchDifficulty.easy).pairs,
        4,
      );
      expect(
        MemoryMatchLevels.specForDifficulty(MemoryMatchDifficulty.medium)
            .pairs,
        8,
      );
      expect(
        MemoryMatchLevels.specForDifficulty(MemoryMatchDifficulty.hard).pairs,
        12,
      );
    });

    test('tiers cover 1–365 without gaps', () {
      expect(MemoryMatchLevels.tiers.first.start, 1);
      expect(MemoryMatchLevels.tiers.last.end, 365);
      for (var i = 1; i < MemoryMatchLevels.tiers.length; i++) {
        expect(
          MemoryMatchLevels.tiers[i].start,
          MemoryMatchLevels.tiers[i - 1].end + 1,
        );
      }
    });
  });

  group('MemoryMatchGame', () {
    test('deals two of each pair id', () {
      final game = MemoryMatchGame(pairs: 4, seed: 7);
      expect(game.cards.length, 8);
      final counts = <int, int>{};
      for (final c in game.cards) {
        counts[c.pairId] = (counts[c.pairId] ?? 0) + 1;
      }
      expect(counts.values.every((n) => n == 2), isTrue);
    });

    test('seeded shuffle is deterministic', () {
      final a = MemoryMatchGame(pairs: 6, seed: 99);
      final b = MemoryMatchGame(pairs: 6, seed: 99);
      expect(
        a.cards.map((c) => c.pairId).toList(),
        b.cards.map((c) => c.pairId).toList(),
      );
    });

    test('matching a pair keeps both cards face up', () {
      final game = MemoryMatchGame(pairs: 2, seed: 1);
      final pairId = game.cards.first.pairId;
      final indexes = [
        for (var i = 0; i < game.cards.length; i++)
          if (game.cards[i].pairId == pairId) i,
      ];
      expect(indexes.length, 2);

      expect(game.flip(indexes[0]).outcome, MemoryFlipOutcome.flipped);
      final second = game.flip(indexes[1]);
      expect(second.outcome, MemoryFlipOutcome.matched);
      expect(game.matches, 1);
      expect(game.cards[indexes[0]].isMatched, isTrue);
      expect(game.cards[indexes[1]].isMatched, isTrue);
    });

    test('mismatch locks input until resolved', () {
      final game = MemoryMatchGame(pairs: 3, seed: 3);
      // Find two cards with different pair ids.
      var first = 0;
      var second = 1;
      for (var i = 1; i < game.cards.length; i++) {
        if (game.cards[i].pairId != game.cards[0].pairId) {
          second = i;
          break;
        }
      }

      expect(game.flip(first).outcome, MemoryFlipOutcome.flipped);
      final miss = game.flip(second);
      expect(miss.outcome, MemoryFlipOutcome.mismatched);
      expect(game.inputLocked, isTrue);
      expect(game.flip(0).outcome, MemoryFlipOutcome.ignored);

      game.resolveMismatch(miss.firstIndex!, miss.secondIndex!);
      expect(game.inputLocked, isFalse);
      expect(game.cards[first].state, MemoryCardState.faceDown);
      expect(game.cards[second].state, MemoryCardState.faceDown);
    });

    test('clearing all pairs wins', () {
      final game = MemoryMatchGame(pairs: 2, seed: 5);
      for (var pair = 0; pair < 2; pair++) {
        final indexes = [
          for (var i = 0; i < game.cards.length; i++)
            if (game.cards[i].pairId == pair &&
                game.cards[i].state == MemoryCardState.faceDown)
              i,
        ];
        game.flip(indexes[0]);
        final result = game.flip(indexes[1]);
        if (pair == 1) {
          expect(result.outcome, MemoryFlipOutcome.won);
        }
      }
      expect(game.isWon, isTrue);
    });

    test('move limit can lose the round', () {
      final game = MemoryMatchGame(pairs: 3, seed: 11, moveLimit: 1);
      var a = 0;
      var b = 1;
      for (var i = 1; i < game.cards.length; i++) {
        if (game.cards[i].pairId != game.cards[0].pairId) {
          b = i;
          break;
        }
      }
      game.flip(a);
      final result = game.flip(b);
      expect(result.outcome, MemoryFlipOutcome.lost);
      expect(game.lost, isTrue);
      expect(game.isOver, isTrue);
    });
  });
}
