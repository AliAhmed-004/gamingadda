import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'memory_match_board.dart';
import 'memory_match_config.dart';
import 'memory_match_levels.dart';
import 'memory_match_play_screen.dart';
import 'memory_match_theme.dart';

class MemoryMatchLevelsScreen extends StatefulWidget {
  const MemoryMatchLevelsScreen({super.key, required this.soundEnabled});

  final bool soundEnabled;

  @override
  State<MemoryMatchLevelsScreen> createState() =>
      _MemoryMatchLevelsScreenState();
}

class _MemoryMatchLevelsScreenState extends State<MemoryMatchLevelsScreen>
    with SingleTickerProviderStateMixin {
  static const _columns = 4;
  static const _spacing = 12.0;
  static const _pagePadding = 16.0;
  static const _tierHeaderExtent = 58.0;

  final _scroll = ScrollController();
  late final AnimationController _pulse;
  int? _unlocked;

  static const _tierColors = [
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFF2DD4BF),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
    Color(0xFFF87171),
    Color(0xFFFACC15),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _loadProgress(scrollToCurrent: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadProgress({bool scrollToCurrent = false}) async {
    final unlocked = await MemoryMatchProgress.highestUnlocked();
    if (!mounted) return;
    setState(() => _unlocked = unlocked);
    if (scrollToCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToLevel(unlocked);
      });
    }
  }

  void _jumpToLevel(int level) {
    if (!_scroll.hasClients || !mounted) return;
    final width =
        MediaQuery.of(context).size.width.clamp(0.0, 560.0) - _pagePadding * 2;
    final tile = (width - (_columns - 1) * _spacing) / _columns;
    final rowExtent = tile + _spacing;

    var offset = 0.0;
    for (final tier in MemoryMatchLevels.tiers) {
      final rows = ((tier.end - tier.start + 1) / _columns).ceil();
      if (level > tier.end) {
        offset += _tierHeaderExtent + rows * rowExtent;
      } else {
        offset += _tierHeaderExtent +
            ((level - tier.start) ~/ _columns) * rowExtent;
        break;
      }
    }

    final position = _scroll.position;
    final target = (offset - position.viewportDimension / 3)
        .clamp(0.0, position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  Future<void> _playLevel(int level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryMatchPlayScreen(
          config: MemoryMatchConfig(
            mode: MemoryMatchPlayMode.campaign,
            soundEnabled: widget.soundEnabled,
            level: level,
          ),
        ),
      ),
    );
    if (mounted) {
      await _loadProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'LEVELS',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: unlocked == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _pagePadding,
                          kToolbarHeight + 8,
                          _pagePadding,
                          0,
                        ),
                        child: Column(
                          children: [
                            _ProgressHeader(unlocked: unlocked),
                            const SizedBox(height: 14),
                            Expanded(child: _buildLevelScroller(unlocked)),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelScroller(int unlocked) {
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        for (final (i, tier) in MemoryMatchLevels.tiers.indexed) ...[
          SliverToBoxAdapter(
            child: _TierHeader(
              name: tier.name,
              start: tier.start,
              end: tier.end,
              color: _tierColors[i % _tierColors.length],
              extent: _tierHeaderExtent,
              done: unlocked > tier.end,
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: _spacing,
              crossAxisSpacing: _spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: tier.end - tier.start + 1,
              (context, index) {
                final level = tier.start + index;
                final state = level < unlocked
                    ? _LevelState.completed
                    : level == unlocked
                        ? _LevelState.current
                        : _LevelState.locked;
                return _LevelTile(
                  key: ValueKey('level-$level'),
                  level: level,
                  state: state,
                  accent: _tierColors[i % _tierColors.length],
                  pulse: state == _LevelState.current ? _pulse : null,
                  onTap: level <= unlocked ? () => _playLevel(level) : null,
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.4,
          colors: [Color(0xFF1E3A8A), Color(0xFF0F1D33), Color(0xFF070D18)],
        ),
      ),
      child: Stack(
        children: [
          _blurDisc(
            const Alignment(-1.2, -0.7),
            180,
            MemoryMatchBoard.frameLight.withValues(alpha: 0.14),
          ),
          _blurDisc(
            const Alignment(1.3, -0.2),
            220,
            MemoryMatchBoard.glow.withValues(alpha: 0.10),
          ),
          _blurDisc(
            const Alignment(-1.1, 0.9),
            200,
            MemoryMatchTheme.match.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }

  Widget _blurDisc(Alignment alignment, double size, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.unlocked});

  final int unlocked;

  @override
  Widget build(BuildContext context) {
    final cleared = unlocked - 1;
    final fraction = cleared / MemoryMatchLevels.maxLevel;
    final percent = (fraction * 100).floor();
    final pairs = MemoryMatchLevels.pairsFor(unlocked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 4.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor:
                      const AlwaysStoppedAnimation(MemoryMatchBoard.glow),
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$cleared / ${MemoryMatchLevels.maxLevel} cleared',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unlocked >= MemoryMatchLevels.maxLevel
                      ? 'Final stage awaits'
                      : 'Next up: Level $unlocked · ${pairs * 2} cards',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MemoryMatchBoard.glow.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MemoryMatchBoard.glow.withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              MemoryMatchLevels.tierName(unlocked),
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: MemoryMatchBoard.glow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({
    required this.name,
    required this.start,
    required this.end,
    required this.color,
    required this.extent,
    required this.done,
  });

  final String name;
  final int start;
  final int end;
  final Color color;
  final double extent;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: extent,
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              name.toUpperCase(),
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$start – $end',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            if (done) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: MemoryMatchBoard.glow,
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LevelState { completed, current, locked }

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    super.key,
    required this.level,
    required this.state,
    required this.accent,
    this.pulse,
    this.onTap,
  });

  final int level;
  final _LevelState state;
  final Color accent;
  final Animation<double>? pulse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget slot = switch (state) {
      _LevelState.completed => _DiscFace(
          level: level,
          color: accent,
          badge: const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: MemoryMatchBoard.glow,
          ),
        ),
      _LevelState.current => _buildCurrent(),
      _LevelState.locked => _Hole(level: level),
    };

    return Semantics(
      button: onTap != null,
      label: switch (state) {
        _LevelState.completed => 'Level $level, completed',
        _LevelState.current => 'Level $level, play',
        _LevelState.locked => 'Level $level, locked',
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor:
              onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: slot,
        ),
      ),
    );
  }

  Widget _buildCurrent() {
    final anim = pulse;
    final face = _DiscFace(
      level: level,
      color: MemoryMatchBoard.glow,
      label: 'PLAY',
    );
    if (anim == null) return face;

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(anim.value);
        return Transform.scale(
          scale: 1 + 0.05 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MemoryMatchBoard.glow
                      .withValues(alpha: 0.35 + 0.30 * t),
                  blurRadius: 14 + 10 * t,
                  spreadRadius: 1 + 2 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: face,
    );
  }
}

class _DiscFace extends StatelessWidget {
  const _DiscFace({
    required this.level,
    required this.color,
    this.badge,
    this.label,
  });

  final int level;
  final Color color;
  final Widget? badge;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final light =
        hsl.withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0)).toColor();

    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth;
        return Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 1.15,
                  colors: [light, color, dark],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: s,
                height: s,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$level',
                        style: GoogleFonts.fredoka(
                          fontSize: s * 0.28,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      if (label != null)
                        Text(
                          label!,
                          style: GoogleFonts.nunito(
                            fontSize: s * 0.11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (badge != null)
              Positioned(right: s * 0.02, top: s * 0.02, child: badge!),
          ],
        );
      },
    );
  }
}

class _Hole extends StatelessWidget {
  const _Hole({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(0, 0.25),
              radius: 0.9,
              colors: [Color(0xFF0A1220), Color(0xFF111E33)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
              width: 1.5,
            ),
          ),
          child: SizedBox(
            width: s,
            height: s,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$level',
                    style: GoogleFonts.fredoka(
                      fontSize: s * 0.24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Positioned(
                  right: s * 0.10,
                  top: s * 0.10,
                  child: Icon(
                    Icons.lock_rounded,
                    size: s * 0.16,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
