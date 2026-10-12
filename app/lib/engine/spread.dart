import 'card.dart';
import 'player.dart';
import 'rules.dart';

enum SpreadType { book, run }

typedef SpreadValidation = ({bool valid, SpreadType? type});

/// A spread found in a hand but not yet laid on the table.
typedef SpreadCandidate = ({SpreadType type, List<Card> cards});

/// A book (3-4 of a rank) or run (3+ sequential, same suit) on the table.
class Spread {
  Spread(List<Card> cards, this.type, this.owner, {String? id})
    : cards = List.of(cards),
      id = id ?? 'spread-$_idSeed-${_nextId++}';

  static int _nextId = 1;

  /// Distinguishes ids across app launches, so restored saves never collide.
  static final String _idSeed = DateTime.now().microsecondsSinceEpoch
      .toRadixString(36);

  final List<Card> cards;
  final SpreadType type;
  final Player? owner;
  final String id;

  static bool isValidBook(List<Card> cards) {
    if (cards.length < minSpreadSize || cards.length > 4) return false;
    final rank = cards.first.rank;
    return cards.every((c) => c.rank == rank);
  }

  static bool isValidRun(List<Card> cards) {
    if (cards.length < minSpreadSize) return false;
    final suit = cards.first.suit;
    if (!cards.every((c) => c.suit == suit)) return false;
    final sorted = _sortedByRank(cards);
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].rankIndex != sorted[i - 1].rankIndex + 1) return false;
    }
    return true;
  }

  static SpreadValidation validate(List<Card> cards) {
    if (isValidBook(cards)) return (valid: true, type: SpreadType.book);
    if (isValidRun(cards)) return (valid: true, type: SpreadType.run);
    return (valid: false, type: null);
  }

  bool canAddCard(Card card) => switch (type) {
    SpreadType.book => _canAddToBook(card),
    SpreadType.run => _canAddToRun(card),
  };

  bool _canAddToBook(Card card) =>
      cards.length < 4 && card.rank == cards.first.rank;

  /// Runs extend at either end only.
  bool _canAddToRun(Card card) {
    if (card.suit != cards.first.suit) return false;
    final sorted = _sortedByRank(cards);
    final index = card.rankIndex;
    return index == sorted.first.rankIndex - 1 ||
        index == sorted.last.rankIndex + 1;
  }

  void addCard(Card card) {
    if (!canAddCard(card)) {
      throw StateError('Cannot add this card to the spread');
    }
    cards.add(card);
    if (type == SpreadType.run) {
      cards.sort((a, b) => a.rankIndex - b.rankIndex);
    }
  }

  int get points => cards.fold(0, (sum, c) => sum + c.value);

  String get description {
    if (type == SpreadType.book) return '${cards.first.rank}s';
    final sorted = _sortedByRank(cards);
    return '${sorted.first.rank}-${sorted.last.rank} of ${cards.first.suit.name}';
  }

  Map<String, dynamic> toJson() => {
    'cards': cards.map((c) => c.toJson()).toList(),
    'type': type.name,
    'ownerId': owner?.id,
    'id': id,
  };

  factory Spread.fromJson(
    Map<String, dynamic> json,
    Player? Function(String? id) ownerLookup,
  ) => Spread(
    (json['cards'] as List)
        .map((c) => Card.fromJson(c as Map<String, dynamic>))
        .toList(),
    SpreadType.values.byName(json['type'] as String),
    ownerLookup(json['ownerId'] as String?),
    id: json['id'] as String,
  );

  static List<Card> _sortedByRank(List<Card> cards) =>
      List.of(cards)..sort((a, b) => a.rankIndex - b.rankIndex);
}

/// All books and runs that can be formed from [cards].
List<SpreadCandidate> findPossibleSpreads(List<Card> cards) {
  final spreads = <SpreadCandidate>[];

  final byRank = <String, List<Card>>{};
  final bySuit = <Suit, List<Card>>{};
  for (final card in cards) {
    (byRank[card.rank] ??= []).add(card);
    (bySuit[card.suit] ??= []).add(card);
  }

  for (final rankCards in byRank.values) {
    if (rankCards.length >= minSpreadSize) {
      spreads.add((type: SpreadType.book, cards: rankCards.take(4).toList()));
    }
  }

  for (final suitCards in bySuit.values) {
    for (final run in _findConsecutiveRuns(suitCards)) {
      spreads.add((type: SpreadType.run, cards: run));
    }
  }

  return spreads;
}

List<List<Card>> _findConsecutiveRuns(List<Card> cards) {
  if (cards.length < minSpreadSize) return [];
  final sorted = List.of(cards)..sort((a, b) => a.rankIndex - b.rankIndex);

  final runs = <List<Card>>[];
  var current = [sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i].rankIndex == sorted[i - 1].rankIndex + 1) {
      current.add(sorted[i]);
    } else {
      if (current.length >= minSpreadSize) runs.add(current);
      current = [sorted[i]];
    }
  }
  if (current.length >= minSpreadSize) runs.add(current);
  return runs;
}
