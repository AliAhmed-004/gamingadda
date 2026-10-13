import 'package:audioplayers/audioplayers.dart';

/// Short SFX for Barricade Clash. No-ops when [enabled] is false.
class BlockRaceSounds {
  BlockRaceSounds({required this.enabled});

  final bool enabled;

  final _move = AudioPlayer();
  final _wall = AudioPlayer();
  final _pickup = AudioPlayer();
  final _invalid = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _move.setSource(AssetSource('sounds/move.wav')),
        _wall.setSource(AssetSource('sounds/capture.wav')),
        _pickup.setSource(AssetSource('sounds/pickup.wav')),
        _invalid.setSource(AssetSource('sounds/hurt.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {
      // Ignore preload failures (tests / missing plugin).
    }
  }

  Future<void> move() => _play(_move, 'sounds/move.wav');
  Future<void> wall() => _play(_wall, 'sounds/capture.wav');
  Future<void> pickup() => _play(_pickup, 'sounds/pickup.wav');
  Future<void> invalid() => _play(_invalid, 'sounds/hurt.wav');
  Future<void> win() => _play(_win, 'sounds/win.wav');

  Future<void> _play(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Ignore audio failures (missing plugin on some test hosts).
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      _move.dispose(),
      _wall.dispose(),
      _pickup.dispose(),
      _invalid.dispose(),
      _win.dispose(),
    ]);
  }
}
