import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../data/settings_store.dart';

/// Loops the lofi track quietly under the game, following the Music setting
/// and pausing while the app is in the background.
class LofiMusic {
  LofiMusic(this.settings);

  final SettingsController settings;

  /// Kept under the sound effects.
  static const double volume = 0.32;

  final AudioPlayer _player = AudioPlayer(playerId: 'lofi-music');
  AppLifecycleListener? _lifecycle;
  bool _ready = false;
  bool _foreground = true;

  Future<void> start() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(volume);
    await _player.setSource(AssetSource('music/lofi_loop.wav'));
    _ready = true;
    settings.addListener(_sync);
    _lifecycle = AppLifecycleListener(
      onShow: () => _setForeground(true),
      onResume: () => _setForeground(true),
      onHide: () => _setForeground(false),
      onPause: () => _setForeground(false),
    );
    _sync();
  }

  void _setForeground(bool value) {
    _foreground = value;
    _sync();
  }

  void _sync() {
    if (!_ready) return;
    final shouldPlay = settings.music && _foreground;
    final playing = _player.state == PlayerState.playing;
    if (shouldPlay && !playing) {
      unawaited(_player.resume());
    } else if (!shouldPlay && playing) {
      unawaited(_player.pause());
    }
  }

  Future<void> dispose() async {
    settings.removeListener(_sync);
    _lifecycle?.dispose();
    await _player.dispose();
  }
}
