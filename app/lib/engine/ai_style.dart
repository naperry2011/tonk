/// Tunable play style for a ComputerPlayer. Defaults match the web AI.
class AiStyle {
  const AiStyle({
    this.knockAlwaysAt = 3,
    this.knockMaybeAt = 5,
    this.raiseAppetite = 1.0,
    this.foldChance = 0.3,
    this.takesLowDiscards = false,
  });

  /// Always knocks with this many points or fewer.
  final int knockAlwaysAt;

  /// Knocks up to this many points when the hand has no spread potential or
  /// only 1-2 cards.
  final int knockMaybeAt;

  /// Multiplier on the chance of raising.
  final double raiseAppetite;

  /// Chance of passing on a big raise while holding a bad hand.
  final double foldChance;

  /// Takes any discard of value 5 or less that pairs with a held card
  /// (default AI only does this for A-3).
  final bool takesLowDiscards;

  Map<String, dynamic> toJson() => {
    'knockAlwaysAt': knockAlwaysAt,
    'knockMaybeAt': knockMaybeAt,
    'raiseAppetite': raiseAppetite,
    'foldChance': foldChance,
    'takesLowDiscards': takesLowDiscards,
  };

  factory AiStyle.fromJson(Map<String, dynamic> json) => AiStyle(
    knockAlwaysAt: json['knockAlwaysAt'] as int? ?? 3,
    knockMaybeAt: json['knockMaybeAt'] as int? ?? 5,
    raiseAppetite: (json['raiseAppetite'] as num?)?.toDouble() ?? 1.0,
    foldChance: (json['foldChance'] as num?)?.toDouble() ?? 0.3,
    takesLowDiscards: json['takesLowDiscards'] as bool? ?? false,
  );
}
