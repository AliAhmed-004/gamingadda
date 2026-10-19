import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'blokus_config.dart';
import 'blokus_logic.dart';
import 'blokus_play_screen.dart';
import 'blokus_theme.dart';

class BlokusSetupScreen extends StatefulWidget {
  const BlokusSetupScreen({super.key});

  @override
  State<BlokusSetupScreen> createState() => _BlokusSetupScreenState();
}

class _BlokusSetupScreenState extends State<BlokusSetupScreen> {
  var _playerCount = 4;
  var _mode = BlokusPlayMode.vsComputer;
  var _humanColor = BlokusColor.blue;
  var _soundEnabled = true;

  List<BlokusColor> get _seatChoices =>
      seatChoicesForPlayerCount(_playerCount);

  void _setPlayerCount(int n) {
    setState(() {
      _playerCount = n;
      if (!_seatChoices.contains(_humanColor)) {
        _humanColor = _seatChoices.first;
      }
    });
  }

  void _startGame() {
    final config = BlokusConfig(
      playerCount: _playerCount,
      mode: _mode,
      humanColor: _humanColor,
      soundEnabled: _soundEnabled,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BlokusPlayScreen(config: config)),
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
            'Each player has 21 polyomino pieces. Place your first piece on '
            'your corner square. Later pieces must touch your own color by a '
            'corner only — never share an edge with yourself. Block opponents '
            'and place as many squares as you can. Highest score wins. '
            'In 2-player, each seat plays two diagonal colors.',
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
    if (_mode == BlokusPlayMode.vsComputer) {
      if (_playerCount == 2) {
        final other = _humanColor == BlokusColor.blue
            ? 'Yellow+Green'
            : 'Blue+Red';
        return 'You play ${_humanColor == BlokusColor.blue ? 'Blue+Red' : 'Yellow+Green'}; AI plays $other.';
      }
      return 'You play as ${_humanColor.label}; other seats are AI.';
    }
    return 'Pass-and-play on this device. Blue places first.';
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
              final maxPanel = constraints.maxWidth.clamp(280.0, 420.0);

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 12 : 20,
                    vertical: CartoonTheme.spaceLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: narrow ? 88 : 104,
                        height: narrow ? 88 : 104,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C3D4A), Color(0xFF071E28)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _BlokusIconPainter(),
                        ),
                      ),
                      const SizedBox(height: CartoonTheme.spaceMd),
                      Text(
                        'BLOKUS',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CartoonTheme.spaceLg),
                      CartoonPanel(
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
                                'PLAYERS',
                                textAlign: TextAlign.center,
                                style: CartoonTheme.sectionLabel(),
                              ),
                            ),
                            const SizedBox(height: CartoonTheme.spaceSm),
                            Row(
                              children: [
                                for (final n in const [2, 3, 4]) ...[
                                  if (n != 2) const SizedBox(width: 8),
                                  Expanded(
                                    child: CartoonPillButton(
                                      label: '$n',
                                      height: pillHeight,
                                      selected: _playerCount == n,
                                      onTap: () => _setPlayerCount(n),
                                    ),
                                  ),
                                ],
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
                              selected: _mode == BlokusPlayMode.vsComputer,
                              onTap: () => setState(
                                () => _mode = BlokusPlayMode.vsComputer,
                              ),
                            ),
                            const SizedBox(height: CartoonTheme.spaceMd),
                            CartoonPillButton(
                              icon: Icons.people_outline,
                              label: 'Local Hotseat',
                              height: pillHeight,
                              selected: _mode == BlokusPlayMode.localHotseat,
                              onTap: () => setState(
                                () => _mode = BlokusPlayMode.localHotseat,
                              ),
                            ),
                            if (_mode == BlokusPlayMode.vsComputer) ...[
                              const SizedBox(height: CartoonTheme.spaceXl),
                              Semantics(
                                header: true,
                                child: Text(
                                  _playerCount == 2 ? 'YOUR SEAT' : 'YOUR COLOR',
                                  textAlign: TextAlign.center,
                                  style: CartoonTheme.sectionLabel(),
                                ),
                              ),
                              const SizedBox(height: CartoonTheme.spaceSm),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final c in _seatChoices)
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _humanColor = c),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: BlokusTheme.face(c),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _humanColor == c
                                                ? Colors.white
                                                : Colors.black26,
                                            width: _humanColor == c ? 3 : 1,
                                          ),
                                          boxShadow: _humanColor == c
                                              ? [
                                                  BoxShadow(
                                                    color: BlokusTheme.face(c)
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
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
                    ],
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

class _BlokusIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 6;
    final pieces = <(Color, List<Offset>)>[
      (
        BlokusTheme.face(BlokusColor.blue),
        [Offset(1, 1), Offset(1, 2), Offset(2, 1)],
      ),
      (
        BlokusTheme.face(BlokusColor.yellow),
        [Offset(3.5, 1), Offset(4.5, 1), Offset(4.5, 2)],
      ),
      (
        BlokusTheme.face(BlokusColor.red),
        [Offset(3.5, 3.5), Offset(4.5, 3.5), Offset(4.5, 4.5)],
      ),
      (
        BlokusTheme.face(BlokusColor.green),
        [Offset(1, 3.5), Offset(1, 4.5), Offset(2, 4.5)],
      ),
    ];
    for (final (color, cells) in pieces) {
      for (final o in cells) {
        final rect = Rect.fromLTWH(
          o.dx * unit,
          o.dy * unit,
          unit * 0.9,
          unit * 0.9,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.shift(const Offset(1, 2)), const Radius.circular(3)),
          Paint()..color = Color.lerp(color, Colors.black, 0.35)!,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
