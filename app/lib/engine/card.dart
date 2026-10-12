enum Suit {
  hearts('♥'),
  diamonds('♦'),
  clubs('♣'),
  spades('♠');

  const Suit(this.symbol);
  final String symbol;

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

const List<String> ranks = [
  'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', //
];

/// A single playing card. Cards are equal when suit and rank match.
class Card {
  Card(this.suit, this.rank)
    : assert(ranks.contains(rank), 'Unknown rank: $rank'),
      value = _valueOf(rank);

  final Suit suit;
  final String rank;

  /// Point value: A = 1, 2-10 = face value, J/Q/K = 10.
  final int value;

  String get id => '$rank-${suit.name}';

  /// Position in [ranks], used for runs. Ace is low.
  int get rankIndex => ranks.indexOf(rank);

  bool get isRed => suit.isRed;

  static int _valueOf(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J' || rank == 'Q' || rank == 'K') return 10;
    return int.parse(rank);
  }

  @override
  bool operator ==(Object other) =>
      other is Card && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '$rank${suit.symbol}';

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank};

  factory Card.fromJson(Map<String, dynamic> json) =>
      Card(Suit.values.byName(json['suit'] as String), json['rank'] as String);
}
