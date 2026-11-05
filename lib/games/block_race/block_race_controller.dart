import 'dart:async';

import 'package:flutter/foundation.dart';

import 'block_race_ai.dart';
import 'block_race_config.dart';
import 'block_race_logic.dart';
import 'block_race_sounds.dart';
import 'block_race_theme.dart';

/// Orchestrates game logic, input, and AI for Barricade Clash.
///
/// The board renders directly from [game] state with implicit animations,
/// so the controller only needs to pace turns with short delays that match
/// the board's animation durations. Every state change notifies listeners,
/// which makes a stale-busy deadlock impossible.
class BlockRaceGameController extends ChangeNotifier {
  BlockRaceGameController({
    required this.config,
    bool autoStart = true,
    this.sounds,
  }) {
    _ai = BlockRaceAi(difficulty: config.difficulty);
    if (autoStart) startGame();
  }

  final BlockRaceConfig config;

  /// Optional SFX; owned by the screen, not disposed here.
  final BlockRaceSounds? sounds;
  late final BlockRaceAi _ai;
  final BlockRaceGame _game = BlockRaceGame();

  /// Who placed each wall, for coloring.
  final Map<Wall, BlockRacePlayer> wallOwners = {};

  bool _busy = false;
  bool _disposed = false;

  BlockRaceGame get game => _game;
  bool get isBusy => _busy;

  /// Human plays Red (bottom). Blue is AI in vs-computer mode.
  bool get isHumanTurn {
    if (config.mode == BlockRacePlayMode.localTwoPlayer) return true;
    return _game.currentPlayer == BlockRacePlayer.red;
  }

  void startGame() {
    if (_busy) return;
    _game.startGame();
    wallOwners.clear();
    _notify();
    _maybeRunAiTurn();
  }

  void toggleWallOrientation() {
    if (!isHumanTurn || _busy) return;
    _game.toggleWallOrientation();
    _notify();
  }

  void setWallOrientation(WallOrientation orientation) {
    if (!isHumanTurn || _busy) return;
    _game.setWallOrientation(orientation);
    _notify();
  }

  Future<void> onCellTap(BoardPos cell) async {
    if (_busy || _game.phase != BlockRacePhase.choosing || !isHumanTurn) {
      return;
    }
    await applyMove(cell);
  }

  Future<void> onWallTap(Wall wall) async {
    if (_busy || _game.phase != BlockRacePhase.choosing || !isHumanTurn) {
      return;
    }
    await placeWall(wall);
  }

  /// Keyboard / D-pad movement relative to the current pawn.
  Future<void> moveByDelta(int dRow, int dCol) async {
    if (_busy || _game.phase != BlockRacePhase.choosing || !isHumanTurn) {
      return;
    }
    final from = _game.positionOf(_game.currentPlayer);
    final to = BoardPos(from.row + dRow, from.col + dCol);
    if (_game.legalMoves().contains(to)) {
      await applyMove(to);
    }
  }

  Future<void> applyMove(BoardPos to) async {
    if (_busy || _game.phase != BlockRacePhase.choosing) return;
    final result = _game.applyMove(to);
    if (result == null) return;
    unawaited(result.won ? sounds?.win() : sounds?.move());

    _busy = true;
    _notify();
    await _wait(BlockRaceTheme.moveDuration + const Duration(milliseconds: 20));

    _busy = false;
    if (result.won) {
      _notify();
      return;
    }
    _game.finishAnimations();
    _notify();
    await _maybeRunAiTurn();
  }

  Future<void> placeWall(Wall wall) async {
    if (_busy || _game.phase != BlockRacePhase.choosing) return;
    final placer = _game.currentPlayer;
    if (!_game.placeWall(wall)) return;
    wallOwners[wall] = placer;
    unawaited(sounds?.wall());

    _busy = true;
    _notify();
    await _wait(BlockRaceTheme.wallDuration + const Duration(milliseconds: 20));

    _busy = false;
    _game.finishAnimations();
    _notify();
    await _maybeRunAiTurn();
  }

  Future<void> _maybeRunAiTurn() async {
    if (_disposed) return;
    if (_game.phase != BlockRacePhase.choosing || isHumanTurn) return;

    await _wait(BlockRaceTheme.aiThinkDuration);
    if (_game.phase != BlockRacePhase.choosing || isHumanTurn || _busy) {
      return;
    }

    final choice = _ai.choose(_game);
    if (choice.isMove && choice.move != null) {
      await applyMove(choice.move!);
    } else if (choice.isWall && choice.wall != null) {
      await placeWall(choice.wall!);
    }

    // Safety net: never leave the game frozen on the computer's turn.
    if (_game.phase == BlockRacePhase.choosing && !isHumanTurn && !_busy) {
      final moves = _game.legalMoves();
      if (moves.isNotEmpty) {
        await applyMove(moves.first);
      }
    }
    if (_game.phase == BlockRacePhase.choosing && !isHumanTurn && !_busy) {
      _game.phase = BlockRacePhase.animating;
      _game.finishAnimations();
      _notify();
    }
  }

  /// Drives the tutorial/demo: plays one move for the current human player.
  Future<void> runDemoMove() async {
    if (_game.phase == BlockRacePhase.gameOver) return;
    if (_game.phase == BlockRacePhase.choosing && isHumanTurn && !_busy) {
      final moves = _game.legalMoves();
      if (moves.isNotEmpty) {
        await applyMove(moves.first);
      }
    }
  }

  Future<void> _wait(Duration duration) async {
    await Future<void>.delayed(duration);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
