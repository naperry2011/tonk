import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

Card c(String rank, [Suit suit = Suit.hearts]) => Card(suit, rank);

/// Human in seat 0, AI in seat 1, AI to act at start of turn.
({Game game, ComputerPlayer ai}) aiToAct(List<Card> aiHand) {
  final game = Game()..initialize(2);
  final ai = game.players[1] as ComputerPlayer;
  game.players[0].hand = [c('K', Suit.clubs), c('Q', Suit.clubs)];
  ai.hand = aiHand;
  game
    ..winner = null
    ..winCondition = null
    ..spreadsOnTable = []
    ..currentPlayerIndex = 1
    ..phase = Phase.startOfTurn;
  return (game: game, ai: ai);
}

void main() {
  test('knocks with a very low hand', () {
    final (:game, ai: _) = aiToAct([c('A'), c('2')]);
    final actions = runAiTurn(game).toList();
    expect(actions.single, isA<AiKnocked>());
    expect(game.winCondition, WinCondition.knock);
  });

  test('a normal turn draws then discards and passes play', () {
    final (:game, :ai) = aiToAct([
      c('K'),
      c('9', Suit.spades),
      c('7', Suit.diamonds),
      c('J', Suit.clubs),
      c('2', Suit.spades),
    ]);
    final actions = runAiTurn(game).toList();
    expect(actions.whereType<AiDrew>(), hasLength(1));
    expect(actions.last, isA<AiDiscarded>());
    expect(ai.cardCount, 5);
    expect(game.currentPlayer.isHuman, isTrue);
    expect(game.phase, Phase.startOfTurn);
  });

  test('lays a spread before drawing and Tonks when the hand empties', () {
    final (:game, :ai) = aiToAct([c('8'), c('9'), c('10')]);
    final actions = runAiTurn(game).toList();
    expect(actions.single, isA<AiLaidSpread>());
    expect(game.winner, same(ai));
    expect(game.winCondition, WinCondition.tonk);
  });

  test('actions apply lazily, one per step', () {
    final (:game, ai: _) = aiToAct([
      c('K'),
      c('9', Suit.spades),
      c('7', Suit.diamonds),
      c('J', Suit.clubs),
      c('2', Suit.spades),
    ]);
    final steps = runAiTurn(game).iterator;
    expect(game.phase, Phase.startOfTurn);
    steps.moveNext();
    expect(steps.current, isA<AiProceededToDraw>());
    expect(game.phase, Phase.draw);
    steps.moveNext();
    expect(steps.current, isA<AiDrew>());
    expect(game.phase, Phase.action);
  });

  test('refuses to run for a human seat', () {
    final game = Game()..initialize(2);
    game
      ..currentPlayerIndex = 0
      ..phase = Phase.startOfTurn;
    expect(() => runAiTurn(game).toList(), throwsA(isA<GameRuleException>()));
  });
}
