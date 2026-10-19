import 'package:flutter/material.dart';

import 'block_race_logic.dart';
import 'block_race_theme.dart';
import 'block_race_wall_layout.dart';

/// Light cartoon Barricade Clash board — wooden panel, plastic gotis,
/// stone+teal castle walls. Input + render share one widget.
class BlockRaceBoard extends StatelessWidget {
  const BlockRaceBoard({
    super.key,
    required this.game,
    required this.wallOwners,
    required this.interactive,
    required this.wallMode,
    required this.onCellTap,
    required this.onWallTap,
    this.previewWall,
    this.previewLegal = false,
  });

  final BlockRaceGame game;
  final Map<Wall, BlockRacePlayer> wallOwners;
  final bool interactive;
  final bool wallMode;
  final ValueChanged<BoardPos> onCellTap;
  final ValueChanged<Wall> onWallTap;

  /// Snapped wall ghost while the player is dragging from the tray.
  final Wall? previewWall;
  final bool previewLegal;

  @override
  Widget build(BuildContext context) {
    // Center keeps AspectRatio effective even under tight constraints.
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFFB8956A).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  BlockRaceTheme.boardPanel,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFC4A57A),
                      width: 2.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cell =
                          constraints.maxWidth / BlockRaceGame.boardSize;
                      final legal = interactive && !wallMode
                          ? game.legalMoves().toSet()
                          : const <BoardPos>{};
                      final layout = WallLayout(game.walls, wallOwners);
                      final corners = layout.corners();

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: List.generate(
                                BlockRaceGame.boardSize,
                                (row) => Expanded(
                                  child: Row(
                                    children: List.generate(
                                      BlockRaceGame.boardSize,
                                      (col) => Expanded(
                                        child: _Tile(row: row, col: col),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Castle barricades spanning exactly two cell edges.
                          for (final wall in game.walls)
                            _PlacedWall(
                              key: ValueKey(
                                'wall-${wall.row}-${wall.col}-${wall.orientation.name}',
                              ),
                              wall: wall,
                              cell: cell,
                              owner: wallOwners[wall] ?? BlockRacePlayer.red,
                            ),
                          // Hub pillars only where H + V meet (wall sprites
                          // already include end towers on free ends).
                          for (final corner in corners)
                            _WallPillar(
                              key: ValueKey(
                                'corner-${corner.point.row}-${corner.point.col}',
                              ),
                              point: corner.point,
                              cell: cell,
                              diameter: cell * 0.56,
                              owner: corner.owner,
                              pop: true,
                            ),
                          if (previewWall != null)
                            _PlacedWall(
                              key: const ValueKey('preview-wall'),
                              wall: previewWall!,
                              cell: cell,
                              owner: game.currentPlayer,
                              ghost: true,
                              ghostLegal: previewLegal,
                            ),
                          for (final pos in legal)
                            Positioned(
                              left: pos.col * cell,
                              top: pos.row * cell,
                              width: cell,
                              height: cell,
                              child: _MoveTarget(onTap: () => onCellTap(pos)),
                            ),
                          _Piece(
                            key: const ValueKey('piece-blue'),
                            pos: game.bluePos,
                            cell: cell,
                            player: BlockRacePlayer.blue,
                            winner: game.winner == BlockRacePlayer.blue,
                            active:
                                game.currentPlayer == BlockRacePlayer.blue &&
                                game.phase == BlockRacePhase.choosing,
                          ),
                          _Piece(
                            key: const ValueKey('piece-red'),
                            pos: game.redPos,
                            cell: cell,
                            player: BlockRacePlayer.red,
                            winner: game.winner == BlockRacePlayer.red,
                            active:
                                game.currentPlayer == BlockRacePlayer.red &&
                                game.phase == BlockRacePhase.choosing,
                          ),
                          if (interactive && wallMode && previewWall == null)
                            for (var r = 0; r < BlockRaceGame.fenceSize; r++)
                              for (var c = 0; c < BlockRaceGame.fenceSize; c++)
                                if (game.isWallPlacementLegal(
                                  Wall(
                                    row: r,
                                    col: c,
                                    orientation: game.wallOrientation,
                                  ),
                                ))
                                  _WallSlot(
                                    key: ValueKey(
                                      'slot-$r-$c-${game.wallOrientation.name}',
                                    ),
                                    wall: Wall(
                                      row: r,
                                      col: c,
                                      orientation: game.wallOrientation,
                                    ),
                                    cell: cell,
                                    onTap: onWallTap,
                                  ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.row, required this.col});

  final int row;
  final int col;

  @override
  Widget build(BuildContext context) {
    final isRedGoal = row == 0;
    final isBlueGoal = row == BlockRaceGame.boardSize - 1;
    final dark = (row + col).isOdd;

    late final Color top;
    late final Color bottom;
    if (isRedGoal) {
      top = const Color(0xFFF2C4BC);
      bottom = const Color(0xFFE8A99E);
    } else if (isBlueGoal) {
      top = const Color(0xFFBDD4F0);
      bottom = const Color(0xFFA4C2E6);
    } else if (dark) {
      top = const Color(0xFFD9B88E);
      bottom = const Color(0xFFC9A574);
    } else {
      top = const Color(0xFFF3E2C4);
      bottom = const Color(0xFFE8D4AE);
    }

    final accent = isRedGoal
        ? BlockRaceTheme.redPlayer
        : isBlueGoal
        ? BlockRaceTheme.bluePlayer
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
          bottom: BorderSide(
            color: Colors.brown.withValues(alpha: 0.18),
            width: 1,
          ),
          right: BorderSide(
            color: Colors.brown.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
      ),
      child: accent == null
          ? null
          : Center(
              child: FractionallySizedBox(
                widthFactor: 0.28,
                heightFactor: 0.28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _MoveTarget extends StatefulWidget {
  const _MoveTarget({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MoveTarget> createState() => _MoveTargetState();
}

class _MoveTargetState extends State<_MoveTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: reduceMotion
            ? _marker(1)
            : AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => _marker(0.78 + 0.22 * _pulse.value),
              ),
      ),
    );
  }

  Widget _marker(double t) {
    return Center(
      child: Opacity(
        opacity: t.clamp(0.55, 1.0),
        child: Transform.scale(
          scale: 0.52 + 0.1 * t,
          child: Image.asset(
            BlockRaceTheme.moveTarget,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _Piece extends StatelessWidget {
  const _Piece({
    super.key,
    required this.pos,
    required this.cell,
    required this.player,
    required this.winner,
    required this.active,
  });

  final BoardPos pos;
  final double cell;
  final BlockRacePlayer player;
  final bool winner;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: BlockRaceTheme.moveDuration,
      curve: Curves.easeOutCubic,
      left: pos.col * cell,
      top: pos.row * cell,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: AnimatedScale(
          duration: BlockRaceTheme.uiDuration,
          scale: winner ? 1.08 : (active ? 1.05 : 1.0),
          child: Padding(
            padding: EdgeInsets.all(cell * 0.04),
            child: Image.asset(
              BlockRaceTheme.gotiAsset(player),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacedWall extends StatelessWidget {
  const _PlacedWall({
    super.key,
    required this.wall,
    required this.cell,
    required this.owner,
    this.ghost = false,
    this.ghostLegal = true,
  });

  final Wall wall;
  final double cell;
  final BlockRacePlayer owner;
  final bool ghost;
  final bool ghostLegal;

  @override
  Widget build(BuildContext context) {
    final horizontal = wall.orientation == WallOrientation.horizontal;
    // Tall enough for stone body + teal roof overhang in the sprite.
    final thick = cell * 0.58;
    final endPad = cell * 0.02;

    final double left;
    final double top;
    final double width;
    final double height;
    if (horizontal) {
      left = wall.col * cell + endPad;
      top = (wall.row + 1) * cell - thick * 0.62;
      width = cell * 2 - endPad * 2;
      height = thick;
    } else {
      left = (wall.col + 1) * cell - thick * 0.62;
      top = wall.row * cell + endPad;
      width = thick;
      height = cell * 2 - endPad * 2;
    }

    final asset = BlockRaceTheme.wallAsset(owner, horizontal: horizontal);
    Widget image = Image.asset(
      asset,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    if (ghost) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(
          ghostLegal
              ? BlockRaceTheme.validGhost.withValues(alpha: 0.55)
              : BlockRaceTheme.invalidGhost.withValues(alpha: 0.55),
          BlendMode.srcATop,
        ),
        child: image,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: ghost ? 1 : 0, end: 1),
          duration: ghost ? Duration.zero : BlockRaceTheme.wallDuration,
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: (ghost ? 0.85 : t).clamp(0.0, 1.0),
            child: Transform.scale(
              scaleX: ghost ? 1 : (horizontal ? 0.6 + 0.4 * t : 1.0),
              scaleY: ghost ? 1 : (horizontal ? 1.0 : 0.6 + 0.4 * t),
              child: child,
            ),
          ),
          child: image,
        ),
      ),
    );
  }
}

class _WallPillar extends StatelessWidget {
  const _WallPillar({
    super.key,
    required this.point,
    required this.cell,
    required this.diameter,
    required this.owner,
    this.pop = false,
  });

  final FencePoint point;
  final double cell;
  final double diameter;
  final BlockRacePlayer owner;
  final bool pop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: point.col * cell - diameter / 2,
      top: point.row * cell - diameter / 2,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: BlockRaceTheme.wallDuration,
          curve: pop ? Curves.easeOutBack : Curves.easeOut,
          builder: (context, t, child) => Transform.scale(
            scale: 0.6 + 0.4 * t.clamp(0.0, 1.0),
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
          child: Image.asset(
            BlockRaceTheme.wallPillarAsset(owner),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _SlotGhostPainter extends CustomPainter {
  _SlotGhostPainter({required this.horizontal, required this.hover});

  final bool horizontal;
  final bool hover;

  @override
  void paint(Canvas canvas, Size size) {
    final thick = horizontal ? size.height : size.width;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(thick / 2),
    );
    const green = BlockRaceTheme.validGhost;

    canvas.drawRRect(
      rrect,
      Paint()..color = green.withValues(alpha: hover ? 0.38 : 0.2),
    );

    // Dashed outline.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = green.withValues(alpha: 0.9);
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0.0, metric.length)),
          outline,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SlotGhostPainter old) =>
      old.hover != hover || old.horizontal != horizontal;
}

class _WallSlot extends StatefulWidget {
  const _WallSlot({
    super.key,
    required this.wall,
    required this.cell,
    required this.onTap,
  });

  final Wall wall;
  final double cell;
  final ValueChanged<Wall> onTap;

  @override
  State<_WallSlot> createState() => _WallSlotState();
}

class _WallSlotState extends State<_WallSlot> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;
    final horizontal = widget.wall.orientation == WallOrientation.horizontal;
    final hit = (cell * 0.85).clamp(28.0, 56.0);
    final double left;
    final double top;
    final double width;
    final double height;
    if (horizontal) {
      left = widget.wall.col * cell - cell * 0.04;
      top = (widget.wall.row + 1) * cell - hit / 2;
      width = cell * 2 + cell * 0.08;
      height = hit;
    } else {
      left = (widget.wall.col + 1) * cell - hit / 2;
      top = widget.wall.row * cell - cell * 0.04;
      width = hit;
      height = cell * 2 + cell * 0.08;
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(widget.wall),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _hover ? 0.95 : 0.55,
              child: Transform.scale(
                scale: _hover ? 1.05 : 0.92,
                child: SizedBox(
                  width: horizontal ? cell * 1.86 : cell * 0.26,
                  height: horizontal ? cell * 0.26 : cell * 1.86,
                  child: CustomPaint(
                    painter: _SlotGhostPainter(
                      horizontal: horizontal,
                      hover: _hover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
