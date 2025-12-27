// Card suits and ranks constants
export const SUITS = ['hearts', 'diamonds', 'clubs', 'spades'];
export const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
export const SUIT_SYMBOLS = {
  hearts: '\u2665',
  diamonds: '\u2666',
  clubs: '\u2663',
  spades: '\u2660'
};

/**
 * Represents a single playing card
 */
export class Card {
  constructor(suit, rank) {
    this.suit = suit;
    this.rank = rank;
    this.value = this.calculateValue();
    this.id = `${rank}-${suit}`;
  }

  /**
   * Calculate the point value of this card
   * A = 1, 2-10 = face value, J/Q/K = 10
   */
  calculateValue() {
    if (this.rank === 'A') return 1;
    if (['J', 'Q', 'K'].includes(this.rank)) return 10;
    return parseInt(this.rank, 10);
  }

  /**
   * Get the suit symbol for display
   */
  getSuitSymbol() {
    return SUIT_SYMBOLS[this.suit];
  }

  /**
   * Check if this card is red (hearts or diamonds)
   */
  isRed() {
    return this.suit === 'hearts' || this.suit === 'diamonds';
  }

  /**
   * Get the numeric rank index for comparison (used in runs)
   */
  getRankIndex() {
    return RANKS.indexOf(this.rank);
  }

  /**
   * String representation for display
   */
  toString() {
    return `${this.rank}${this.getSuitSymbol()}`;
  }

  /**
   * Check if this card equals another card
   */
  equals(other) {
    return this.suit === other.suit && this.rank === other.rank;
  }

  /**
   * Create a unique identifier for this card
   */
  toJSON() {
    return {
      suit: this.suit,
      rank: this.rank
    };
  }

  /**
   * Create a Card instance from JSON
   */
  static fromJSON(json) {
    return new Card(json.suit, json.rank);
  }
}
