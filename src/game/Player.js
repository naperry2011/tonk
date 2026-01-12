import { findPossibleSpreads } from './Spread.js';
import { canKnock } from './rules.js';

/**
 * Represents a player in the game
 */
export class Player {
  constructor(name, isHuman = false) {
    this.id = `player-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    this.name = name;
    this.hand = [];
    this.isHuman = isHuman;
    this.spreads = []; // Spreads this player has laid down
    this.chips = 0; // Chips for betting (initialized by Game)
    this.currentBet = 0; // Current bet this round
    this.isEliminated = false; // True if player has no chips
  }

  /**
   * Add a card to the player's hand
   */
  addCard(card) {
    this.hand.push(card);
  }

  /**
   * Add multiple cards to the player's hand
   */
  addCards(cards) {
    this.hand.push(...cards);
  }

  /**
   * Remove a card from the player's hand
   */
  removeCard(card) {
    const index = this.hand.findIndex(c => c.equals(card));
    if (index !== -1) {
      return this.hand.splice(index, 1)[0];
    }
    return null;
  }

  /**
   * Remove multiple cards from the player's hand
   */
  removeCards(cards) {
    const removed = [];
    for (const card of cards) {
      const removedCard = this.removeCard(card);
      if (removedCard) {
        removed.push(removedCard);
      }
    }
    return removed;
  }

  /**
   * Get a card from hand by index
   */
  getCard(index) {
    return this.hand[index] || null;
  }

  /**
   * Calculate total points in hand
   */
  calculatePoints() {
    return this.hand.reduce((sum, card) => sum + card.value, 0);
  }

  /**
   * Check if player can knock
   */
  canKnock() {
    return canKnock(this.calculatePoints());
  }

  /**
   * Check if player has won (empty hand)
   */
  hasEmptyHand() {
    return this.hand.length === 0;
  }

  /**
   * Get number of cards in hand
   */
  get cardCount() {
    return this.hand.length;
  }

  /**
   * Find all possible spreads in the player's hand
   */
  findPossibleSpreads() {
    return findPossibleSpreads(this.hand);
  }

  /**
   * Add a spread to player's spreads list
   */
  addSpread(spread) {
    this.spreads.push(spread);
  }

  /**
   * Clear the player's hand
   */
  clearHand() {
    this.hand = [];
  }

  /**
   * Clear all spreads
   */
  clearSpreads() {
    this.spreads = [];
  }

  /**
   * Reset player for new game
   */
  reset() {
    this.clearHand();
    this.clearSpreads();
  }

  /**
   * Get cards sorted by value (highest first)
   */
  getCardsSortedByValue() {
    return [...this.hand].sort((a, b) => b.value - a.value);
  }

  /**
   * Get cards sorted by suit and rank
   */
  getCardsSortedBySuit() {
    return [...this.hand].sort((a, b) => {
      if (a.suit !== b.suit) {
        return a.suit.localeCompare(b.suit);
      }
      return a.getRankIndex() - b.getRankIndex();
    });
  }

  /**
   * Check if player has a specific card
   */
  hasCard(card) {
    return this.hand.some(c => c.equals(card));
  }

  /**
   * Reorder a card in hand from one position to another
   */
  reorderCard(fromIndex, toIndex) {
    if (fromIndex < 0 || fromIndex >= this.hand.length) return;
    if (toIndex < 0 || toIndex >= this.hand.length) return;
    if (fromIndex === toIndex) return;

    const [card] = this.hand.splice(fromIndex, 1);
    this.hand.splice(toIndex, 0, card);
  }

  /**
   * Place a bet (deduct chips)
   * Returns actual amount bet (may be less if all-in)
   */
  bet(amount) {
    const actualBet = Math.min(amount, this.chips);
    this.chips -= actualBet;
    this.currentBet += actualBet;
    return actualBet;
  }

  /**
   * Receive chips (winnings)
   */
  receiveChips(amount) {
    this.chips += amount;
  }

  /**
   * Reset betting state for new round
   */
  resetBet() {
    this.currentBet = 0;
  }

  /**
   * Check if player can afford a bet
   */
  canAfford(amount) {
    return this.chips >= amount;
  }

  /**
   * Check if player is all-in (has bet all chips)
   */
  isAllIn() {
    return this.chips === 0 && this.currentBet > 0;
  }

  /**
   * Serialize player state to JSON
   */
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      hand: this.hand.map(c => c.toJSON()),
      isHuman: this.isHuman,
      spreads: this.spreads.map(s => s.toJSON()),
      chips: this.chips,
      currentBet: this.currentBet,
      isEliminated: this.isEliminated
    };
  }
}
