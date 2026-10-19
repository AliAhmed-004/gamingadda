import 'package:audioplayers/audioplayers.dart';

/// Short SFX for Blokus. No-ops when [enabled] is false.
class BlokusSounds {
  BlokusSounds({required this.enabled});

  final bool enabled;

  final _select = AudioPlayer();
  final _place = AudioPlayer();
  final _illegal = AudioPlayer();
  final _pass = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _select.setSource(AssetSource('sounds/select.wav')),
        _place.setSource(AssetSource('sounds/move.wav')),
        _illegal.setSource(AssetSource('sounds/hurt.wav')),
        _pass.setSource(AssetSource('sounds/pickup.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {}
  }

  Future<void> select() => _play(_select, 'sounds/select.wav');
  Future<void> place() => _play(_place, 'sounds/move.wav');
  Future<void> illegal() => _play(_illegal, 'sounds/hurt.wav');
  Future<void> pass() => _play(_pass, 'sounds/pickup.wav');
  Future<void> win() => _play(_win, 'sounds/win.wav');

  Future<void> _play(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await Future.wait([
      _select.dispose(),
      _place.dispose(),
      _illegal.dispose(),
      _pass.dispose(),
      _win.dispose(),
    ]);
  }
}
