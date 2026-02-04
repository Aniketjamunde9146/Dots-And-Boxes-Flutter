import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static AudioPlayer? _bgPlayer;
  static bool isMuted = false;
  static bool isHomePlaying = false;

  static AudioPlayer get _backgroundPlayer {
    _bgPlayer ??= AudioPlayer();
    return _bgPlayer!;
  }

  // 🎵 HOME MUSIC
  static Future<void> playHomeMusic() async {
    if (isMuted || isHomePlaying || kIsWeb) return;

    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.play(
        AssetSource('sounds/home.mp3'),
      );
      isHomePlaying = true;
    } catch (_) {}
  }

  static Future<void> stopHomeMusic() async {
    try {
      await _backgroundPlayer.stop();
    } catch (_) {}
    isHomePlaying = false;
  }

  // 🔔 SAFE SFX (NEW PLAYER EACH TIME)
  static Future<void> _playSfx(String file) async {
    if (isMuted) return;

    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/$file'));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {}
  }

  static void click() => _playSfx('click.mp3');
  static void box() => _playSfx('box.mp3');
  static void win() => _playSfx('win.mp3');
  static void cancel() => _playSfx('cancel.mp3');

  // 🔇 MUTE
  static Future<void> setMuted(bool mute) async {
    isMuted = mute;
    if (mute) {
      await stopHomeMusic();
    }
  }

  // 🗑️ CLEANUP
  static Future<void> dispose() async {
    try {
      await _bgPlayer?.dispose();
    } catch (_) {}
    _bgPlayer = null;
    isHomePlaying = false;
  }
}
