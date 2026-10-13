import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'block_race_config.dart';
import 'block_race_play_screen.dart';

class BlockRaceSetupScreen extends StatefulWidget {
  const BlockRaceSetupScreen({super.key});

  @override
  State<BlockRaceSetupScreen> createState() => _BlockRaceSetupScreenState();
}

class _BlockRaceSetupScreenState extends State<BlockRaceSetupScreen> {
  var _mode = BlockRacePlayMode.vsComputer;
  var _difficulty = BlockRaceAiDifficulty.medium;
  var _soundEnabled = true;

  void _startGame() {
    final config = BlockRaceConfig(
      mode: _mode,
      difficulty: _difficulty,
      soundEnabled: _soundEnabled,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlockRacePlayScreen(config: config),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            'How to play',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Barricade Clash is played on a 9×9 grid. You are Red at the '
            'bottom; reach the top row to win. Each turn, either move one '
            'step (tap a glowing cell or use the arrow pad) or place a wall '
            '(tap "Place wall", then tap a green bar between cells). Walls '
            'block movement for both players but can never fully seal anyone '
            'off. Jump straight over your rival when they stand next to you. '
            'Each player gets 10 walls — first to the far side wins!',
            style: GoogleFonts.nunito(height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(backgroundColor: scheme.primary),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  String get _modeHint {
    if (_mode == BlockRacePlayMode.localTwoPlayer) {
      return 'Pass-and-play. Red goes first.';
    }
    return switch (_difficulty) {
      BlockRaceAiDifficulty.easy =>
        'You are Red. AI makes occasional mistakes.',
      BlockRaceAiDifficulty.medium => 'You are Red. AI blocks key paths.',
      BlockRaceAiDifficulty.hard => 'You are Red. AI plays aggressively.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/bg_jungle.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final circleSize = narrow ? 48.0 : 56.0;
              final pillHeight = narrow ? 48.0 : 52.0;
              final maxPanel = constraints.maxWidth.clamp(280.0, 400.0);

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 12 : 20,
                    vertical: CartoonTheme.spaceLg,
                  ),
                  child: CartoonPanel(
                    title: 'BARRICADE CLASH',
                    maxWidth: maxPanel,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'QUICK',
                            textAlign: TextAlign.center,
                            style: CartoonTheme.sectionLabel(),
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceSm),
                        Row(
                          children: [
                            Expanded(
                              child: CartoonCircleButton(
                                icon: _soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                label: 'Sound',
                                size: circleSize,
                                enabled: _soundEnabled,
                                semanticHint: _soundEnabled
                                    ? 'Sound on. Tap to mute.'
                                    : 'Sound off. Tap to unmute.',
                                asset: _soundEnabled
                                    ? CartoonAssets.btnCircleGreen
                                    : CartoonAssets.btnCircleOff,
                                onTap: () => setState(
                                  () => _soundEnabled = !_soundEnabled,
                                ),
                              ),
                            ),
                            Expanded(
                              child: CartoonCircleButton(
                                icon: Icons.help_outline_rounded,
                                label: 'Help',
                                size: circleSize,
                                semanticHint: 'Show how to play',
                                onTap: _showHelp,
                              ),
                            ),
                            Expanded(
                              child: CartoonCircleButton(
                                icon: Icons.home_rounded,
                                label: 'Home',
                                size: circleSize,
                                asset: CartoonAssets.btnCircleBlue,
                                semanticHint: 'Return to game store',
                                onTap: _goHome,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: CartoonTheme.spaceXl),
                        Semantics(
                          header: true,
                          child: Text(
                            'MODE',
                            textAlign: TextAlign.center,
                            style: CartoonTheme.sectionLabel(),
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceSm),
                        CartoonPillButton(
                          icon: Icons.smart_toy_outlined,
                          label: 'Vs Computer',
                          height: pillHeight,
                          selected: _mode == BlockRacePlayMode.vsComputer,
                          onTap: () => setState(
                            () => _mode = BlockRacePlayMode.vsComputer,
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceMd),
                        CartoonPillButton(
                          icon: Icons.people_outline,
                          label: '2 Players',
                          height: pillHeight,
                          selected: _mode == BlockRacePlayMode.localTwoPlayer,
                          onTap: () => setState(
                            () => _mode = BlockRacePlayMode.localTwoPlayer,
                          ),
                        ),
                        if (_mode == BlockRacePlayMode.vsComputer) ...[
                          const SizedBox(height: CartoonTheme.spaceXl),
                          Semantics(
                            header: true,
                            child: Text(
                              'DIFFICULTY',
                              textAlign: TextAlign.center,
                              style: CartoonTheme.sectionLabel(),
                            ),
                          ),
                          const SizedBox(height: CartoonTheme.spaceSm),
                          CartoonPillButton(
                            icon: Icons.sentiment_satisfied_alt_outlined,
                            label: 'Easy',
                            height: pillHeight,
                            selected: _difficulty == BlockRaceAiDifficulty.easy,
                            onTap: () => setState(
                              () => _difficulty = BlockRaceAiDifficulty.easy,
                            ),
                          ),
                          const SizedBox(height: CartoonTheme.spaceMd),
                          CartoonPillButton(
                            icon: Icons.sentiment_neutral_outlined,
                            label: 'Medium',
                            height: pillHeight,
                            selected:
                                _difficulty == BlockRaceAiDifficulty.medium,
                            onTap: () => setState(
                              () => _difficulty = BlockRaceAiDifficulty.medium,
                            ),
                          ),
                          const SizedBox(height: CartoonTheme.spaceMd),
                          CartoonPillButton(
                            icon: Icons.sentiment_very_dissatisfied_outlined,
                            label: 'Hard',
                            height: pillHeight,
                            selected: _difficulty == BlockRaceAiDifficulty.hard,
                            onTap: () => setState(
                              () => _difficulty = BlockRaceAiDifficulty.hard,
                            ),
                          ),
                        ],
                        const SizedBox(height: CartoonTheme.spaceSm),
                        Text(
                          _modeHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: CartoonTheme.woodMuted,
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceXl),
                        CartoonPillButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Start Game',
                          height: pillHeight + 4,
                          isPrimary: true,
                          asset: CartoonAssets.btnPillGold,
                          onTap: _startGame,
                        ),
                        const SizedBox(height: CartoonTheme.spaceMd),
                        CartoonPillButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Back',
                          height: pillHeight,
                          asset: CartoonAssets.btnPillRed,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
