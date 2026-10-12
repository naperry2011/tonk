import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/content/roster.dart';
import 'package:tonk/engine/engine.dart';
import 'package:tonk/state/table_talk.dart';

final _source = File('assets/content/characters.json').readAsStringSync();

/// Words that must never ship (talk tone: playful, no cursing).
const _banned = [
  'damn', 'hell', 'shit', 'fuck', 'bitch', 'ass', 'crap', 'piss', 'dick', //
];

void main() {
  final roster = Roster.fromJsonString(_source);

  group('characters.json', () {
    test('has unique ids and enough characters for a 4-player table', () {
      final ids = roster.characters.map((c) => c.id).toSet();
      expect(ids, hasLength(roster.characters.length));
      expect(roster.characters.length, greaterThanOrEqualTo(3));
    });

    test('only uses known talk keys', () {
      final json = jsonDecode(_source) as Map<String, dynamic>;
      final known = TalkKey.values.map((k) => k.name).toSet();
      for (final c in json['characters'] as List) {
        final lines = (c as Map<String, dynamic>)['lines'] as Map;
        expect(known.containsAll(lines.keys), isTrue, reason: '${c['id']}');
      }
      expect(known.containsAll((json['shared'] as Map).keys), isTrue);
    });

    test('every key has a shared fallback line', () {
      for (final key in TalkKey.values) {
        expect(roster.shared[key], isNotEmpty, reason: key.name);
      }
    });

    test('keeps the talk clean', () {
      final words = RegExp(r"[a-z']+");
      final all = [
        for (final c in roster.characters) ...c.lines.values.expand((l) => l),
        ...roster.shared.values.expand((l) => l),
      ];
      for (final line in all) {
        expect(line.trim(), isNotEmpty);
        final tokens = words
            .allMatches(line.toLowerCase())
            .map((m) => m.group(0));
        for (final word in _banned) {
          expect(tokens, isNot(contains(word)), reason: line);
        }
      }
    });

    test('styles stay in sane ranges', () {
      for (final c in roster.characters) {
        expect(c.style.knockAlwaysAt, lessThanOrEqualTo(c.style.knockMaybeAt));
        expect(c.style.foldChance, inInclusiveRange(0, 1));
        expect(c.style.raiseAppetite, greaterThan(0));
      }
    });
  });

  group('TableTalk', () {
    Game tableOf(List<Character> cast) =>
        Game(random: Random(1))..initializeWithPlayers([
          Player('You', isHuman: true),
          for (final c in cast)
            ComputerPlayer(c.name, style: c.style, characterId: c.id),
        ]);

    test('a knock always gets a reaction from the knocker and the catcher', () {
      final game = tableOf(roster.characters.take(2).toList());
      final [_, a, b] = game.players;
      final talk = TableTalk(roster: roster, random: Random(2));

      final lines = talk.react(Knocked(a, b), game);
      expect(lines.map((s) => s.playerId), [a.id, b.id]);
      final caught =
          roster.characters.first.lines[TalkKey.knockCaught]! +
          roster.shared[TalkKey.knockCaught]!;
      expect(caught, contains(lines.first.text));
    });

    test('small moments respect the cooldown', () {
      var now = DateTime(2026);
      final game = tableOf(roster.characters.take(1).toList());
      final ai = game.players[1];
      final talk = TableTalk(
        roster: roster,
        random: Random(3),
        clock: () => now,
      );
      final spread = Spread(
        [
          Card(Suit.hearts, '2'),
          Card(Suit.hearts, '3'),
          Card(Suit.hearts, '4'),
        ],
        SpreadType.run,
        game.players.first,
      );

      // Big moment speaks and starts the cooldown.
      expect(talk.react(Knocked(ai, ai), game), hasLength(1));
      // A hit right after is suppressed.
      expect(
        talk.react(SpreadHit(ai, Card(Suit.hearts, '5'), spread), game),
        isEmpty,
      );
      // After the cooldown it can speak again (chance permitting).
      now = now.add(const Duration(seconds: 5));
      final later = [
        for (var i = 0; i < 20; i++)
          ...talk
              .react(SpreadHit(ai, Card(Suit.hearts, '5'), spread), game)
              .also(() => now = now.add(const Duration(seconds: 5))),
      ];
      expect(later, isNotEmpty);
    });

    test('fills in the nickname', () {
      final game = tableOf(roster.characters.take(1).toList());
      final talk = TableTalk(roster: roster, random: Random(4), nickname: 'Z');
      for (var i = 0; i < 30; i++) {
        for (final s in talk.matchEnd(game..matchWinner = game.players.first)) {
          expect(s.text, isNot(contains('{you}')));
        }
      }
    });
  });
}

extension<T> on T {
  T also(void Function() effect) {
    effect();
    return this;
  }
}
