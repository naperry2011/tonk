import 'dart:math';

import '../content/roster.dart';
import '../engine/engine.dart';

class Speech {
  const Speech(this.playerId, this.text);
  final String playerId;
  final String text;
}

/// Decides which AI says what in response to game events.
///
/// Big moments (knocks, tonks, match end) always get a line. Small ones
/// (spreads, hits, greetings) are chance-based and skipped while someone
/// spoke recently, so the table stays funny instead of noisy.
class TableTalk {
  TableTalk({
    required this.roster,
    required this.random,
    this.nickname = 'rookie',
    DateTime Function()? clock,
    this.cooldown = const Duration(milliseconds: 1500),
  }) : _clock = clock ?? DateTime.now;

  final Roster roster;
  final Random random;

  /// Replaces {you} in lines.
  String nickname;
  final Duration cooldown;
  final DateTime Function() _clock;
  DateTime? _lastSpoke;

  List<Speech> react(GameEvent event, Game game) {
    switch (event) {
      case RoundStart() || GameInitialized():
        final ai = _randomAi(game);
        return _maybe(ai, TalkKey.greet, chance: 0.6);
      case Knocked(:final knocker, :final winner):
        return [
          if (knocker is ComputerPlayer)
            ?_say(
              knocker,
              identical(knocker, winner)
                  ? TalkKey.knockWin
                  : TalkKey.knockCaught,
            ),
          if (winner is ComputerPlayer && !identical(winner, knocker))
            ?_say(winner, TalkKey.catchKnocker),
          // The human knocked and won: someone at the table tips their hat.
          if (knocker.isHuman && identical(knocker, winner))
            ?_say(_randomAi(game), TalkKey.sufferTonk),
        ];
      case GameOver(:final winner, :final condition)
          when condition == WinCondition.tonk ||
              condition == WinCondition.initialTonk:
        if (winner is ComputerPlayer) return [?_say(winner, TalkKey.tonk)];
        return [?_say(_randomAi(game), TalkKey.sufferTonk)];
      case SpreadLaid(:final player) when player is ComputerPlayer:
        return _maybe(player, TalkKey.spread, chance: 0.5);
      case SpreadHit(:final player, :final spread):
        final owner = spread.owner;
        if (player is ComputerPlayer && owner != null && owner.isHuman) {
          return _maybe(player, TalkKey.hitYou, chance: 0.8);
        }
        if (player.isHuman && owner is ComputerPlayer) {
          return _maybe(owner, TalkKey.gotHit, chance: 0.9);
        }
        return const [];
      default:
        return const [];
    }
  }

  /// Responses to the human's raise, one line per opponent at most.
  List<Speech> raiseResponses(Map<ComputerPlayer, bool> called) => [
    for (final MapEntry(key: ai, value: didCall) in called.entries)
      if (random.nextDouble() < 0.5)
        ?_say(ai, didCall ? TalkKey.callRaise : TalkKey.passRaise),
  ];

  List<Speech> aiRaised(ComputerPlayer ai) => [?_say(ai, TalkKey.raise)];

  List<Speech> matchEnd(Game game) {
    final winner = game.matchWinner;
    if (winner is ComputerPlayer) return [?_say(winner, TalkKey.matchWin)];
    return [?_say(_randomAi(game), TalkKey.matchLose)];
  }

  List<Speech> _maybe(
    ComputerPlayer? ai,
    TalkKey key, {
    required double chance,
  }) {
    if (ai == null) return const [];
    final last = _lastSpoke;
    if (last != null && _clock().difference(last) < cooldown) return const [];
    if (random.nextDouble() >= chance) return const [];
    return [?_say(ai, key)];
  }

  Speech? _say(ComputerPlayer? ai, TalkKey key) {
    if (ai == null) return null;
    final text = roster.line(roster.byId(ai.characterId), key, random);
    if (text == null) return null;
    _lastSpoke = _clock();
    return Speech(ai.id, text.replaceAll('{you}', nickname));
  }

  ComputerPlayer? _randomAi(Game game) {
    final ais = game.players.whereType<ComputerPlayer>().toList();
    return ais.isEmpty ? null : ais[random.nextInt(ais.length)];
  }
}
