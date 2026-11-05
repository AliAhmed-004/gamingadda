import 'package:audioplayers/audioplayers.dart';

/// Short SFX for Memory Match. No-ops when [enabled] is false.
class MemoryMatchSounds {
  MemoryMatchSounds({required this.enabled});

  final bool enabled;

  final _flip = AudioPlayer();
  final _match = AudioPlayer();
  final _miss = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _flip.setSource(AssetSource('sounds/select.wav')),
        _match.setSource(AssetSource('sounds/capture.wav')),
        _miss.setSource(AssetSource('sounds/hurt.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {
      // Ignore preload failures (tests / missing plugin).
    }
  }

  Future<void> flip() => _play(_flip, 'sounds/select.wav');
  Future<void> match() => _play(_match, 'sounds/capture.wav');
  Future<void> miss() => _play(_miss, 'sounds/hurt.wav');
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
      _flip.dispose(),
      _match.dispose(),
      _miss.dispose(),
      _win.dispose(),
    ]);
  }
}
