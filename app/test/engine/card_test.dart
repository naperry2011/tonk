import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

void main() {
  group('point values', () {
    test('values an Ace at 1', () {
      expect(Card(Suit.hearts, 'A').value, 1);
    });

    test('values number cards at face value', () {
      for (final rank in ['2', '3', '4', '5', '6', '7', '8', '9', '10']) {
        expect(Card(Suit.spades, rank).value, int.parse(rank));
      }
    });

    test('values face cards at 10', () {
      expect(Card(Suit.clubs, 'J').value, 10);
      expect(Card(Suit.clubs, 'Q').value, 10);
      expect(Card(Suit.clubs, 'K').value, 10);
    });
  });

  group('rank ordering', () {
    test('orders A low through K high', () {
      expect(Card(Suit.hearts, 'A').rankIndex, 0);
      expect(Card(Suit.hearts, 'K').rankIndex, 12);
    });

    test('exposes 13 ranks and 4 suits', () {
      expect(ranks, hasLength(13));
      expect(Suit.values, hasLength(4));
    });
  });

  group('color and identity', () {
    test('treats hearts and diamonds as red', () {
      expect(Card(Suit.hearts, '5').isRed, isTrue);
      expect(Card(Suit.diamonds, '5').isRed, isTrue);
      expect(Card(Suit.clubs, '5').isRed, isFalse);
      expect(Card(Suit.spades, '5').isRed, isFalse);
    });

    test('compares cards by suit and rank', () {
      expect(Card(Suit.hearts, '7'), Card(Suit.hearts, '7'));
      expect(Card(Suit.hearts, '7'), isNot(Card(Suit.spades, '7')));
    });

    test('round-trips through JSON', () {
      final card = Card(Suit.diamonds, 'Q');
      final restored = Card.fromJson(card.toJson());
      expect(restored, card);
      expect(restored.value, 10);
    });
  });
}
