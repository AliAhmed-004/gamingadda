import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'block_race_board.dart';
import 'block_race_config.dart';
import 'block_race_controller.dart';
import 'block_race_logic.dart';
import 'block_race_sounds.dart';
import 'block_race_theme.dart';
import 'block_race_wall_paint.dart';

class BlockRacePlayScreen extends StatefulWidget {
  const BlockRacePlayScreen({
    super.key,
    required this.config,
    this.demo = false,
  });

  final BlockRaceConfig config;
  final bool demo;

  @override
  State<BlockRacePlayScreen> createState() => _BlockRacePlayScreenState();
}

class _BlockRacePlayScreenState extends State<BlockRacePlayScreen> {
  late final BlockRaceGameController _controller;
  late final BlockRaceSounds _sounds;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _boardKey = GlobalKey();
  bool _showWalls = false;
  bool _draggingWall = false;
  Wall? _previewWall;
  bool _previewLegal = false;

  @override
  void initState() {
    super.initState();
    _sounds = BlockRaceSounds(enabled: widget.config.soundEnabled)..preload();
    _controller = BlockRaceGameController(
      config: widget.config,
      sounds: _sounds,
    )..addListener(_onControllerChanged);
    if (widget.demo) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _controller.runDemoMove();
      });
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    // Leave wall mode whenever the turn moves on (wall placed / AI turn).
    if (_showWalls && !_controller.isHumanTurn) {
      _showWalls = false;
      _clearDrag();
    }
    setState(() {});
  }

  void _clearDrag() {
    _draggingWall = false;
    _previewWall = null;
    _previewLegal = false;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _sounds.dispose();
    super.dispose();
  }

  void _toggleWalls() {
    setState(() {
      _showWalls = !_showWalls;
      _clearDrag();
    });
  }

  void _onDragStarted() {
    _sounds.pickup();
    setState(() {
      _draggingWall = true;
      _showWalls = true;
      _previewWall = null;
      _previewLegal = false;
    });
  }

  void _onDragUpdate(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(global);
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > box.size.width ||
        local.dy > box.size.height) {
      if (_previewWall != null) {
        setState(() {
          _previewWall = null;
          _previewLegal = false;
        });
      }
      return;
    }

    // Account for the board's inner padding (matches BlockRaceBoard padding).
    const pad = 10.0;
    final grid = local - const Offset(pad, pad);
    final cell = (box.size.width - pad * 2) / BlockRaceGame.boardSize;
    if (cell <= 0) return;

    final wall = snapWallAt(grid, cell, _controller.game.wallOrientation);
    final legal = _controller.game.isWallPlacementLegal(wall);
    if (wall == _previewWall && legal == _previewLegal) return;
    setState(() {
      _previewWall = wall;
      _previewLegal = legal;
    });
  }

  Future<void> _onDragEnd() async {
    final wall = _previewWall;
    final legal = _previewLegal;
    setState(_clearDrag);
    if (wall == null) return;
    if (!legal) {
      await _sounds.invalid();
      return;
    }
    setState(() => _showWalls = false);
    await _controller.placeWall(wall);
  }

  void _onDragCanceled() {
    setState(_clearDrag);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BlockRaceTheme.panel,
        title: Text(
          'How to play',
          style: BlockRaceTheme.display(
            fontSize: 20,
            color: BlockRaceTheme.foreground,
          ),
        ),
        content: Text(
          'You are RED (bottom). Reach any cell on the TOP row to win.\n\n'
          '• Each turn: MOVE one step, or PLACE one wall.\n'
          '• Tap a marked cell to move.\n'
          '• Drag a wall from the tray onto the board (or tap "Place wall" '
          'then a green slot). Rotate with Horizontal / Vertical.\n'
          '• Walls block movement for both players.\n'
          '• You can jump straight over the opponent when they are adjacent.\n'
          '• Walls can never fully cut a player off from their goal.\n'
          '• Each player has 10 walls total — spend them wisely!',
          style: BlockRaceTheme.body(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: BlockRaceTheme.foreground,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BlockRaceTheme.bluePlayer,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final game = _controller.game;
    if (game.phase != BlockRacePhase.choosing ||
        !_controller.isHumanTurn ||
        _controller.isBusy) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _controller.moveByDelta(-1, 0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _controller.moveByDelta(1, 0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _controller.moveByDelta(0, -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _controller.moveByDelta(0, 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyW) {
      _toggleWalls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _controller.toggleWallOrientation();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _hint(BlockRaceGame game) {
    if (game.phase == BlockRacePhase.gameOver) return '';
    final vsAi = widget.config.mode == BlockRacePlayMode.vsComputer;
    if (!_controller.isHumanTurn || _controller.isBusy) {
      return vsAi ? 'Blue is thinking…' : '…';
    }
    if (_showWalls || _draggingWall) {
      return _draggingWall
          ? (_previewLegal ? 'Drop to place wall' : 'Move over a legal slot')
          : 'Drag a wall onto the board, or tap a green slot';
    }
    final who = vsAi
        ? 'Your turn'
        : (game.currentPlayer == BlockRacePlayer.red
              ? "Red's turn"
              : "Blue's turn");
    return '$who — tap a marked cell to move';
  }

  @override
  Widget build(BuildContext context) {
    final game = _controller.game;
    final phase = game.phase;
    final canPlay =
        phase == BlockRacePhase.choosing &&
        _controller.isHumanTurn &&
        !_controller.isBusy;
    final vsAi = widget.config.mode == BlockRacePlayMode.vsComputer;
    final wallsLeft = game.wallsLeftFor(game.currentPlayer);
    final turnColor = game.currentPlayer == BlockRacePlayer.blue
        ? BlockRaceTheme.bluePlayer
        : BlockRaceTheme.redPlayer;

    return Scaffold(
      backgroundColor: BlockRaceTheme.background,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _onKey(event),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFBF5),
                BlockRaceTheme.background,
                Color(0xFFE8DFD0),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned(
                top: -90,
                left: -50,
                child: _AmbientBlob(
                  color: BlockRaceTheme.redPlayer,
                  size: 240,
                  opacity: 0.10,
                ),
              ),
              const Positioned(
                top: -70,
                right: -60,
                child: _AmbientBlob(
                  color: BlockRaceTheme.bluePlayer,
                  size: 260,
                  opacity: 0.10,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: BlockRaceTheme.foreground,
                          ),
                          IconButton(
                            tooltip: 'How to play',
                            onPressed: _showHelp,
                            icon: const Icon(Icons.help_outline_rounded),
                            color: BlockRaceTheme.foreground,
                          ),
                          Expanded(
                            child: Text(
                              'BARRICADE CLASH',
                              textAlign: TextAlign.center,
                              style: BlockRaceTheme.display(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: BlockRaceTheme.muted,
                              ),
                            ),
                          ),
                          Text(
                            'M${game.moveCount}',
                            style: BlockRaceTheme.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: BlockRaceTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _PlayerChip(
                            label: vsAi ? 'YOU' : 'RED',
                            color: BlockRaceTheme.redPlayer,
                            walls: game.redWallsLeft,
                            active:
                                game.currentPlayer == BlockRacePlayer.red &&
                                phase == BlockRacePhase.choosing,
                            gotiAsset: BlockRaceTheme.gotiRed,
                          ),
                          const Spacer(),
                          _PlayerChip(
                            label: 'BLUE',
                            color: BlockRaceTheme.bluePlayer,
                            walls: game.blueWallsLeft,
                            active:
                                game.currentPlayer == BlockRacePlayer.blue &&
                                phase == BlockRacePhase.choosing,
                            gotiAsset: BlockRaceTheme.gotiBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: BlockRaceTheme.uiDuration,
                      child: Text(
                        _hint(game),
                        key: ValueKey('${_hint(game)}-$_showWalls'),
                        textAlign: TextAlign.center,
                        style: BlockRaceTheme.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _showWalls
                              ? BlockRaceTheme.validGhost
                              : turnColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0007)
                              ..rotateX(-0.18)
                              ..scaleByDouble(1.02, 1.02, 1.02, 1),
                            child: BlockRaceBoard(
                              key: _boardKey,
                              game: game,
                              wallOwners: _controller.wallOwners,
                              interactive: canPlay,
                              wallMode: _showWalls,
                              previewWall: _previewWall,
                              previewLegal: _previewLegal,
                              onCellTap: _controller.onCellTap,
                              onWallTap: (wall) async {
                                setState(() => _showWalls = false);
                                await _controller.onWallTap(wall);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    _BottomControls(
                      controller: _controller,
                      enabled: canPlay,
                      showWalls: _showWalls,
                      wallsLeft: wallsLeft,
                      dragging: _draggingWall,
                      onToggleWalls: _toggleWalls,
                      onDragStarted: _onDragStarted,
                      onDragEnd: _onDragEnd,
                      onDragCanceled: _onDragCanceled,
                      onDragUpdate: _onDragUpdate,
                    ),
                  ],
                ),
              ),
              if (phase == BlockRacePhase.gameOver)
                _WinnerOverlay(
                  winner: game.winner!,
                  vsComputer: vsAi,
                  onPlayAgain: () {
                    setState(() => _showWalls = false);
                    _controller.startGame();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.controller,
    required this.enabled,
    required this.showWalls,
    required this.wallsLeft,
    required this.dragging,
    required this.onToggleWalls,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragCanceled,
    required this.onDragUpdate,
  });

  final BlockRaceGameController controller;
  final bool enabled;
  final bool showWalls;
  final int wallsLeft;
  final bool dragging;
  final VoidCallback onToggleWalls;
  final VoidCallback onDragStarted;
  final Future<void> Function() onDragEnd;
  final VoidCallback onDragCanceled;
  final ValueChanged<Offset> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final horizontal = game.wallOrientation == WallOrientation.horizontal;
    final owner = game.currentPlayer;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.35,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionChip(
                      label: 'Horizontal',
                      selected: horizontal,
                      color: BlockRaceTheme.validGhost,
                      onTap: () => controller.setWallOrientation(
                        WallOrientation.horizontal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionChip(
                      label: 'Vertical',
                      selected: !horizontal,
                      color: BlockRaceTheme.validGhost,
                      onTap: () => controller.setWallOrientation(
                        WallOrientation.vertical,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Draggable castle wall token.
                  _WallDragHandle(
                    horizontal: horizontal,
                    owner: owner,
                    enabled: wallsLeft > 0,
                    onDragStarted: onDragStarted,
                    onDragEnd: onDragEnd,
                    onDragCanceled: onDragCanceled,
                    onDragUpdate: onDragUpdate,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: wallsLeft > 0 ? onToggleWalls : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: showWalls || dragging
                            ? BlockRaceTheme.bluePlayer
                            : BlockRaceTheme.barricade,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                      icon: Icon(
                        showWalls || dragging
                            ? Icons.directions_run_rounded
                            : Icons.view_column_rounded,
                      ),
                      label: Text(
                        showWalls || dragging
                            ? 'Cancel — back to moving'
                            : 'Place wall ($wallsLeft left)',
                        style: BlockRaceTheme.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                wallsLeft > 0
                    ? 'Drag the wall onto the board to place it'
                    : 'No walls left',
                style: BlockRaceTheme.body(
                  fontSize: 12,
                  color: BlockRaceTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WallDragHandle extends StatefulWidget {
  const _WallDragHandle({
    required this.horizontal,
    required this.owner,
    required this.enabled,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragCanceled,
    required this.onDragUpdate,
  });

  final bool horizontal;
  final BlockRacePlayer owner;
  final bool enabled;
  final VoidCallback onDragStarted;
  final Future<void> Function() onDragEnd;
  final VoidCallback onDragCanceled;
  final ValueChanged<Offset> onDragUpdate;

  @override
  State<_WallDragHandle> createState() => _WallDragHandleState();
}

class _WallDragHandleState extends State<_WallDragHandle> {
  OverlayEntry? _entry;
  Offset _pointer = Offset.zero;

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    _entry = OverlayEntry(
      builder: (context) {
        final w = widget.horizontal ? 110.0 : 42.0;
        final h = widget.horizontal ? 42.0 : 110.0;
        return Positioned(
          left: _pointer.dx - w / 2,
          top: _pointer.dy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: CastleWallToken(
                horizontal: widget.horizontal,
                owner: widget.owner,
                width: widget.horizontal ? 110 : 42,
                height: widget.horizontal ? 42 : 110,
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _pointer = details.globalPosition;
    _showOverlay();
    widget.onDragStarted();
    widget.onDragUpdate(_pointer);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_entry == null) return;
    _pointer = details.globalPosition;
    _entry!.markNeedsBuild();
    widget.onDragUpdate(_pointer);
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    _removeOverlay();
    await widget.onDragEnd();
  }

  void _onPanCancel() {
    _removeOverlay();
    widget.onDragCanceled();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = Opacity(
      opacity: widget.enabled ? 1 : 0.35,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BlockRaceTheme.chipFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BlockRaceTheme.gridLine, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: CastleWallToken(
            horizontal: widget.horizontal,
            owner: widget.owner,
            width: 88,
            height: 34,
          ),
        ),
      ),
    );

    return GestureDetector(
      onPanStart: widget.enabled ? _onPanStart : null,
      onPanUpdate: widget.enabled ? _onPanUpdate : null,
      onPanEnd: widget.enabled ? _onPanEnd : null,
      onPanCancel: widget.enabled ? _onPanCancel : null,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.grab
            : SystemMouseCursors.basic,
        child: token,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.22) : BlockRaceTheme.chipFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : BlockRaceTheme.gridLine,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: BlockRaceTheme.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? color : BlockRaceTheme.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.label,
    required this.color,
    required this.walls,
    required this.active,
    required this.gotiAsset,
  });

  final String label;
  final Color color;
  final int walls;
  final bool active;
  final String gotiAsset;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: BlockRaceTheme.uiDuration,
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.16) : BlockRaceTheme.chipFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.9 : 0.35),
          width: active ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? 0.1 : 0.05),
            blurRadius: active ? 10 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            gotiAsset,
            width: 28,
            height: 28,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: BlockRaceTheme.display(fontSize: 12, color: color),
              ),
              Text(
                '$walls walls',
                style: BlockRaceTheme.body(
                  fontSize: 13,
                  color: BlockRaceTheme.foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WinnerOverlay extends StatelessWidget {
  const _WinnerOverlay({
    required this.winner,
    required this.vsComputer,
    required this.onPlayAgain,
  });

  final BlockRacePlayer winner;
  final bool vsComputer;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final color = winner == BlockRacePlayer.blue
        ? BlockRaceTheme.bluePlayer
        : BlockRaceTheme.redPlayer;
    final title = vsComputer
        ? (winner == BlockRacePlayer.red ? 'YOU WIN!' : 'BLUE WINS')
        : (winner == BlockRacePlayer.red ? 'RED WINS' : 'BLUE WINS');

    return ColoredBox(
      color: const Color(0xFF3A2F28).withValues(alpha: 0.35),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            decoration: BoxDecoration(
              color: BlockRaceTheme.panel,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  winner == BlockRacePlayer.blue
                      ? BlockRaceTheme.gotiBlue
                      : BlockRaceTheme.gotiRed,
                  width: 72,
                  height: 72,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: BlockRaceTheme.display(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Opposite side reached',
                  style: BlockRaceTheme.body(
                    fontSize: 16,
                    color: BlockRaceTheme.muted,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: onPlayAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    'Play Again',
                    style: BlockRaceTheme.display(
                      fontSize: 16,
                      color: Colors.white,
                    ),
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
