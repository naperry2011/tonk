import 'dart:math';

import 'card.dart';

/// The stock (draw pile) and discard pile.
class Deck {
  Deck([Random? random]) : _random = random ?? Random() {
    _generate();
    shuffle();
  }

  Deck._empty(this._random);

  final Random _random;
  List<Card> cards = [];
  List<Card> discardPile = [];

  void _generate() {
    cards = [
      for (final suit in Suit.values)
        for (final rank in ranks) Card(suit, rank),
    ];
  }

  /// Fisher-Yates.
  void shuffle() {
    for (var i = cards.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = cards[i];
      cards[i] = cards[j];
      cards[j] = tmp;
    }
  }

  /// Returns null when the stock is empty (no reshuffle per Tonk rules).
  Card? draw() => cards.isEmpty ? null : cards.removeLast();

  void discard(Card card) => discardPile.add(card);

  Card? get topDiscard => discardPile.isEmpty ? null : discardPile.last;

  Card? drawFromDiscard() =>
      discardPile.isEmpty ? null : discardPile.removeLast();

  int get cardsRemaining => cards.length;

  bool get isEmpty => cards.isEmpty;

  void reset() {
    discardPile = [];
    _generate();
    shuffle();
  }

  Map<String, dynamic> toJson() => {
    'cards': cards.map((c) => c.toJson()).toList(),
    'discardPile': discardPile.map((c) => c.toJson()).toList(),
  };

  factory Deck.fromJson(Map<String, dynamic> json, [Random? random]) {
    final deck = Deck._empty(random ?? Random());
    deck.cards = _cardsFromJson(json['cards']);
    deck.discardPile = _cardsFromJson(json['discardPile']);
    return deck;
  }

  static List<Card> _cardsFromJson(Object? list) => (list as List)
      .map((c) => Card.fromJson(c as Map<String, dynamic>))
      .toList();
}
