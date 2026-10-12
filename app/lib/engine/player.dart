import 'card.dart';
import 'rules.dart' as rules;
import 'spread.dart' show Spread, SpreadCandidate;
import 'spread.dart' as spread_lib;

class Player {
  Player(this.name, {this.isHuman = false, String? id})
    : id = id ?? 'player-$_idSeed-${_nextId++}';

  static int _nextId = 1;

  /// Distinguishes ids across app launches, so restored saves never collide.
  static final String _idSeed = DateTime.now().microsecondsSinceEpoch
      .toRadixString(36);

  final String id;
  final String name;
  final bool isHuman;
  List<Card> hand = [];

  /// Spreads this player has laid down.
  List<Spread> spreads = [];

  /// Initialized by Game.
  int chips = 0;
  int currentBet = 0;
  bool isEliminated = false;

  /// Folded on a raise this round: sits out, can't win the round or pot.
  bool hasFolded = false;

  bool get isActive => !hasFolded;

  void addCard(Card card) => hand.add(card);

  void addCards(Iterable<Card> cards) => hand.addAll(cards);

  /// Removes the first card equal to [card]; returns it, or null if absent.
  Card? removeCard(Card card) {
    final index = hand.indexOf(card);
    return index == -1 ? null : hand.removeAt(index);
  }

  List<Card> removeCards(Iterable<Card> cards) => [
    for (final card in cards) ?removeCard(card),
  ];

  Card? getCard(int index) =>
      index >= 0 && index < hand.length ? hand[index] : null;

  int calculatePoints() => hand.fold(0, (sum, c) => sum + c.value);

  bool canKnock() => rules.canKnock(calculatePoints());

  bool hasEmptyHand() => hand.isEmpty;

  int get cardCount => hand.length;

  List<SpreadCandidate> findPossibleSpreads() =>
      spread_lib.findPossibleSpreads(hand);

  void addSpread(Spread spread) => spreads.add(spread);

  void clearHand() => hand = [];

  void clearSpreads() => spreads = [];

  void reset() {
    clearHand();
    clearSpreads();
    hasFolded = false;
  }

  List<Card> getCardsSortedByValue() =>
      List.of(hand)..sort((a, b) => b.value - a.value);

  List<Card> getCardsSortedBySuit() => List.of(hand)
    ..sort(
      (a, b) => a.suit != b.suit
          ? a.suit.name.compareTo(b.suit.name)
          : a.rankIndex - b.rankIndex,
    );

  bool hasCard(Card card) => hand.contains(card);

  void reorderCard(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= hand.length) return;
    if (toIndex < 0 || toIndex >= hand.length) return;
    if (fromIndex == toIndex) return;
    hand.insert(toIndex, hand.removeAt(fromIndex));
  }

  /// Deducts chips; returns the actual amount bet (capped at chips, all-in).
  int bet(int amount) {
    final actual = amount < chips ? amount : chips;
    chips -= actual;
    currentBet += actual;
    return actual;
  }

  void receiveChips(int amount) => chips += amount;

  void resetBet() => currentBet = 0;

  bool canAfford(int amount) => chips >= amount;

  bool isAllIn() => chips == 0 && currentBet > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hand': hand.map((c) => c.toJson()).toList(),
    'isHuman': isHuman,
    'spreadIds': spreads.map((s) => s.id).toList(),
    'chips': chips,
    'currentBet': currentBet,
    'isEliminated': isEliminated,
    'hasFolded': hasFolded,
  };

  /// Restores hand and chip state. Spreads are re-linked by Game.fromJson.
  void restoreFromJson(Map<String, dynamic> json) {
    hand = (json['hand'] as List)
        .map((c) => Card.fromJson(c as Map<String, dynamic>))
        .toList();
    chips = json['chips'] as int;
    currentBet = json['currentBet'] as int;
    isEliminated = json['isEliminated'] as bool;
    hasFolded = json['hasFolded'] as bool? ?? false;
  }
}
