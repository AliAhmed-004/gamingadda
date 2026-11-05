import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'blokus_ai.dart';
import 'blokus_board.dart';
import 'blokus_config.dart';
import 'blokus_logic.dart';
import 'blokus_pieces.dart';
import 'blokus_sounds.dart';
import 'blokus_theme.dart';
import 'blokus_tray.dart';

class BlokusPlayScreen extends StatefulWidget {
  const BlokusPlayScreen({super.key, required this.config, this.demo = false});

  final BlokusConfig config;
  final bool demo;

  @override
  State<BlokusPlayScreen> createState() => _BlokusPlayScreenState();
}

class _BlokusPlayScreenState extends State<BlokusPlayScreen> {
  late BlokusGame _game;
  late final BlokusAi _ai;
  late final BlokusSounds _sounds;

  String? _selectedPieceId;
  var _orientationIndex = 0;
  var _anchorCellIndex = 0;
  BlokusCell? _hoverCell;
  var _aiThinking = false;
  var _showResult = false;

  BlokusConfig get _config => widget.config;

  bool get _canInteract =>
      !_aiThinking &&
      !_game.gameOver &&
      !_showResult &&
      _config.isHumanTurn(_game.turn);

  @override
  void initState() {
    super.initState();
    _game = BlokusGame(playerCount: _config.playerCount);
    _ai = BlokusAi();
    _sounds = BlokusSounds(enabled: _config.soundEnabled);
    _sounds.preload();
    _selectedPieceId = _largestRemaining(_game.turn);
    if (widget.demo) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedDemo());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAi());
    }
  }

  @override
  void dispose() {
    _sounds.dispose();
    super.dispose();
  }

  String? _largestRemaining(BlokusColor color) {
    final rem = _game.remaining[color];
    if (rem == null || rem.isEmpty) return null;
    final list = rem.toList()
      ..sort(
        (a, b) =>
            BlokusPieces.byId(b).size.compareTo(BlokusPieces.byId(a).size),
      );
    return list.first;
  }

  void _seedDemo() {
    // Place opening V5 pieces on each active corner for screenshots.
    while (!_game.gameOver) {
      final color = _game.turn;
      if (_game.hasPlaced[color] == true) break;
      final corner = cornerFor(color);
      var placed = false;
      final orients = _game.orientationsOf('v5');
      for (var oi = 0; oi < orients.length && !placed; oi++) {
        for (var ci = 0; ci < orients[oi].length; ci++) {
          final p = _game.placementAtAnchor(
            color: color,
            pieceId: 'v5',
            orientationIndex: oi,
            anchor: corner,
            cellIndex: ci,
          );
          if (p != null && _game.canPlace(p)) {
            _game.place(p);
            placed = true;
            break;
          }
        }
      }
      if (!placed) {
        _game.pass();
      }
    }
    setState(() {
      _selectedPieceId = _largestRemaining(_game.turn);
    });
    _maybeRunAi();
  }

  BlokusGhost? get _ghost {
    final id = _selectedPieceId;
    final cell = _hoverCell;
    if (id == null || cell == null || !_canInteract) return null;

    final orients = _game.orientationsOf(id);
    if (orients.isEmpty) return null;
    final oi = _orientationIndex.clamp(0, orients.length - 1);

    // Prefer current anchor; otherwise any cell of this orientation covering hover.
    BlokusPlacement? p;
    final preferCi = _anchorCellIndex.clamp(0, orients[oi].length - 1);
    p = _game.placementAtAnchor(
      color: _game.turn,
      pieceId: id,
      orientationIndex: oi,
      anchor: cell,
      cellIndex: preferCi,
    );
    if (p == null || !_game.canPlace(p)) {
      p = null;
      for (var ci = 0; ci < orients[oi].length; ci++) {
        final cand = _game.placementAtAnchor(
          color: _game.turn,
          pieceId: id,
          orientationIndex: oi,
          anchor: cell,
          cellIndex: ci,
        );
        if (cand != null && _game.canPlace(cand)) {
          p = cand;
          break;
        }
      }
    }
    // Still show an (illegal) ghost for aiming feedback.
    p ??= _game.placementAtAnchor(
      color: _game.turn,
      pieceId: id,
      orientationIndex: oi,
      anchor: cell,
      cellIndex: preferCi,
    );
    if (p == null) return null;
    return BlokusGhost(
      cells: p.cells,
      color: _game.turn,
      legal: _game.canPlace(p),
    );
  }

  /// Find a legal placement of the selected piece that covers [cell].
  /// Tries current orientation/anchor first, then every orientation and
  /// every piece-cell as the tap anchor so placement is forgiving.
  BlokusPlacement? _placementCovering(BlokusCell cell) {
    final id = _selectedPieceId;
    if (id == null) return null;

    final orients = _game.orientationsOf(id);
    if (orients.isEmpty) return null;

    BlokusPlacement? tryAt(int oi, int ci) {
      final p = _game.placementAtAnchor(
        color: _game.turn,
        pieceId: id,
        orientationIndex: oi,
        anchor: cell,
        cellIndex: ci,
      );
      if (p != null && _game.canPlace(p)) return p;
      return null;
    }

    // Prefer the user's current orientation + anchor.
    final oi0 = _orientationIndex.clamp(0, orients.length - 1);
    final ci0 = _anchorCellIndex.clamp(0, orients[oi0].length - 1);
    final preferred = tryAt(oi0, ci0);
    if (preferred != null) return preferred;

    for (var oi = 0; oi < orients.length; oi++) {
      for (var ci = 0; ci < orients[oi].length; ci++) {
        final p = tryAt(oi, ci);
        if (p != null) {
          _orientationIndex = oi;
          _anchorCellIndex = ci;
          return p;
        }
      }
    }
    return null;
  }

  Future<void> _onCellTap(BlokusCell cell) async {
    if (!_canInteract) return;
    setState(() => _hoverCell = cell);

    final id = _selectedPieceId;
    if (id == null) {
      await _sounds.illegal();
      return;
    }

    final p = _placementCovering(cell);
    if (p == null) {
      await _sounds.illegal();
      setState(() {});
      return;
    }

    _game.place(p);
    await _sounds.place();
    setState(() {
      _hoverCell = null;
      _selectedPieceId = _largestRemaining(_game.turn);
      _orientationIndex = 0;
      _anchorCellIndex = 0;
    });
    await _afterMove();
  }

  Future<void> _pass() async {
    if (!_canInteract) return;
    _game.pass();
    await _sounds.pass();
    setState(() {
      _hoverCell = null;
      _selectedPieceId = _largestRemaining(_game.turn);
      _orientationIndex = 0;
    });
    await _afterMove();
  }

  Future<void> _afterMove() async {
    if (_game.gameOver) {
      await Future<void>.delayed(BlokusTheme.resultOverlayDelay);
      if (!mounted) return;
      await _sounds.win();
      setState(() => _showResult = true);
      return;
    }
    await _maybeRunAi();
  }

  Future<void> _maybeRunAi() async {
    if (!mounted || _game.gameOver || !_config.isVsComputer) return;
    while (mounted &&
        !_game.gameOver &&
        !_config.isHumanTurn(_game.turn)) {
      setState(() => _aiThinking = true);
      await Future<void>.delayed(BlokusTheme.aiTurnDelay);
      if (!mounted || _game.gameOver) break;

      final move = _ai.choosePlacement(_game);
      if (move == null) {
        _game.pass();
        await _sounds.pass();
      } else {
        _game.place(move);
        await _sounds.place();
      }
      if (!mounted) return;
      setState(() {
        _selectedPieceId = _largestRemaining(_game.turn);
        _orientationIndex = 0;
      });
    }
    if (!mounted) return;
    setState(() => _aiThinking = false);
    if (_game.gameOver && !_showResult) {
      await Future<void>.delayed(BlokusTheme.resultOverlayDelay);
      if (!mounted) return;
      await _sounds.win();
      setState(() => _showResult = true);
    }
  }

  void _rotate() {
    final id = _selectedPieceId;
    if (id == null) return;
    final n = _game.orientationsOf(id).length;
    setState(() {
      _orientationIndex = (_orientationIndex + 1) % n;
      _anchorCellIndex = 0;
    });
    _sounds.select();
  }

  void _flip() {
    final id = _selectedPieceId;
    if (id == null) return;
    // Flip = jump halfway through orientation list when possible.
    final n = _game.orientationsOf(id).length;
    if (n <= 1) return;
    setState(() {
      _orientationIndex = (_orientationIndex + (n ~/ 2)) % n;
      _anchorCellIndex = 0;
    });
    _sounds.select();
  }

  void _cycleAnchor() {
    final id = _selectedPieceId;
    if (id == null) return;
    final orients = _game.orientationsOf(id);
    if (_orientationIndex >= orients.length) return;
    final len = orients[_orientationIndex].length;
    setState(() => _anchorCellIndex = (_anchorCellIndex + 1) % len);
    _sounds.select();
  }

  void _selectPiece(String id) {
    setState(() {
      _selectedPieceId = id;
      _orientationIndex = 0;
      _anchorCellIndex = 0;
    });
    _sounds.select();
  }

  void _newGame() {
    setState(() {
      _game = BlokusGame(playerCount: _config.playerCount);
      _selectedPieceId = _largestRemaining(_game.turn);
      _orientationIndex = 0;
      _anchorCellIndex = 0;
      _hoverCell = null;
      _aiThinking = false;
      _showResult = false;
    });
    _maybeRunAi();
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String get _statusText {
    if (_showResult || _game.gameOver) {
      final rank = _game.ranking();
      return '${rank.first.label} wins!';
    }
    if (_aiThinking) return 'AI thinking…';
    return "${_game.turn.label}'s turn";
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_canInteract) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _rotate();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _flip();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      _cycleAnchor();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [BlokusTheme.bgTop, BlokusTheme.bgBottom],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(),
                    _buildScores(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: BlokusBoard(
                          game: _game,
                          ghost: _ghost,
                          interactive: _canInteract,
                          onCellTap: _onCellTap,
                          onHover: (cell) {
                            if (!_canInteract) return;
                            if (_hoverCell != cell) {
                              setState(() => _hoverCell = cell);
                            }
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                      child: BlokusTray(
                        game: _game,
                        color: _game.turn,
                        selectedPieceId: _selectedPieceId,
                        enabled: _canInteract,
                        onSelect: _selectPiece,
                      ),
                    ),
                    _buildControls(),
                    const SizedBox(height: 8),
                  ],
                ),
                if (_showResult) _buildResultOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BlokusTheme.statusText,
              ),
            ),
          ),
          IconButton(
            onPressed: _goHome,
            icon: const Icon(Icons.home_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScores() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final c in _game.activeColors)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: BlokusTheme.face(c).withValues(
                    alpha: _game.turn == c ? 0.95 : 0.35,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _game.turn == c ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      c.label.substring(0, 1),
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_game.scores[c] ?? 0}',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _ctrlBtn(Icons.rotate_right_rounded, 'Rotate', _canInteract ? _rotate : null),
          const SizedBox(width: 6),
          _ctrlBtn(Icons.flip_rounded, 'Flip', _canInteract ? _flip : null),
          const SizedBox(width: 6),
          _ctrlBtn(Icons.gps_fixed_rounded, 'Anchor', _canInteract ? _cycleAnchor : null),
          const SizedBox(width: 6),
          Expanded(
            child: FilledButton.tonal(
              onPressed: _canInteract ? _pass : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Pass',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, String tip, VoidCallback? onPressed) {
    return Tooltip(
      message: tip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final rank = _game.ranking();
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F38),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Game Over',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < rank.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: BlokusTheme.face(rank[i]),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${i + 1}. ${rank[i].label}',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${_game.scores[rank[i]] ?? 0}',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _newGame,
                  child: const Text('Play again'),
                ),
                TextButton(
                  onPressed: _goHome,
                  child: const Text('Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
