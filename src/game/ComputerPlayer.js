import { Player } from './Player.js';
import { Spread, findPossibleSpreads } from './Spread.js';

/**
 * Computer-controlled player with AI decision making
 */
export class ComputerPlayer extends Player {
  constructor(name, difficulty = 'medium') {
    super(name, false);
    this.difficulty = difficulty;
  }

  /**
   * Decide whether to draw from deck or discard pile
   */
  decideDraw(discardTop) {
    if (!discardTop) return 'deck';

    // Check if discard would complete a spread
    const currentSpreads = findPossibleSpreads(this.hand);
    const handWithDiscard = [...this.hand, discardTop];
    const spreadsWithDiscard = findPossibleSpreads(handWithDiscard);

    // Take discard if it creates a new spread opportunity
    if (spreadsWithDiscard.length > currentSpreads.length) {
      return 'discard';
    }

    // Check if discard contributes to near-complete spread
    if (this.helpsNearComplete(discardTop)) {
      return 'discard';
    }

    // Check if discard is low value (1-3) and same rank as a card we have
    if (discardTop.value <= 3) {
      const sameRank = this.hand.filter(c => c.rank === discardTop.rank);
      if (sameRank.length >= 1) {
        return 'discard';
      }
    }

    return 'deck';
  }

  /**
   * Check if a card helps form a near-complete spread
   */
  helpsNearComplete(card) {
    // Check for 2 of a kind (would make 3 with this card)
    const sameRank = this.hand.filter(c => c.rank === card.rank);
    if (sameRank.length >= 2) return true;

    // Check for 2 in a row of same suit
    const sameSuit = this.hand.filter(c => c.suit === card.suit);
    for (const handCard of sameSuit) {
      const diff = Math.abs(handCard.getRankIndex() - card.getRankIndex());
      if (diff === 1) {
        // Adjacent card - check if there's another adjacent
        for (const other of sameSuit) {
          if (other !== handCard) {
            const diffToNew = Math.abs(other.getRankIndex() - card.getRankIndex());
            const diffToHand = Math.abs(other.getRankIndex() - handCard.getRankIndex());
            if (diffToNew === 2 || diffToHand === 1) return true;
          }
        }
      }
    }

    return false;
  }

  /**
   * Find the best spread to lay down
   */
  findBestSpread() {
    const possibleSpreads = findPossibleSpreads(this.hand);

    if (possibleSpreads.length === 0) return null;

    // Sort by point value (lay down highest point spreads first)
    possibleSpreads.sort((a, b) => {
      const pointsA = a.cards.reduce((sum, c) => sum + c.value, 0);
      const pointsB = b.cards.reduce((sum, c) => sum + c.value, 0);
      return pointsB - pointsA;
    });

    return possibleSpreads[0];
  }

  /**
   * Find all spreads the AI should lay down this turn
   */
  findAllSpreadsToLay() {
    const spreads = [];
    let remainingHand = [...this.hand];

    while (true) {
      const possibleSpreads = findPossibleSpreads(remainingHand);
      if (possibleSpreads.length === 0) break;

      // Find highest value spread
      possibleSpreads.sort((a, b) => {
        const pointsA = a.cards.reduce((sum, c) => sum + c.value, 0);
        const pointsB = b.cards.reduce((sum, c) => sum + c.value, 0);
        return pointsB - pointsA;
      });

      const best = possibleSpreads[0];
      spreads.push(best);

      // Remove these cards from consideration
      for (const card of best.cards) {
        const idx = remainingHand.findIndex(c => c.equals(card));
        if (idx !== -1) {
          remainingHand.splice(idx, 1);
        }
      }
    }

    return spreads;
  }

  /**
   * Find cards that could hit existing spreads
   */
  findHitOpportunities(spreadsOnTable) {
    const hits = [];

    for (const spread of spreadsOnTable) {
      for (const card of this.hand) {
        if (spread.canAddCard(card)) {
          hits.push({ card, spread });
        }
      }
    }

    // Sort by card value (highest first - get rid of high point cards)
    hits.sort((a, b) => b.card.value - a.card.value);

    return hits;
  }

  /**
   * Decide which card to discard
   */
  decideDiscard() {
    // Get cards that contribute to potential spreads
    const spreadCards = this.getSpreadContributingCards();
    const spreadCardIds = new Set(spreadCards.map(c => c.id));

    // Filter out cards that help spreads
    const nonSpreadCards = this.hand.filter(c => !spreadCardIds.has(c.id));

    // Sort by value (highest first)
    if (nonSpreadCards.length > 0) {
      nonSpreadCards.sort((a, b) => b.value - a.value);
      return nonSpreadCards[0];
    }

    // If all cards contribute to spreads, discard highest value
    const sorted = [...this.hand].sort((a, b) => b.value - a.value);
    return sorted[0];
  }

  /**
   * Get cards that contribute to potential spreads
   */
  getSpreadContributingCards() {
    const contributing = new Set();

    // Check for cards in potential books (2+ of same rank)
    const byRank = {};
    for (const card of this.hand) {
      if (!byRank[card.rank]) byRank[card.rank] = [];
      byRank[card.rank].push(card);
    }
    for (const cards of Object.values(byRank)) {
      if (cards.length >= 2) {
        cards.forEach(c => contributing.add(c));
      }
    }

    // Check for cards in potential runs (2+ sequential same suit)
    const bySuit = {};
    for (const card of this.hand) {
      if (!bySuit[card.suit]) bySuit[card.suit] = [];
      bySuit[card.suit].push(card);
    }
    for (const cards of Object.values(bySuit)) {
      if (cards.length < 2) continue;
      const sorted = [...cards].sort((a, b) => a.getRankIndex() - b.getRankIndex());
      for (let i = 0; i < sorted.length - 1; i++) {
        const diff = sorted[i + 1].getRankIndex() - sorted[i].getRankIndex();
        if (diff === 1 || diff === 2) {
          contributing.add(sorted[i]);
          contributing.add(sorted[i + 1]);
        }
      }
    }

    return [...contributing];
  }

  /**
   * Decide whether to knock
   */
  shouldKnock() {
    const points = this.calculatePoints();

    // Always knock with 0-3 points
    if (points <= 3) return true;

    // Knock with 4-5 points if no spread potential or few cards
    if (points <= 5) {
      const spreadPotential = this.countSpreadPotential();
      if (spreadPotential === 0 || this.hand.length <= 2) {
        return true;
      }
    }

    return false;
  }

  /**
   * Count potential spreads in hand
   */
  countSpreadPotential() {
    return findPossibleSpreads(this.hand).length;
  }

  /**
   * Execute a complete AI turn
   * Returns array of actions taken
   */
  async executeTurn(game, delay = 500) {
    const actions = [];

    // Check if should knock
    if (this.shouldKnock()) {
      actions.push({ type: 'knock' });
      return actions;
    }

    // Decide draw source
    const discardTop = game.getTopDiscard();
    const drawSource = this.decideDraw(discardTop);
    actions.push({ type: 'draw', source: drawSource });

    // Find spreads to lay down
    const spreadsToLay = this.findAllSpreadsToLay();
    for (const spreadInfo of spreadsToLay) {
      actions.push({ type: 'spread', cards: spreadInfo.cards, spreadType: spreadInfo.type });
    }

    // Find hit opportunities
    const hits = this.findHitOpportunities(game.spreadsOnTable);
    for (const hit of hits) {
      // Only hit if we still have the card
      if (this.hasCard(hit.card)) {
        actions.push({ type: 'hit', card: hit.card, spread: hit.spread });
      }
    }

    // Decide discard (if hand not empty)
    if (this.hand.length > 0) {
      const cardToDiscard = this.decideDiscard();
      actions.push({ type: 'discard', card: cardToDiscard });
    }

    return actions;
  }
}
