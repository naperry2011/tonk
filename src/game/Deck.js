import { Card, SUITS, RANKS } from './Card.js';

/**
 * Represents the deck of cards with draw and discard piles
 */
export class Deck {
  constructor() {
    this.cards = [];
    this.discardPile = [];
    this.generateDeck();
    this.shuffle();
  }

  /**
   * Generate a standard 52-card deck
   */
  generateDeck() {
    this.cards = [];
    for (const suit of SUITS) {
      for (const rank of RANKS) {
        this.cards.push(new Card(suit, rank));
      }
    }
  }

  /**
   * Shuffle the deck using Fisher-Yates algorithm
   */
  shuffle() {
    for (let i = this.cards.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [this.cards[i], this.cards[j]] = [this.cards[j], this.cards[i]];
    }
  }

  /**
   * Draw a card from the deck
   * Returns null if deck is empty (no reshuffle per Tonk rules)
   */
  draw() {
    if (this.cards.length === 0) {
      return null; // Stock is empty
    }
    return this.cards.pop();
  }

  /**
   * Add a card to the discard pile
   */
  discard(card) {
    this.discardPile.push(card);
  }

  /**
   * Get the top card of the discard pile without removing it
   */
  getTopDiscard() {
    if (this.discardPile.length === 0) return null;
    return this.discardPile[this.discardPile.length - 1];
  }

  /**
   * Draw the top card from the discard pile
   */
  drawFromDiscard() {
    return this.discardPile.pop();
  }

  /**
   * Get the number of cards remaining in the draw pile
   */
  get cardsRemaining() {
    return this.cards.length;
  }

  /**
   * Check if stock is empty
   */
  isEmpty() {
    return this.cards.length === 0;
  }

  /**
   * Reset the deck to initial state
   */
  reset() {
    this.discardPile = [];
    this.generateDeck();
    this.shuffle();
  }

  /**
   * Serialize deck state to JSON
   */
  toJSON() {
    return {
      cards: this.cards.map(c => c.toJSON()),
      discardPile: this.discardPile.map(c => c.toJSON())
    };
  }

  /**
   * Restore deck state from JSON
   */
  static fromJSON(json) {
    const deck = new Deck();
    deck.cards = json.cards.map(c => Card.fromJSON(c));
    deck.discardPile = json.discardPile.map(c => Card.fromJSON(c));
    return deck;
  }
}
