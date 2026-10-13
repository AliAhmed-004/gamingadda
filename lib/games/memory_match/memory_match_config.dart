enum MemoryMatchPlayMode { campaign, freePlay }

enum MemoryMatchDifficulty { easy, medium, hard }

class MemoryMatchConfig {
  const MemoryMatchConfig({
    this.mode = MemoryMatchPlayMode.campaign,
    this.soundEnabled = true,
    this.level,
    this.difficulty,
  });

  final MemoryMatchPlayMode mode;
  final bool soundEnabled;

  /// Campaign level (1-based); null in free play.
  final int? level;

  /// Free-play difficulty; null in campaign.
  final MemoryMatchDifficulty? difficulty;

  bool get isCampaign => mode == MemoryMatchPlayMode.campaign;
  bool get isFreePlay => mode == MemoryMatchPlayMode.freePlay;
}
