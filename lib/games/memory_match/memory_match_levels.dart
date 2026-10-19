import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'memory_match_config.dart';

/// Difficulty curve for the 365-level campaign.
///
/// Starts at a full easy grid (9 pairs) and climbs to 18 pairs. Later levels
/// peek less, flip mismatches back faster, and tighten the move budget.
abstract final class MemoryMatchLevels {
  static const int maxLevel = 365;
  static const int maxPairs = 18;

  /// Pair counts that tile cleanly; campaign begins at the Easy 9-pair grid.
  static const _pairSteps = [9, 10, 12, 15, 18];

  /// Number of unique pairs for [level] (1-based).
  static int pairsFor(int level) {
    final t = ((level - 1) / (maxLevel - 1)).clamp(0.0, 1.0);
    // Ease-out so mid/late campaign ramps into bigger boards sooner.
    final eased = pow(t, 0.65).toDouble();
    final idx = (eased * (_pairSteps.length - 1)).round();
    return _pairSteps[idx];
  }

  /// Grid column count for a given pair count (always divides evenly).
  static int columnsFor(int pairs) {
    final cards = pairs * 2;
    var bestCols = 2;
    var bestScore = double.infinity;
    for (var cols = 2; cols <= 6; cols++) {
      if (cards % cols != 0) continue;
      final rows = cards ~/ cols;
      final score = (rows - cols).abs() + rows * 0.15;
      if (score < bestScore) {
        bestScore = score;
        bestCols = cols;
      }
    }
    return bestCols;
  }

  /// How long mismatched cards stay face-up before flipping back.
  static Duration mismatchDelayFor(int level) {
    final t = ((level - 1) / (maxLevel - 1)).clamp(0.0, 1.0);
    // 1000ms → 320ms — much snappier late game.
    final ms = 1000 - (t * 680).round();
    return Duration(milliseconds: ms);
  }

  /// Brief reveal only on early campaign levels; fades out by level 25.
  static Duration? peekDurationFor(int level) {
    if (level > 25) return null;
    final ms = 1200 - ((level - 1) * 40);
    return Duration(milliseconds: ms.clamp(300, 1200));
  }

  /// Move budget shrinks hard as levels climb.
  static int moveLimitFor(int level) {
    final pairs = pairsFor(level);
    final t = ((level - 1) / (maxLevel - 1)).clamp(0.0, 1.0);
    // Early: ~3.6 attempts/pair; late: ~2.05 attempts/pair.
    final attemptsPerPair = 3.6 - t * 1.55;
    return max(pairs + 1, (pairs * attemptsPerPair).ceil());
  }

  static MemoryMatchLevelSpec specForLevel(int level) {
    final pairs = pairsFor(level);
    return MemoryMatchLevelSpec(
      pairs: pairs,
      columns: columnsFor(pairs),
      mismatchDelay: mismatchDelayFor(level),
      peekDuration: peekDurationFor(level),
      moveLimit: moveLimitFor(level),
      seed: level * 9973 + 42,
    );
  }

  static MemoryMatchLevelSpec specForDifficulty(MemoryMatchDifficulty d) {
    final pairs = switch (d) {
      MemoryMatchDifficulty.easy => 9,
      MemoryMatchDifficulty.medium => 12,
      MemoryMatchDifficulty.hard => 18,
    };
    return MemoryMatchLevelSpec(
      pairs: pairs,
      columns: columnsFor(pairs),
      mismatchDelay: switch (d) {
        MemoryMatchDifficulty.easy => const Duration(milliseconds: 900),
        MemoryMatchDifficulty.medium => const Duration(milliseconds: 650),
        MemoryMatchDifficulty.hard => const Duration(milliseconds: 400),
      },
      peekDuration: switch (d) {
        MemoryMatchDifficulty.easy => const Duration(milliseconds: 1000),
        MemoryMatchDifficulty.medium => const Duration(milliseconds: 500),
        MemoryMatchDifficulty.hard => null,
      },
      moveLimit: null,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static const _tiers = [
    (1, 'Rookie'),
    (50, 'Easy'),
    (100, 'Casual'),
    (150, 'Clever'),
    (200, 'Skilled'),
    (250, 'Expert'),
    (300, 'Master'),
    (350, 'Grandmaster'),
  ];

  static final List<({int start, int end, String name})> tiers = [
    for (var i = 0; i < _tiers.length; i++)
      (
        start: _tiers[i].$1,
        end: i + 1 < _tiers.length ? _tiers[i + 1].$1 - 1 : maxLevel,
        name: _tiers[i].$2,
      ),
  ];

  static String tierName(int level) {
    var name = _tiers.first.$2;
    for (final (start, tier) in _tiers) {
      if (level >= start) name = tier;
    }
    return name;
  }

  static String progressLabel(int level) {
    final pairs = pairsFor(level);
    return '${pairs * 2} cards · ${tierName(level)}';
  }
}

class MemoryMatchLevelSpec {
  const MemoryMatchLevelSpec({
    required this.pairs,
    required this.columns,
    required this.mismatchDelay,
    required this.peekDuration,
    required this.moveLimit,
    required this.seed,
  });

  final int pairs;
  final int columns;
  final Duration mismatchDelay;
  final Duration? peekDuration;
  final int? moveLimit;
  final int seed;
}

/// Campaign progress saved on-device.
abstract final class MemoryMatchProgress {
  static const _unlockedKey = 'memory_match_highest_unlocked';

  static Future<int> highestUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_unlockedKey) ?? 1;
    return value.clamp(1, MemoryMatchLevels.maxLevel);
  }

  static Future<void> completeLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedKey) ?? 1;
    final next = min(level + 1, MemoryMatchLevels.maxLevel);
    if (next > current) {
      await prefs.setInt(_unlockedKey, next);
    }
  }
}
