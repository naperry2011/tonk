import 'dart:math';

import 'ai_style.dart';
import 'card.dart';
import 'player.dart';
import 'rules.dart';
import 'spread.dart';

enum DrawSource { deck, discard }

typedef HitOpportunity = ({Card card, Spread spread});

/// Computer-controlled player. Turn sequencing lives in ai_turn.dart.
class ComputerPlayer extends Player {
  ComputerPlayer(
    super.name, {
    this.style = const AiStyle(),
    this.characterId,
    Random? random,
    super.id,
  }) : _random = random ?? Random();

  final AiStyle style;

  /// Which roster character this seat is, if any (used by the app for
  /// avatars and table talk).
  final String? characterId;
  final Random _random;

  DrawSource decideDraw(Card? discardTop) {
    if (discardTop == null) return DrawSource.deck;

    final current = findPossibleSpreads(hand);
    final withDiscard = findPossibleSpreads([...hand, discardTop]);
    if (withDiscard.length > current.length) return DrawSource.discard;

    if (helpsNearComplete(discardTop)) return DrawSource.discard;

    // Low card that pairs with one already held.
    final lowLimit = style.takesLowDiscards ? 5 : 3;
    if (discardTop.value <= lowLimit &&
        hand.any((c) => c.rank == discardTop.rank)) {
      return DrawSource.discard;
    }

    return DrawSource.deck;
  }

  /// True if [card] would make 3 of a kind, or extends a same-suit pair.
  bool helpsNearComplete(Card card) {
    if (hand.where((c) => c.rank == card.rank).length >= 2) return true;

    final sameSuit = hand.where((c) => c.suit == card.suit).toList();
    for (final handCard in sameSuit) {
      if ((handCard.rankIndex - card.rankIndex).abs() != 1) continue;
      for (final other in sameSuit) {
        if (identical(other, handCard)) continue;
        final diffToNew = (other.rankIndex - card.rankIndex).abs();
        final diffToHand = (other.rankIndex - handCard.rankIndex).abs();
        if (diffToNew == 2 || diffToHand == 1) return true;
      }
    }
    return false;
  }

  SpreadCandidate? findBestSpread() {
    final spreads = findPossibleSpreads(hand);
    if (spreads.isEmpty) return null;
    spreads.sort(_byPointsDesc);
    return spreads.first;
  }

  /// Greedily picks the highest-point spreads that don't share cards.
  List<SpreadCandidate> findAllSpreadsToLay() {
    final result = <SpreadCandidate>[];
    final remaining = List.of(hand);

    while (true) {
      final spreads = findPossibleSpreads(remaining);
      if (spreads.isEmpty) break;
      spreads.sort(_byPointsDesc);
      final best = spreads.first;
      result.add(best);
      for (final card in best.cards) {
        remaining.remove(card);
      }
    }
    return result;
  }

  /// Hits sorted highest card value first, to shed points.
  List<HitOpportunity> findHitOpportunities(List<Spread> spreadsOnTable) {
    final hits = <HitOpportunity>[
      for (final spread in spreadsOnTable)
        for (final card in hand)
          if (spread.canAddCard(card)) (card: card, spread: spread),
    ];
    hits.sort((a, b) => b.card.value - a.card.value);
    return hits;
  }

  /// Highest-value card that doesn't contribute to a potential spread.
  Card decideDiscard() {
    final contributing = getSpreadContributingCards().toSet();
    final candidates = hand.where((c) => !contributing.contains(c)).toList();
    final pool = candidates.isNotEmpty ? candidates : List.of(hand);
    pool.sort((a, b) => b.value - a.value);
    return pool.first;
  }

  /// Pairs of a rank, and same-suit cards within 2 ranks of each other.
  List<Card> getSpreadContributingCards() {
    final contributing = <Card>{};

    final byRank = <String, List<Card>>{};
    final bySuit = <Suit, List<Card>>{};
    for (final card in hand) {
      (byRank[card.rank] ??= []).add(card);
      (bySuit[card.suit] ??= []).add(card);
    }

    for (final cards in byRank.values) {
      if (cards.length >= 2) contributing.addAll(cards);
    }

    for (final cards in bySuit.values) {
      if (cards.length < 2) continue;
      final sorted = List.of(cards)..sort((a, b) => a.rankIndex - b.rankIndex);
      for (var i = 0; i < sorted.length - 1; i++) {
        final diff = sorted[i + 1].rankIndex - sorted[i].rankIndex;
        if (diff == 1 || diff == 2) {
          contributing
            ..add(sorted[i])
            ..add(sorted[i + 1]);
        }
      }
    }

    return contributing.toList();
  }

  bool shouldKnock() {
    final points = calculatePoints();
    if (points <= style.knockAlwaysAt) return true;
    if (points <= style.knockMaybeAt) {
      return countSpreadPotential() == 0 || hand.length <= 2;
    }
    return false;
  }

  int countSpreadPotential() => findPossibleSpreads(hand).length;

  /// Raise amount, or 0 for no raise.
  int decideBet() {
    if (chips <= 0) return 0;

    final points = calculatePoints();
    final double raiseChance;
    final int maxRaiseIndex;
    if (countSpreadPotential() > 0) {
      raiseChance = 0.30;
      maxRaiseIndex = 2;
    } else if (points < 20) {
      raiseChance = 0.20;
      maxRaiseIndex = 1;
    } else if (points < 35) {
      raiseChance = 0.10;
      maxRaiseIndex = 0;
    } else {
      raiseChance = 0.05;
      maxRaiseIndex = 0;
    }

    if (_random.nextDouble() < raiseChance * style.raiseAppetite) {
      final amount = Betting.raiseOptions[_random.nextInt(maxRaiseIndex + 1)];
      if (canAfford(amount)) return amount;
      if (chips > 0) return chips;
    }
    return 0;
  }

  /// Calls a raise, or folds (sits out the round). Good hands always call;
  /// the worse the hand and the bigger the raise, the likelier a fold,
  /// scaled by [AiStyle.foldChance].
  bool shouldCall(int amountToCall) {
    if (chips <= 0) return false;
    final points = calculatePoints();
    if (points <= 15 || countSpreadPotential() > 0) return true;

    final weakness = ((points - 15) / 35).clamp(0.0, 1.0);
    final size = amountToCall >= 50 || !canAfford(amountToCall) ? 1.5 : 1.0;
    final foldOdds = (style.foldChance * weakness * size).clamp(0.0, 1.0);
    return _random.nextDouble() >= foldOdds;
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'isComputer': true,
    'style': style.toJson(),
    'characterId': characterId,
  };

  static int _byPointsDesc(SpreadCandidate a, SpreadCandidate b) =>
      _points(b.cards) - _points(a.cards);

  static int _points(List<Card> cards) =>
      cards.fold(0, (sum, c) => sum + c.value);
}
