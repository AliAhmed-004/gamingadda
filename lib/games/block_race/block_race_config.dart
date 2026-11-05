enum BlockRacePlayMode { vsComputer, localTwoPlayer }

enum BlockRaceAiDifficulty { easy, medium, hard }

class BlockRaceConfig {
  const BlockRaceConfig({
    this.mode = BlockRacePlayMode.vsComputer,
    this.difficulty = BlockRaceAiDifficulty.medium,
    this.soundEnabled = true,
  });

  final BlockRacePlayMode mode;
  final BlockRaceAiDifficulty difficulty;
  final bool soundEnabled;
}
