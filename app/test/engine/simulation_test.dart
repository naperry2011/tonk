import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

const _turnCap = 500;

Game _allAiGame(int seed, int seats) {
  final random = Random(seed);
  return Game(random: random)..initializeWithPlayers([
    for (var i = 0; i < seats; i++) ComputerPlayer('Bot $i', random: random),
  ]);
}

/// Plays AI turns until the round ends. Returns the number of turns taken.
int _playRound(Game game) {
  var turns = 0;
  while (!game.isGameOver) {
    runAiTurn(game).toList();
    expect(++turns, lessThan(_turnCap), reason: 'round did not terminate');
  }
  return turns;
}

int _totalChips(Game game) =>
    game.players.fold(game.pot, (sum, p) => sum + p.chips);

void main() {
  test('1,000 seeded AI-vs-AI rounds complete with chips conserved', () {
    final conditions = <WinCondition>{};
    var rounds = 0;
    var seed = 0;

    while (rounds < 1000) {
      final seats = 2 + seed % 3;
      final game = _allAiGame(seed++, seats);
      final expectedChips = seats * Betting.startingChips;

      while (rounds < 1000) {
        _playRound(game);
        rounds++;
        conditions.add(game.winCondition!);

        expect(_totalChips(game), expectedChips);
        final cardsInPlay =
            game.deck.cardsRemaining +
            game.deck.discardPile.length +
            game.players.fold(0, (sum, p) => sum + p.cardCount) +
            game.spreadsOnTable.fold(0, (sum, s) => sum + s.cards.length);
        expect(cardsInPlay, 52);

        final settled = game.settleRound();
        expect(_totalChips(game), expectedChips);
        if (settled.matchEnded) {
          expect(game.matchWinner, isNotNull);
          break;
        }
        game.startNextRound();
      }
    }

    // A healthy engine reaches the common endings across 1,000 rounds.
    expect(
      conditions,
      containsAll([WinCondition.tonk, WinCondition.knock, WinCondition.caught]),
    );
  });

  test('the same seed replays the same match', () {
    List<String> transcript(int seed) {
      final game = _allAiGame(seed, 3);
      final log = <String>[];
      game.addListener((e) => log.add(e.runtimeType.toString()));
      for (var r = 0; r < 5 && !(game.settleRoundIfOver()); r++) {
        _playRound(game);
      }
      return log;
    }

    expect(transcript(42), transcript(42));
  });

  test('a mid-round save restores and plays to the end', () {
    final game = _allAiGame(7, 4);
    for (var i = 0; i < 6 && !game.isGameOver; i++) {
      runAiTurn(game).toList();
    }
    if (game.isGameOver) game.startNextRound();

    final saved = jsonEncode(game.toJson());
    final restored = Game.fromJson(
      jsonDecode(saved) as Map<String, dynamic>,
      random: Random(1),
    );

    expect(jsonEncode(restored.toJson()), saved);
    for (final p in restored.players) {
      for (final s in p.spreads) {
        expect(restored.spreadsOnTable, contains(same(s)));
        expect(s.owner, same(p));
      }
    }

    _playRound(restored);
    expect(restored.winner, isNotNull);
  });
}

extension on Game {
  /// Settles a finished round and starts the next one. True if the match ended.
  bool settleRoundIfOver() {
    if (!isGameOver) return false;
    if (settleRound().matchEnded) return true;
    startNextRound();
    return false;
  }
}
