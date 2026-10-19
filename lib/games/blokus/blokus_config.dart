import 'blokus_logic.dart';

enum BlokusPlayMode { vsComputer, localHotseat }

class BlokusConfig {
  const BlokusConfig({
    this.playerCount = 4,
    this.mode = BlokusPlayMode.vsComputer,
    this.humanColor = BlokusColor.blue,
    this.soundEnabled = true,
  });

  final int playerCount;
  final BlokusPlayMode mode;
  final BlokusColor humanColor;
  final bool soundEnabled;

  bool get isVsComputer => mode == BlokusPlayMode.vsComputer;
  bool get isLocalHotseat => mode == BlokusPlayMode.localHotseat;

  List<BlokusColor> get activeColors =>
      activeColorsForPlayerCount(playerCount);

  /// Colors controlled by the human seat (2p owns a diagonal pair).
  Set<BlokusColor> get humanColors =>
      colorsOwnedBySeat(humanColor, playerCount);

  bool isHumanTurn(BlokusColor turn) {
    if (isLocalHotseat) return true;
    return humanColors.contains(turn);
  }
}
