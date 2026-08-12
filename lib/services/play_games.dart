import 'package:games_services/games_services.dart';

/// Thin wrapper around Google Play Games Services sign-in.
///
/// Keys live outside Dart: the Android App ID is in
/// android/app/src/main/res/values/games_ids.xml. No key belongs here.
class PlayGames {
  /// Signs the player in silently if possible, prompting otherwise.
  /// Safe to call at startup; returns false if the user declines or on error.
  static Future<bool> signIn() async {
    try {
      await GamesServices.signIn();
      return await GamesServices.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get isSignedIn => GamesServices.isSignedIn;
}
