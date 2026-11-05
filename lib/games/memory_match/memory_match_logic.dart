import 'dart:math';

enum MemoryCardState { faceDown, faceUp, matched }

enum MemoryFlipOutcome { flipped, matched, mismatched, ignored, won, lost }

class MemoryCard {
  MemoryCard({
    required this.id,
    required this.pairId,
    this.state = MemoryCardState.faceDown,
  });

  final int id;
  final int pairId;
  MemoryCardState state;

  bool get isFaceUp =>
      state == MemoryCardState.faceUp || state == MemoryCardState.matched;
  bool get isMatched => state == MemoryCardState.matched;
}

class MemoryFlipResult {
  const MemoryFlipResult({
    required this.outcome,
    this.firstIndex,
    this.secondIndex,
  });

  final MemoryFlipOutcome outcome;
  final int? firstIndex;
  final int? secondIndex;
}

/// Pure memory-match rules: flip two cards, match pairs, clear the board.
class MemoryMatchGame {
  MemoryMatchGame({
    required this.pairs,
    required this.seed,
    this.moveLimit,
  }) {
    _deal();
  }

  final int pairs;
  final int seed;
  final int? moveLimit;

  late List<MemoryCard> cards;
  int? _openIndex;
  var moves = 0;
  var matches = 0;
  var inputLocked = false;
  var lost = false;

  bool get isWon => matches >= pairs;
  bool get isOver => isWon || lost;
  int get remainingMoves =>
      moveLimit == null ? -1 : max(0, moveLimit! - moves);

  void _deal() {
    final pairIds = List<int>.generate(pairs, (i) => i);
    final deck = <int>[...pairIds, ...pairIds];
    final rng = Random(seed);
    deck.shuffle(rng);
    cards = [
      for (var i = 0; i < deck.length; i++)
        MemoryCard(id: i, pairId: deck[i]),
    ];
    _openIndex = null;
    moves = 0;
    matches = 0;
    inputLocked = false;
    lost = false;
  }

  void reset() => _deal();

  void revealAll() {
    for (final c in cards) {
      if (!c.isMatched) c.state = MemoryCardState.faceUp;
    }
  }

  void hideUnmatched() {
    for (final c in cards) {
      if (!c.isMatched) c.state = MemoryCardState.faceDown;
    }
    _openIndex = null;
  }

  MemoryFlipResult flip(int index) {
    if (isOver || inputLocked) {
      return const MemoryFlipResult(outcome: MemoryFlipOutcome.ignored);
    }
    if (index < 0 || index >= cards.length) {
      return const MemoryFlipResult(outcome: MemoryFlipOutcome.ignored);
    }
    final card = cards[index];
    if (card.state != MemoryCardState.faceDown) {
      return const MemoryFlipResult(outcome: MemoryFlipOutcome.ignored);
    }

    card.state = MemoryCardState.faceUp;

    final open = _openIndex;
    if (open == null) {
      _openIndex = index;
      return MemoryFlipResult(
        outcome: MemoryFlipOutcome.flipped,
        firstIndex: index,
      );
    }

    // Second card of the pair attempt.
    moves += 1;
    _openIndex = null;
    final first = cards[open];

    if (first.pairId == card.pairId) {
      first.state = MemoryCardState.matched;
      card.state = MemoryCardState.matched;
      matches += 1;
      if (isWon) {
        return MemoryFlipResult(
          outcome: MemoryFlipOutcome.won,
          firstIndex: open,
          secondIndex: index,
        );
      }
      return MemoryFlipResult(
        outcome: MemoryFlipOutcome.matched,
        firstIndex: open,
        secondIndex: index,
      );
    }

    if (moveLimit != null && moves >= moveLimit!) {
      lost = true;
      inputLocked = true;
      return MemoryFlipResult(
        outcome: MemoryFlipOutcome.lost,
        firstIndex: open,
        secondIndex: index,
      );
    }

    inputLocked = true;
    return MemoryFlipResult(
      outcome: MemoryFlipOutcome.mismatched,
      firstIndex: open,
      secondIndex: index,
    );
  }

  /// Call after a mismatch delay to flip the two cards face-down again.
  void resolveMismatch(int firstIndex, int secondIndex) {
    if (lost) return;
    final a = cards[firstIndex];
    final b = cards[secondIndex];
    if (!a.isMatched) a.state = MemoryCardState.faceDown;
    if (!b.isMatched) b.state = MemoryCardState.faceDown;
    inputLocked = false;
  }
}
