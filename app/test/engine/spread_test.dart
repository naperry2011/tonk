import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

Card c(String rank, [Suit suit = Suit.hearts]) => Card(suit, rank);

void main() {
  group('isValidBook', () {
    test('accepts 3 cards of the same rank', () {
      expect(
        Spread.isValidBook([c('7'), c('7', Suit.clubs), c('7', Suit.spades)]),
        isTrue,
      );
    });

    test('accepts 4 cards of the same rank', () {
      expect(
        Spread.isValidBook([for (final s in Suit.values) c('K', s)]),
        isTrue,
      );
    });

    test('rejects fewer than 3 cards', () {
      expect(Spread.isValidBook([c('7'), c('7', Suit.clubs)]), isFalse);
    });

    test('rejects mixed ranks', () {
      expect(
        Spread.isValidBook([c('7'), c('7', Suit.clubs), c('8', Suit.spades)]),
        isFalse,
      );
    });
  });

  group('isValidRun', () {
    test('accepts 3 sequential cards of the same suit', () {
      expect(Spread.isValidRun([c('4'), c('5'), c('6')]), isTrue);
    });

    test('accepts unsorted input', () {
      expect(Spread.isValidRun([c('6'), c('4'), c('5')]), isTrue);
    });

    test('treats the Ace as low (A-2-3 is valid)', () {
      expect(Spread.isValidRun([c('A'), c('2'), c('3')]), isTrue);
    });

    test('does not wrap around (Q-K-A is invalid)', () {
      expect(Spread.isValidRun([c('Q'), c('K'), c('A')]), isFalse);
    });

    test('rejects mixed suits', () {
      expect(Spread.isValidRun([c('4'), c('5', Suit.clubs), c('6')]), isFalse);
    });

    test('rejects gaps in the sequence', () {
      expect(Spread.isValidRun([c('4'), c('5'), c('7')]), isFalse);
    });
  });

  group('validate', () {
    test('identifies books', () {
      final v = Spread.validate([
        c('9'),
        c('9', Suit.clubs),
        c('9', Suit.spades),
      ]);
      expect(v, (valid: true, type: SpreadType.book));
    });

    test('identifies runs', () {
      expect(Spread.validate([c('9'), c('10'), c('J')]), (
        valid: true,
        type: SpreadType.run,
      ));
    });

    test('rejects invalid sets', () {
      expect(Spread.validate([c('9'), c('10'), c('K')]), (
        valid: false,
        type: null,
      ));
    });
  });

  group('hitting spreads', () {
    test('allows the 4th card of a rank onto a book, but not a 5th', () {
      final book = Spread(
        [c('7'), c('7', Suit.clubs), c('7', Suit.spades)],
        SpreadType.book,
        null,
      );
      expect(book.canAddCard(c('7', Suit.diamonds)), isTrue);
      book.addCard(c('7', Suit.diamonds));
      expect(book.canAddCard(c('7')), isFalse);
    });

    test('rejects a different rank on a book', () {
      final book = Spread(
        [c('7'), c('7', Suit.clubs), c('7', Suit.spades)],
        SpreadType.book,
        null,
      );
      expect(book.canAddCard(c('8', Suit.diamonds)), isFalse);
    });

    test('allows extending a run at either end only', () {
      final run = Spread([c('5'), c('6'), c('7')], SpreadType.run, null);
      expect(run.canAddCard(c('4')), isTrue);
      expect(run.canAddCard(c('8')), isTrue);
      expect(run.canAddCard(c('9')), isFalse);
      expect(run.canAddCard(c('4', Suit.clubs)), isFalse);
    });

    test('keeps runs sorted after adding and throws on invalid adds', () {
      final run = Spread([c('5'), c('6'), c('7')], SpreadType.run, null);
      run.addCard(c('4'));
      expect(run.cards.map((card) => card.rank), ['4', '5', '6', '7']);
      expect(() => run.addCard(c('J')), throwsStateError);
    });
  });

  test('points sums card values', () {
    final run = Spread([c('9'), c('10'), c('J')], SpreadType.run, null);
    expect(run.points, 29);
  });

  group('findPossibleSpreads', () {
    test('finds books and runs in a hand', () {
      final hand = [
        c('7'),
        c('7', Suit.clubs),
        c('7', Suit.spades),
        c('2', Suit.diamonds),
        c('3', Suit.diamonds),
        c('4', Suit.diamonds),
      ];
      final types = findPossibleSpreads(hand).map((s) => s.type).toSet();
      expect(types, {SpreadType.book, SpreadType.run});
    });

    test('caps books at 4 cards', () {
      final hand = [for (final s in Suit.values) c('Q', s)];
      expect(findPossibleSpreads(hand).single.cards, hasLength(4));
    });

    test('returns nothing for a spreadless hand', () {
      final hand = [
        c('2'),
        c('5', Suit.clubs),
        c('9', Suit.spades),
        c('K', Suit.diamonds),
      ];
      expect(findPossibleSpreads(hand), isEmpty);
    });
  });
}
