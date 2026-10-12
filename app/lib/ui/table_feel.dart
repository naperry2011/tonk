import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../data/settings_store.dart';
import '../engine/engine.dart';

enum Sfx { select, card, draw, spread, knock, chips, win, lose, tonk }

/// Sounds and haptics for table moments, gated by settings.
class TableFeel {
  TableFeel(this.settings);

  final SettingsController settings;
  final Map<Sfx, AudioPlayer> _players = {};
  StreamSubscription<GameEvent>? _subscription;

  Future<void> preload() async {
    // Mix with the player's own music instead of pausing it on every card.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    for (final sfx in Sfx.values) {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setSource(AssetSource('sfx/${sfx.name}.wav'));
      _players[sfx] = player;
    }
  }

  void attach(Stream<GameEvent> events) {
    _subscription?.cancel();
    _subscription = events.listen(_onEvent);
  }

  void play(Sfx sfx) {
    if (!settings.sound) return;
    final player = _players[sfx];
    if (player == null) return;
    unawaited(player.stop().then((_) => player.resume()));
  }

  void tap() {
    play(Sfx.select);
    _haptic(HapticFeedback.selectionClick);
  }

  void _onEvent(GameEvent event) {
    switch (event) {
      case CardDrawn(:final player):
        play(Sfx.draw);
        if (player.isHuman) _haptic(HapticFeedback.lightImpact);
      case CardDiscarded():
        play(Sfx.card);
      case SpreadLaid(:final player):
        play(Sfx.spread);
        if (player.isHuman) _haptic(HapticFeedback.mediumImpact);
      case SpreadHit(:final player):
        play(Sfx.card);
        if (player.isHuman) _haptic(HapticFeedback.lightImpact);
      case Knocked():
        play(Sfx.knock);
        _haptic(HapticFeedback.heavyImpact);
      case BetPlaced(:final player):
        play(Sfx.chips);
        if (player.isHuman) _haptic(HapticFeedback.mediumImpact);
      case GameOver(:final winner, :final condition):
        final tonk =
            condition == WinCondition.tonk ||
            condition == WinCondition.initialTonk;
        play(
          tonk && winner.isHuman
              ? Sfx.tonk
              : winner.isHuman
              ? Sfx.win
              : Sfx.lose,
        );
        if (winner.isHuman) {
          _haptic(HapticFeedback.heavyImpact);
          if (tonk) {
            Future<void>.delayed(
              const Duration(milliseconds: 180),
              () => _haptic(HapticFeedback.heavyImpact),
            );
          }
        }
      default:
        break;
    }
  }

  void _haptic(Future<void> Function() feedback) {
    if (settings.haptics) unawaited(feedback());
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    for (final player in _players.values) {
      await player.dispose();
    }
  }
}
