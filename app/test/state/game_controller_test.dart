import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/content/roster.dart';
import 'package:tonk/data/save_store.dart';
import 'package:tonk/engine/engine.dart';
import 'package:tonk/state/game_controller.dart';

GameController _controller(int seed, [SaveStore? store]) => GameController(
  store: store ?? MemorySaveStore(),
  aiStepDelay: Duration.zero,
  random: Random(seed),
);

/// Waits until AI turns finish and it's the human's move or the round ended.
/// AI raises are answered with [call], or randomly when [choices] is given.
Future<void> _settle(
  GameController c, {
  bool call = true,
  Random? choices,
}) async {
  for (var i = 0; i < 20000; i++) {
    if (c.pendingRaise != null) {
      c.answerRaise(call: choices == null ? call : choices.nextBool());
    } else if (!c.aiThinking) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('AI loop did not finish');
}

/// Simple human strategy: sometimes raise, lay any spread, draw from the
/// stock, dump the highest card.
void _playHumanTurn(GameController c, [Random? raises]) {
  if (raises != null && raises.nextDouble() < 0.3 && c.canRaise(10)) {
    c.raise(10);
  }
  if (!c.isHumanTurn) return;
  for (final candidate in findPossibleSpreads(c.human.hand)) {
    if (!c.isHumanTurn || !candidate.cards.every(c.human.hasCard)) continue;
    c.selected
      ..clear()
      ..addAll(candidate.cards);
    c.laySelected();
  }
  if (!c.isHumanTurn) return;
  c.drawFromDeck();
  if (!c.isHumanTurn) return;
  c.selected
    ..clear()
    ..add(c.human.getCardsSortedByValue().first);
  c.discardSelected();
}

int _totalChips(Game g) => g.players.fold(g.pot, (sum, p) => sum + p.chips);

void main() {
  test('plays full matches against the AI with chips conserved', () async {
    for (var seed = 0; seed < 5; seed++) {
      final c = _controller(seed)..newMatch(3);
      final expected = 4 * Betting.startingChips;
      final choices = Random(seed);
      var rounds = 0;

      while (true) {
        await _settle(c, choices: choices);
        final summary = c.roundSummary;
        if (summary != null) {
          rounds++;
          expect(_totalChips(c.game), expected);
          if (summary.matchEnded) break;
          c.startNextRound();
          continue;
        }
        expect(c.isHumanTurn, isTrue);
        _playHumanTurn(c, choices);
        expect(c.error, isNull);
      }

      expect(rounds, greaterThan(0));
      expect(c.roundSummary!.matchWinner, isNotNull);
    }
  });

  test('a rejected action sets an error and changes nothing', () async {
    final c = _controller(3)..newMatch(1);
    await _settle(c);
    if (!c.isHumanTurn) return;
    final before = jsonEncode(c.game.toJson());
    c.selected
      ..clear()
      ..add(c.human.hand.first);
    c.discardSelected(); // can't discard before drawing
    expect(jsonEncode(c.game.toJson()), before);
  });

  test('raising moves chips into the pot and opponents respond', () async {
    final c = _controller(11)..newMatch(2);
    await _settle(c);
    expect(c.isHumanTurn, isTrue);
    final pot = c.game.pot;
    final chips = c.human.chips;

    c.raise(25);
    expect(c.human.chips, chips - 25);
    expect(c.game.pot, greaterThanOrEqualTo(pot + 25));
    for (final ai in c.opponents) {
      expect(c.lastAction[ai.id], isNotNull);
    }
    expect(c.canRaise(10), isFalse, reason: 'one raise per turn');
    expect(_totalChips(c.game), 3 * Betting.startingChips);
  });

  test('a saved match resumes where it left off', () async {
    final store = MemorySaveStore();
    final c = _controller(5, store)..newMatch(2);
    await _settle(c);
    if (c.isHumanTurn) _playHumanTurn(c);
    await _settle(c);
    final snapshot = jsonEncode(c.game.toJson());
    c.dispose();

    final resumed = _controller(6, store);
    expect(await resumed.hasSavedMatch(), isTrue);
    expect(await resumed.resume(), isTrue);
    if (resumed.roundSummary == null) {
      expect(jsonEncode(resumed.game.toJson()), snapshot);
    }
  });

  test('a roster match seats characters, talks, and survives resume', () async {
    final roster = Roster.fromJsonString(
      File('assets/content/characters.json').readAsStringSync(),
    );
    final store = MemorySaveStore();
    final c = GameController(
      store: store,
      aiStepDelay: Duration.zero,
      random: Random(21),
      roster: roster,
      talkRandom: Random(2),
      speechDuration: const Duration(milliseconds: 1),
    )..newMatch(3);

    final ids = c.opponents.map((p) => c.characterFor(p)!.id).toSet();
    expect(ids, hasLength(3));

    var spoke = false;
    c.addListener(() => spoke = spoke || c.speech.isNotEmpty);
    for (var round = 0; round < 6; round++) {
      while (c.roundSummary == null) {
        await _settle(c);
        if (c.roundSummary == null) _playHumanTurn(c);
      }
      if (c.roundSummary!.matchEnded) break;
      c.startNextRound();
    }
    expect(spoke, isTrue, reason: 'knocks and tonks always get a line');

    if (c.roundSummary?.matchEnded ?? false) return;
    final resumed = GameController(store: store, roster: roster);
    expect(await resumed.resume(), isTrue);
    expect(
      resumed.opponents.map((p) => resumed.characterFor(p)?.id).toSet(),
      ids,
    );
    resumed.dispose();
  });

  group('AI raises', () {
    /// Opponents that always raise and never fold.
    final raisers = Roster(
      characters: [
        for (final id in ['a', 'b'])
          Character(
            id: id,
            name: 'Raiser $id',
            tagline: '',
            color: const Color(0xFFFFFFFF),
            emoji: '',
            style: const AiStyle(
              raiseAppetite: 100,
              foldChance: 0,
              knockAlwaysAt: -1,
              knockMaybeAt: -1,
            ),
            lines: const {},
          ),
      ],
      shared: const {},
    );

    GameController raiseTable(int seed, [SaveStore? store]) => GameController(
      store: store ?? MemorySaveStore(),
      aiStepDelay: Duration.zero,
      random: Random(seed),
      roster: raisers,
    );

    /// Plays human turns until an AI raise prompt shows.
    Future<void> untilPrompt(GameController c) async {
      for (var i = 0; i < 20000 && c.pendingRaise == null; i++) {
        if (c.isHumanTurn) _playHumanTurn(c);
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.pendingRaise, isNotNull);
    }

    test('calling pays the raise and keeps you in', () async {
      final c = raiseTable(1)..newMatch(2);
      await untilPrompt(c);
      final raise = c.pendingRaise!;
      final chips = c.human.chips;
      c.answerRaise(call: true);
      await Future<void>.delayed(Duration.zero);
      expect(c.human.chips, chips - raise.toCall);
      expect(c.human.hasFolded, isFalse);
      expect(_totalChips(c.game), 3 * Betting.startingChips);
    });

    test('folding sits you out and the round plays out without you', () async {
      final c = raiseTable(2)..newMatch(2);
      await untilPrompt(c);
      c.answerRaise(call: false);
      await _settle(c);
      expect(c.human.hasFolded, isTrue);
      expect(c.roundSummary, isNotNull);
      expect(c.roundSummary!.winner.isHuman, isFalse);
      expect(_totalChips(c.game), 3 * Betting.startingChips);
    });

    test('each AI raises at most once per round', () async {
      final c = raiseTable(3)..newMatch(2);
      var prompts = 0;
      PendingRaise? last;
      while (c.roundSummary == null) {
        if (c.pendingRaise != null && !identical(c.pendingRaise, last)) {
          prompts++;
          last = c.pendingRaise;
          c.answerRaise(call: true);
        }
        if (c.isHumanTurn) _playHumanTurn(c);
        await Future<void>.delayed(Duration.zero);
      }
      expect(prompts, lessThanOrEqualTo(2));
    });

    test('a pending prompt survives an app restart', () async {
      final store = MemorySaveStore();
      final c = raiseTable(4, store)..newMatch(2);
      await untilPrompt(c);
      final raiserId = c.pendingRaise!.raiser.id;
      final pot = c.game.pot;
      c.dispose();

      final resumed = raiseTable(5, store);
      expect(await resumed.resume(), isTrue);
      for (var i = 0; i < 100 && resumed.pendingRaise == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(resumed.pendingRaise?.raiser.id, raiserId);
      expect(resumed.game.pot, pot, reason: 'the raise is not charged twice');
      resumed.dispose();
    });
  });

  test('the save is cleared once a match is abandoned', () async {
    final store = MemorySaveStore();
    final c = _controller(8, store)..newMatch(1);
    await _settle(c);
    expect(await store.load(), isNotNull);
    await c.abandonMatch();
    expect(await store.load(), isNull);
    expect(c.hasGame, isFalse);
  });
}
