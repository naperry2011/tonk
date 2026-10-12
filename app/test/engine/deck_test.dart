import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

void main() {
  test('contains 52 unique cards', () {
    final deck = Deck();
    expect(deck.cardsRemaining, 52);
    expect(deck.cards.map((c) => c.id).toSet(), hasLength(52));
  });

  test('draw removes a card and returns it', () {
    final deck = Deck();
    expect(deck.draw(), isA<Card>());
    expect(deck.cardsRemaining, 51);
  });

  test(
    'returns null when the stock is empty (no reshuffle per Tonk rules)',
    () {
      final deck = Deck();
      while (!deck.isEmpty) {
        deck.draw();
      }
      expect(deck.draw(), isNull);
    },
  );

  test('manages the discard pile', () {
    final deck = Deck();
    expect(deck.topDiscard, isNull);

    final first = deck.draw()!;
    final second = deck.draw()!;
    deck
      ..discard(first)
      ..discard(second);

    expect(deck.topDiscard, same(second));
    expect(deck.drawFromDiscard(), same(second));
    expect(deck.topDiscard, same(first));
  });

  test('round-trips through JSON', () {
    final deck = Deck();
    deck.discard(deck.draw()!);
    final restored = Deck.fromJson(deck.toJson());
    expect(restored.cardsRemaining, 51);
    expect(restored.discardPile, hasLength(1));
    expect(restored.topDiscard, deck.topDiscard);
    expect(restored.cards, deck.cards);
  });
}
