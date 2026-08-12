import 'package:flutter/material.dart';

import 'games/block_race/block_race_config.dart';
import 'games/block_race/block_race_play_screen.dart';
import 'games/block_race/block_race_setup_screen.dart';
import 'games/casino/casino_config.dart';
import 'games/casino/casino_play_screen.dart';
import 'games/casino/casino_setup_screen.dart';
import 'games/checkers/checkers_config.dart';
import 'games/checkers/checkers_play_screen.dart';
import 'games/checkers/checkers_setup_screen.dart';
import 'games/connect_four/connect_four_setup_screen.dart';
import 'games/ludo/ludo_config.dart';
import 'games/ludo/ludo_play_screen.dart';
import 'games/ludo/ludo_setup_screen.dart';
import 'games/stack/stack_play_screen.dart';
import 'games/sudoku/sudoku_config.dart';
import 'games/sudoku/sudoku_play_screen.dart';
import 'games/sudoku/sudoku_setup_screen.dart';
import 'games/tic_tac_toe/tic_tac_toe_config.dart';
import 'games/tic_tac_toe/tic_tac_toe_play_screen.dart';
import 'games/tic_tac_toe/tic_tac_toe_setup_screen.dart';
import 'models/game.dart';
import 'screens/play_game_screen.dart';

void openPlay(BuildContext context, Game game) {
  final Widget screen = switch (game.id) {
    'block_race' => const BlockRaceSetupScreen(),
    'checkers' => const CheckersSetupScreen(),
    'connect_four' => const ConnectFourSetupScreen(),
    'ludo' => const LudoSetupScreen(),
    'stack' => const StackPlayScreen(),
    'sudoku' => const SudokuSetupScreen(),
    'casino' => const CasinoSetupScreen(),
    'tic_tac_toe' => const TicTacToeSetupScreen(),
    _ => PlayGameScreen(game: game),
  };

  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Builds the in-game (play) screen for [gameId] with default settings.
/// Used by the `?game=` deep link to jump straight into gameplay
/// (e.g. for store screenshots). Returns null for unknown ids.
Widget? buildGamePlayScreen(String gameId, {bool demo = false}) {
  return switch (gameId) {
    'block_race' => BlockRacePlayScreen(
        config: const BlockRaceConfig(),
        demo: demo,
      ),
    'checkers' => const CheckersPlayScreen(config: CheckersConfig()),
    'ludo' => const LudoPlayScreen(config: LudoConfig()),
    'stack' => StackPlayScreen(demoTower: demo),
    'sudoku' => const SudokuPlayScreen(
        config: SudokuConfig(
          mode: SudokuPlayMode.freePlay,
          difficulty: SudokuDifficulty.medium,
        ),
      ),
    'casino' => const CasinoPlayScreen(config: CasinoConfig()),
    'tic_tac_toe' => const TicTacToePlayScreen(config: TicTacToeConfig()),
    _ => null,
  };
}
