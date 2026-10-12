import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

Card c(String rank, [Suit suit = Suit.hearts]) => Card(suit, rank);

void main() {
  group('hand management', () {
    test('adds and removes cards by equality', () {
      final p = Player('Test')..addCards([c('5'), c('K', Suit.spades)]);
      expect(p.cardCount, 2);

      final removed = p.removeCard(c('K', Suit.spades));
      expect(removed?.rank, 'K');
      expect(p.cardCount, 1);
      expect(p.removeCard(c('Q')), isNull);
    });

    test('calculates hand points', () {
      final p = Player('Test')..addCards([c('A'), c('10'), c('J')]);
      expect(p.calculatePoints(), 21);
    });

    test('reports an empty hand', () {
      final p = Player('Test');
      expect(p.hasEmptyHand(), isTrue);
      p.addCard(c('2'));
      expect(p.hasEmptyHand(), isFalse);
    });

    test('reorders cards within bounds and ignores out-of-bounds moves', () {
      final p = Player('Test')..addCards([c('2'), c('3'), c('4')]);
      p.reorderCard(0, 2);
      expect(p.hand.map((card) => card.rank), ['3', '4', '2']);
      p.reorderCard(0, 5);
      expect(p.hand.map((card) => card.rank), ['3', '4', '2']);
    });
  });

  group('betting', () {
    test('deducts chips on a bet and tracks the current bet', () {
      final p = Player('Test')..chips = 100;
      expect(p.bet(30), 30);
      expect(p.chips, 70);
      expect(p.currentBet, 30);
    });

    test('caps a bet at remaining chips (all-in)', () {
      final p = Player('Test')..chips = 20;
      expect(p.bet(50), 20);
      expect(p.chips, 0);
      expect(p.isAllIn(), isTrue);
    });

    test('checks affordability', () {
      final p = Player('Test')..chips = 25;
      expect(p.canAfford(25), isTrue);
      expect(p.canAfford(26), isFalse);
    });
  });
}
