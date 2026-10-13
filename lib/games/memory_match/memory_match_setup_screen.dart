import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'memory_match_config.dart';
import 'memory_match_levels_screen.dart';
import 'memory_match_play_screen.dart';

class MemoryMatchSetupScreen extends StatefulWidget {
  const MemoryMatchSetupScreen({super.key});

  @override
  State<MemoryMatchSetupScreen> createState() => _MemoryMatchSetupScreenState();
}

class _MemoryMatchSetupScreenState extends State<MemoryMatchSetupScreen> {
  var _mode = MemoryMatchPlayMode.campaign;
  var _soundEnabled = true;
  var _difficulty = MemoryMatchDifficulty.medium;

  void _startGame() {
    if (_mode == MemoryMatchPlayMode.campaign) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MemoryMatchLevelsScreen(soundEnabled: _soundEnabled),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryMatchPlayScreen(
          config: MemoryMatchConfig(
            mode: MemoryMatchPlayMode.freePlay,
            soundEnabled: _soundEnabled,
            difficulty: _difficulty,
          ),
        ),
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
            'All cards start face down. Tap one, then another — if the '
            'symbols match they stay up; if not they flip back. Clear every '
            'pair to finish the stage. Campaign has 365 levels that grow '
            'from tiny boards to full grids with tighter move limits.',
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

  String get _modeHint => _mode == MemoryMatchPlayMode.campaign
      ? '365 stages: more cards, shorter peeks, tighter move budgets.'
      : 'Easy = 4 pairs, Medium = 8 pairs, Hard = 12 pairs.';

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
                    title: 'SETTINGS',
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
                          icon: Icons.emoji_events_outlined,
                          label: 'Campaign',
                          height: pillHeight,
                          selected: _mode == MemoryMatchPlayMode.campaign,
                          onTap: () => setState(
                            () => _mode = MemoryMatchPlayMode.campaign,
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceMd),
                        CartoonPillButton(
                          icon: Icons.casino_outlined,
                          label: 'Free Play',
                          height: pillHeight,
                          selected: _mode == MemoryMatchPlayMode.freePlay,
                          onTap: () => setState(
                            () => _mode = MemoryMatchPlayMode.freePlay,
                          ),
                        ),
                        if (_mode == MemoryMatchPlayMode.freePlay) ...[
                          const SizedBox(height: CartoonTheme.spaceMd),
                          Row(
                            children: [
                              for (final d
                                  in MemoryMatchDifficulty.values) ...[
                                if (d != MemoryMatchDifficulty.values.first)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: CartoonPillButton(
                                    label: switch (d) {
                                      MemoryMatchDifficulty.easy => 'Easy',
                                      MemoryMatchDifficulty.medium => 'Med',
                                      MemoryMatchDifficulty.hard => 'Hard',
                                    },
                                    height: pillHeight - 4,
                                    selected: _difficulty == d,
                                    onTap: () =>
                                        setState(() => _difficulty = d),
                                  ),
                                ),
                              ],
                            ],
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
