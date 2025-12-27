import { RANKS } from './Card.js';
import { MIN_SPREAD_SIZE } from './rules.js';

/**
 * Represents a spread (book or run) of cards
 */
export class Spread {
  constructor(cards, type, owner) {
    this.cards = [...cards];
    this.type = type; // 'book' or 'run'
    this.owner = owner; // Player who created the spread
    this.id = `spread-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Check if a set of cards forms a valid book (3+ same rank)
   */
  static isValidBook(cards) {
    if (!cards || cards.length < MIN_SPREAD_SIZE) return false;
    if (cards.length > 4) return false; // Can't have more than 4 of same rank

    const rank = cards[0].rank;
    return cards.every(card => card.rank === rank);
  }

  /**
   * Check if a set of cards forms a valid run (3+ sequential same suit)
   */
  static isValidRun(cards) {
    if (!cards || cards.length < MIN_SPREAD_SIZE) return false;

    // All cards must be same suit
    const suit = cards[0].suit;
    if (!cards.every(card => card.suit === suit)) return false;

    // Sort cards by rank
    const sorted = [...cards].sort((a, b) => a.getRankIndex() - b.getRankIndex());

    // Check for consecutive ranks
    for (let i = 1; i < sorted.length; i++) {
      const prevIndex = sorted[i - 1].getRankIndex();
      const currIndex = sorted[i].getRankIndex();
      if (currIndex !== prevIndex + 1) return false;
    }

    return true;
  }

  /**
   * Validate cards and return spread info if valid
   */
  static validate(cards) {
    if (Spread.isValidBook(cards)) {
      return { valid: true, type: 'book' };
    }
    if (Spread.isValidRun(cards)) {
      return { valid: true, type: 'run' };
    }
    return { valid: false, type: null };
  }

  /**
   * Check if a card can be added to this spread
   */
  canAddCard(card) {
    if (this.type === 'book') {
      return this.canAddToBook(card);
    } else if (this.type === 'run') {
      return this.canAddToRun(card);
    }
    return false;
  }

  /**
   * Check if a card can be added to a book
   */
  canAddToBook(card) {
    // Book must have same rank, and can't exceed 4 cards
    if (this.cards.length >= 4) return false;
    return card.rank === this.cards[0].rank;
  }

  /**
   * Check if a card can be added to a run
   */
  canAddToRun(card) {
    // Must be same suit
    if (card.suit !== this.cards[0].suit) return false;

    // Sort current cards by rank
    const sorted = [...this.cards].sort((a, b) => a.getRankIndex() - b.getRankIndex());
    const lowestIndex = sorted[0].getRankIndex();
    const highestIndex = sorted[sorted.length - 1].getRankIndex();
    const cardIndex = card.getRankIndex();

    // Can add at either end
    return cardIndex === lowestIndex - 1 || cardIndex === highestIndex + 1;
  }

  /**
   * Add a card to this spread
   */
  addCard(card) {
    if (!this.canAddCard(card)) {
      throw new Error('Cannot add this card to the spread');
    }
    this.cards.push(card);
    // Re-sort for runs
    if (this.type === 'run') {
      this.cards.sort((a, b) => a.getRankIndex() - b.getRankIndex());
    }
  }

  /**
   * Get total points of cards in this spread
   */
  getPoints() {
    return this.cards.reduce((sum, card) => sum + card.value, 0);
  }

  /**
   * Get spread description for display
   */
  getDescription() {
    if (this.type === 'book') {
      return `${this.cards[0].rank}s`;
    } else {
      const sorted = [...this.cards].sort((a, b) => a.getRankIndex() - b.getRankIndex());
      return `${sorted[0].rank}-${sorted[sorted.length - 1].rank} of ${this.cards[0].suit}`;
    }
  }

  /**
   * Serialize spread to JSON
   */
  toJSON() {
    return {
      cards: this.cards.map(c => c.toJSON()),
      type: this.type,
      ownerId: this.owner?.id || null,
      id: this.id
    };
  }
}

/**
 * Helper function to find all possible spreads in a hand
 */
export function findPossibleSpreads(cards) {
  const spreads = [];

  // Find books (same rank)
  const byRank = groupCardsByRank(cards);
  for (const [rank, rankCards] of Object.entries(byRank)) {
    if (rankCards.length >= MIN_SPREAD_SIZE) {
      spreads.push({
        type: 'book',
        cards: rankCards.slice(0, 4) // Max 4 for a book
      });
    }
  }

  // Find runs (sequential same suit)
  const bySuit = groupCardsBySuit(cards);
  for (const [suit, suitCards] of Object.entries(bySuit)) {
    const runs = findConsecutiveRuns(suitCards);
    spreads.push(...runs.map(runCards => ({
      type: 'run',
      cards: runCards
    })));
  }

  return spreads;
}

/**
 * Group cards by rank
 */
function groupCardsByRank(cards) {
  const groups = {};
  for (const card of cards) {
    if (!groups[card.rank]) {
      groups[card.rank] = [];
    }
    groups[card.rank].push(card);
  }
  return groups;
}

/**
 * Group cards by suit
 */
function groupCardsBySuit(cards) {
  const groups = {};
  for (const card of cards) {
    if (!groups[card.suit]) {
      groups[card.suit] = [];
    }
    groups[card.suit].push(card);
  }
  return groups;
}

/**
 * Find all consecutive runs of 3+ cards in a sorted list of same-suit cards
 */
function findConsecutiveRuns(cards) {
  if (cards.length < MIN_SPREAD_SIZE) return [];

  // Sort by rank index
  const sorted = [...cards].sort((a, b) => a.getRankIndex() - b.getRankIndex());

  const runs = [];
  let currentRun = [sorted[0]];

  for (let i = 1; i < sorted.length; i++) {
    const prevIndex = sorted[i - 1].getRankIndex();
    const currIndex = sorted[i].getRankIndex();

    if (currIndex === prevIndex + 1) {
      currentRun.push(sorted[i]);
    } else {
      if (currentRun.length >= MIN_SPREAD_SIZE) {
        runs.push([...currentRun]);
      }
      currentRun = [sorted[i]];
    }
  }

  // Check last run
  if (currentRun.length >= MIN_SPREAD_SIZE) {
    runs.push(currentRun);
  }

  return runs;
}
