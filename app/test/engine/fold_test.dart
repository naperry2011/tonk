import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

Card c(String rank, [Suit suit = Suit.hearts]) => Card(suit, rank);

/// Three seats with fixed hands, seat 0 to act at start of turn.
({Game game, Player a, Player b, Player d}) table(
  List<String> aRanks,
  List<String> bRanks,
  List<String> dRanks,
) {
  final game = Game()
    ..initializeWithPlayers([
      Player('A', isHuman: true),
      ComputerPlayer('B'),
      ComputerPlayer('D'),
    ]);
  final [a, b, d] = game.players;
  a.hand = [for (final r in aRanks) c(r, Suit.hearts)];
  b.hand = [for (final r in bRanks) c(r, Suit.spades)];
  d.hand = [for (final r in dRanks) c(r, Suit.clubs)];
  game
    ..winner = null
    ..winCondition = null
    ..currentPlayerIndex = 0
    ..phase = Phase.startOfTurn;
  return (game: game, a: a, b: b, d: d);
}

void main() {
  test('a folded player is skipped in turn order', () {
    final (:game, a: _, :b, :d) = table(['K'], ['Q'], ['J']);
    game.fold(b);
    game.phase = Phase.action;
    game.endTurn();
    expect(game.currentPlayer, same(d));
  });

  test('when everyone else folds, the last player in wins', () {
    final (:game, :a, :b, :d) = table(['K'], ['Q'], ['J']);
    final events = <GameEvent>[];
    game.addListener(events.add);
    game.fold(b);
    expect(game.isGameOver, isFalse);
    game.fold(d);
    expect(game.winner, same(a));
    expect(game.winCondition, WinCondition.allFolded);
    expect(events.whereType<Folded>(), hasLength(2));
  });

  test('a folded player cannot catch a knocker', () {
    // A knocks with 10; B (folded) has 2; D has 9.
    final (:game, :a, :b, :d) = table(['10'], ['2'], ['9']);
    game.fold(b);
    game.currentPlayerIndex = 2; // D is up
    game.phase = Phase.startOfTurn;
    game.knock();
    expect(game.winner, same(d));
    expect(game.winCondition, WinCondition.knock);
    expect(a.hasFolded, isFalse);
  });

  test('an empty stock ignores folded players', () {
    final (:game, :a, :b, d: _) = table(['9'], ['A'], ['K']);
    game.fold(b);
    game.deck.cards.clear();
    game.proceedToDraw();
    game.drawFromDeck();
    expect(game.winner, same(a));
  });

  test('folded players cannot bet and still take penalty points', () {
    final (:game, :a, :b, d: _) = table(['A'], ['K', 'Q'], ['J']);
    game.fold(b);
    expect(() => game.placeBet(b, 10), throwsA(isA<GameRuleException>()));
    game.knock();
    game.settleRound();
    expect(game.winner, same(a));
    expect(game.matchScores[b.id], 20);
  });

  test('folding the current player passes the turn', () {
    final (:game, :a, :b, d: _) = table(['K'], ['Q'], ['J']);
    game.fold(a);
    expect(game.currentPlayer, same(b));
    expect(game.phase, Phase.startOfTurn);
  });

  test('fold state survives save and resets next round', () {
    final (:game, a: _, :b, d: _) = table(['K'], ['Q'], ['J']);
    game.fold(b);
    final restored = Game.fromJson(
      jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>,
    );
    expect(restored.players[1].hasFolded, isTrue);

    game.knock();
    game.settleRound();
    game.startNextRound();
    expect(b.hasFolded, isFalse);
  });

  group('ComputerPlayer.shouldCall', () {
    test('always calls with a good hand', () {
      final ai = ComputerPlayer('X', style: const AiStyle(foldChance: 1))
        ..chips = 500
        ..hand = [c('A'), c('2', Suit.spades), c('5', Suit.clubs)];
      for (var i = 0; i < 50; i++) {
        expect(ai.shouldCall(100), isTrue);
      }
    });

    test('a fold-happy style folds a bad hand to a big raise', () {
      final ai = ComputerPlayer('X', style: const AiStyle(foldChance: 1))
        ..chips = 500
        ..hand = [
          c('K'),
          c('Q', Suit.spades),
          c('J', Suit.clubs),
          c('9', Suit.diamonds),
          c('8'),
        ];
      expect(ai.shouldCall(50), isFalse);
    });

    test('a never-fold style always calls', () {
      final ai = ComputerPlayer('X', style: const AiStyle(foldChance: 0))
        ..chips = 500
        ..hand = [c('K'), c('Q', Suit.spades), c('J', Suit.clubs)];
      for (var i = 0; i < 50; i++) {
        expect(ai.shouldCall(100), isTrue);
      }
    });
  });
}
