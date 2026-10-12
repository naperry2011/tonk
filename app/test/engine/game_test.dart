import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

Card c(String rank, [Suit suit = Suit.hearts]) => Card(suit, rank);

/// A 2-player game with forced hands and phase, so tests are deterministic
/// regardless of the shuffled deal (including the rare initial-tonk win).
({Game game, Player human, Player ai}) gameWithHands(
  List<String> humanRanks,
  List<String> aiRanks,
) {
  final game = Game()..initialize(2);
  final [human, ai] = game.players;
  human.hand = [for (final r in humanRanks) c(r, Suit.hearts)];
  ai.hand = [for (final r in aiRanks) c(r, Suit.spades)];
  game
    ..winner = null
    ..winCondition = null
    ..currentPlayerIndex = 0
    ..phase = Phase.startOfTurn;
  return (game: game, human: human, ai: ai);
}

void main() {
  group('initialize', () {
    test('deals 5 cards each, flips one discard, and collects antes', () {
      final game = Game()..initialize(2);

      expect(game.players, hasLength(2));
      expect(game.players.first.isHuman, isTrue);
      for (final p in game.players) {
        expect(p.cardCount, 5);
      }
      expect(game.deck.cardsRemaining, 41);
      expect(game.deck.discardPile, hasLength(1));

      expect(game.pot, 2 * Betting.anteAmount);
      for (final p in game.players) {
        expect(p.chips, Betting.startingChips - Betting.anteAmount);
      }
    });

    test('starts at START_OF_TURN unless an initial tonk ended the round', () {
      final game = Game()..initialize(2);
      if (game.winCondition == WinCondition.initialTonk) {
        expect(game.phase, Phase.gameOver);
        expect(game.winner, isNotNull);
      } else {
        expect(game.phase, Phase.startOfTurn);
      }
    });

    test('rejects unsupported player counts', () {
      expect(() => Game().initialize(1), throwsArgumentError);
      expect(() => Game().initialize(5), throwsArgumentError);
    });

    test('an initial-tonk redeal keeps the antes in the pot', () {
      // First deck deals 50 points to seats 0 and 1; later decks are shuffled.
      var decksBuilt = 0;
      Deck stacked(Random random) {
        final deck = Deck(random);
        if (decksBuilt++ > 0) return deck;
        final tens = [
          for (final s in Suit.values)
            for (final r in ['10', 'J', 'Q', 'K']) Card(s, r),
        ];
        final lows = [
          for (final s in Suit.values)
            for (final r in ['A', '2', '3']) Card(s, r),
        ];
        // Dealt round-robin to 4 seats; draw() pops from the end.
        final dealOrder = [
          for (var i = 0; i < 5; i++) ...[
            tens[i * 2],
            tens[i * 2 + 1],
            lows[i],
            lows[i + 5],
          ],
        ];
        final rest = deck.cards.where((c) => !dealOrder.contains(c));
        deck.cards = [...rest, ...dealOrder.reversed];
        return deck;
      }

      final game = Game(random: Random(1), deckFactory: stacked);
      var redeals = 0;
      game.addListener((e) {
        if (e is InitialTonkDraw) redeals++;
      });
      game.initialize(4);

      expect(redeals, greaterThanOrEqualTo(1));
      expect(game.pot, 4 * Betting.anteAmount);
      final chips = game.players.fold(0, (sum, p) => sum + p.chips);
      expect(chips + game.pot, 4 * Betting.startingChips);
    });
  });

  group('knock', () {
    test('awards the round to the knocker with strictly lowest points', () {
      final (:game, :human, ai: _) = gameWithHands(['A', '2'], ['K', 'Q']);
      game.knock();
      expect(game.winner, same(human));
      expect(game.winCondition, WinCondition.knock);
      expect(game.phase, Phase.gameOver);
    });

    test('catches a knocker who ties (tie does not win)', () {
      final (:game, human: _, :ai) = gameWithHands(['5'], ['5']);
      game.knock();
      expect(game.winner, same(ai));
      expect(game.winCondition, WinCondition.caught);
    });

    test('catches a knocker with higher points', () {
      final (:game, human: _, :ai) = gameWithHands(['K', 'Q'], ['A', '2']);
      game.knock();
      expect(game.winner, same(ai));
      expect(game.winCondition, WinCondition.caught);
    });

    test('only allows knocking at the start of a turn', () {
      final (:game, human: _, ai: _) = gameWithHands(['A'], ['K']);
      game.phase = Phase.action;
      expect(game.knock, throwsA(isA<GameRuleException>()));
    });

    test('emits knock and gameOver events', () {
      final (:game, :human, ai: _) = gameWithHands(['A'], ['K']);
      final events = <Object>[];
      game.addListener((e) {
        if (e is Knocked) events.add('knock');
        if (e is GameOver) events.add(e.condition);
      });
      game.knock();
      expect(events, ['knock', WinCondition.knock]);
      expect(game.winner, same(human));
    });
  });

  group('round scoring and match end', () {
    test("adds losers' hand points to their match scores", () {
      final (:game, :human, :ai) = gameWithHands(['A'], ['K', 'Q']);
      game.knock();
      final losers = game.applyRoundScoring();

      expect(losers, hasLength(1));
      expect(losers.single.player, same(ai));
      expect(losers.single.pointsAdded, 20);
      expect(game.matchScores[ai.id], 20);
      expect(game.matchScores[human.id], 0);
    });

    test('ends the match when a player reaches 100 and the lowest wins', () {
      final (:game, :human, :ai) = gameWithHands(['A'], ['K']);
      game.matchScores[ai.id] = 100;
      expect(game.checkMatchEnd(), isTrue);
      expect(game.matchWinner, same(human));
    });

    test('does not end the match below the limit', () {
      final (:game, human: _, :ai) = gameWithHands(['A'], ['K']);
      game.matchScores[ai.id] = 99;
      expect(game.checkMatchEnd(), isFalse);
    });

    test('settleRound awards the pot, then scores losers', () {
      final (:game, :human, :ai) = gameWithHands(['A'], ['K', 'Q']);
      final pot = game.pot;
      final chipsBefore = human.chips;
      game.knock();
      final result = game.settleRound();
      expect(result.potWinnings, pot);
      expect(human.chips, chipsBefore + pot);
      expect(game.pot, 0);
      expect(result.losers.single.player, same(ai));
      expect(result.matchEnded, isFalse);
    });
  });

  group('turn flow', () {
    test('endTurn advances to the next player and resets to START_OF_TURN', () {
      final (:game, human: _, :ai) = gameWithHands(['A'], ['K']);
      game.phase = Phase.action;
      game.endTurn();
      expect(game.currentPlayer, same(ai));
      expect(game.phase, Phase.startOfTurn);
      expect(game.hasDrawnThisTurn, isFalse);
    });

    test('laying the last cards as a spread is a Tonk', () {
      final (:game, :human, ai: _) = gameWithHands(['4', '5', '6'], ['K']);
      game.laySpread(List.of(human.hand));
      expect(game.winner, same(human));
      expect(game.winCondition, WinCondition.tonk);
    });

    test('rejects laying cards the player does not hold', () {
      final (:game, human: _, ai: _) = gameWithHands(['4', '5'], ['K']);
      expect(
        () => game.laySpread([c('4'), c('5'), c('6')]),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('an empty stock ends the round with lowest points winning', () {
      final (:game, :human, ai: _) = gameWithHands(['A'], ['K']);
      game.deck.cards.clear();
      game.proceedToDraw();
      expect(game.drawFromDeck(), isNull);
      expect(game.winner, same(human));
      expect(game.winCondition, WinCondition.stockEmpty);
    });
  });
}
