import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'memory_match_board.dart';
import 'memory_match_config.dart';
import 'memory_match_levels.dart';
import 'memory_match_logic.dart';
import 'memory_match_sounds.dart';
import 'memory_match_theme.dart';

class MemoryMatchPlayScreen extends StatefulWidget {
  const MemoryMatchPlayScreen({super.key, required this.config});

  final MemoryMatchConfig config;

  @override
  State<MemoryMatchPlayScreen> createState() => _MemoryMatchPlayScreenState();
}

class _MemoryMatchPlayScreenState extends State<MemoryMatchPlayScreen> {
  MemoryMatchGame? _game;
  MemoryMatchLevelSpec? _spec;
  late final MemoryMatchSounds _sounds;
  var _elapsed = Duration.zero;
  Timer? _timer;
  Timer? _mismatchTimer;
  Timer? _peekTimer;
  var _winShown = false;
  var _loseShown = false;
  final _highlight = <int>{};

  MemoryMatchConfig get _config => widget.config;

  String get _timerText {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusText {
    final g = _game;
    final spec = _spec;
    if (g == null || spec == null) return 'Shuffling…';
    if (g.isWon) return 'Cleared!';
    if (g.lost) return 'Out of moves';
    if (_config.isCampaign && _config.level != null) {
      return MemoryMatchLevels.progressLabel(_config.level!);
    }
    final d = _config.difficulty;
    if (d == null) return 'Free Play';
    return switch (d) {
      MemoryMatchDifficulty.easy => 'Easy · ${spec.pairs} pairs',
      MemoryMatchDifficulty.medium => 'Medium · ${spec.pairs} pairs',
      MemoryMatchDifficulty.hard => 'Hard · ${spec.pairs} pairs',
    };
  }

  @override
  void initState() {
    super.initState();
    _sounds = MemoryMatchSounds(enabled: _config.soundEnabled);
    _sounds.preload();
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mismatchTimer?.cancel();
    _peekTimer?.cancel();
    _sounds.dispose();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    _mismatchTimer?.cancel();
    _peekTimer?.cancel();

    final spec = _config.isCampaign
        ? MemoryMatchLevels.specForLevel(_config.level ?? 1)
        : MemoryMatchLevels.specForDifficulty(
            _config.difficulty ?? MemoryMatchDifficulty.medium,
          );

    final game = MemoryMatchGame(
      pairs: spec.pairs,
      seed: spec.seed,
      moveLimit: spec.moveLimit,
    );

    setState(() {
      _spec = spec;
      _game = game;
      _elapsed = Duration.zero;
      _winShown = false;
      _loseShown = false;
      _highlight.clear();
    });

    final peek = spec.peekDuration;
    if (peek != null) {
      game.inputLocked = true;
      game.revealAll();
      _peekTimer = Timer(peek, () {
        if (!mounted) return;
        setState(() {
          game.hideUnmatched();
          game.inputLocked = false;
        });
        _startTimer();
      });
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final g = _game;
      if (!mounted || g == null || g.isOver) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _onCardTap(int index) async {
    final g = _game;
    final spec = _spec;
    if (g == null || spec == null) return;

    final result = g.flip(index);
    setState(() {});

    switch (result.outcome) {
      case MemoryFlipOutcome.ignored:
        return;
      case MemoryFlipOutcome.flipped:
        await _sounds.flip();
      case MemoryFlipOutcome.matched:
        await _sounds.match();
        final a = result.firstIndex;
        final b = result.secondIndex;
        if (a != null && b != null) {
          setState(() => _highlight.addAll({a, b}));
          Future<void>.delayed(MemoryMatchTheme.matchPulseDuration, () {
            if (!mounted) return;
            setState(() => _highlight.removeAll({a, b}));
          });
        }
      case MemoryFlipOutcome.won:
        await _sounds.match();
        _timer?.cancel();
        await _sounds.win();
        final level = _config.level;
        if (_config.isCampaign && level != null) {
          await MemoryMatchProgress.completeLevel(level);
        }
        if (!mounted || _winShown) return;
        _winShown = true;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _showWinDialog();
      case MemoryFlipOutcome.mismatched:
        await _sounds.miss();
        final a = result.firstIndex!;
        final b = result.secondIndex!;
        _mismatchTimer?.cancel();
        _mismatchTimer = Timer(spec.mismatchDelay, () {
          if (!mounted) return;
          setState(() => g.resolveMismatch(a, b));
        });
      case MemoryFlipOutcome.lost:
        await _sounds.miss();
        _timer?.cancel();
        if (_loseShown) return;
        _loseShown = true;
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        _showLoseDialog();
    }
  }

  void _showWinDialog() {
    final level = _config.level;
    final campaign = _config.isCampaign && level != null;
    final hasNext = campaign && level < MemoryMatchLevels.maxLevel;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Level cleared',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 280),
      pageBuilder: (ctx, animation, secondary) {
        return _ResultDialog(
          title: campaign ? 'Level $level cleared!' : 'All matched!',
          subtitle: 'Time $_timerText · ${_game?.moves ?? 0} moves',
          accent: MemoryMatchTheme.match,
          actions: [
            if (campaign) ...[
              _DialogAction(label: 'Levels', onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              }),
              _DialogAction(label: 'Replay', onTap: () {
                Navigator.of(ctx).pop();
                _startRound();
              }),
              if (hasNext)
                _DialogAction(
                  label: 'Next',
                  primary: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => MemoryMatchPlayScreen(
                          config: MemoryMatchConfig(
                            mode: MemoryMatchPlayMode.campaign,
                            soundEnabled: _config.soundEnabled,
                            level: level + 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ] else ...[
              _DialogAction(
                label: 'Play again',
                primary: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startRound();
                },
              ),
              _DialogAction(
                label: 'Home',
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ],
        );
      },
      transitionBuilder: (ctx, animation, secondary, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  void _showLoseDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MemoryMatchTheme.panel,
        title: Text(
          'Out of moves',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'You used all ${_spec?.moveLimit ?? 0} moves. Try again and '
          'remember the pairs!',
          style: GoogleFonts.nunito(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Levels'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startRound();
            },
            style: FilledButton.styleFrom(
              backgroundColor: MemoryMatchTheme.glow,
              foregroundColor: const Color(0xFF0F172A),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _game;
    final spec = _spec;
    final title = _config.level != null
        ? 'LEVEL ${_config.level}'
        : 'MEMORY MATCH';

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _startRound,
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.35,
            colors: [Color(0xFF1E3A8A), Color(0xFF0F1D33), Color(0xFF070D18)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 4, 16, 16),
                child: g == null || spec == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      )
                    : Column(
                        children: [
                          Text(
                            _statusText,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              MemoryMatchHudChip(
                                icon: Icons.timer_outlined,
                                label: _timerText,
                                accent: MemoryMatchTheme.glow,
                              ),
                              MemoryMatchHudChip(
                                icon: Icons.swipe_rounded,
                                label: '${g.moves} moves',
                              ),
                              MemoryMatchHudChip(
                                icon: Icons.grid_view_rounded,
                                label: '${g.matches}/${g.pairs}',
                                accent: MemoryMatchTheme.match,
                              ),
                              if (spec.moveLimit != null)
                                MemoryMatchHudChip(
                                  icon: Icons.flag_rounded,
                                  label: '${g.remainingMoves} left',
                                  accent: g.remainingMoves <= 3
                                      ? MemoryMatchTheme.miss
                                      : Colors.white,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Center(
                              child: MemoryMatchBoard(
                                game: g,
                                columns: spec.columns,
                                highlightMatched: _highlight,
                                onTap: _onCardTap,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Flip two cards. Match every pair to clear the stage.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogAction {
  const _DialogAction({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<_DialogAction> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: action.onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: action.primary
                          ? accent
                          : Colors.white.withValues(alpha: 0.15),
                      foregroundColor: action.primary
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      action.label,
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
