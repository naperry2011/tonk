import { describe, it, expect } from 'vitest';
import { Deck } from '../src/game/Deck.js';
import { Card } from '../src/game/Card.js';

describe('Deck', () => {
  it('contains 52 unique cards', () => {
    const deck = new Deck();
    expect(deck.cardsRemaining).toBe(52);
    const ids = new Set(deck.cards.map(card => card.id));
    expect(ids.size).toBe(52);
  });

  it('draw removes a card and returns it', () => {
    const deck = new Deck();
    const card = deck.draw();
    expect(card).toBeInstanceOf(Card);
    expect(deck.cardsRemaining).toBe(51);
  });

  it('returns null when the stock is empty (no reshuffle per Tonk rules)', () => {
    const deck = new Deck();
    while (!deck.isEmpty()) deck.draw();
    expect(deck.draw()).toBeNull();
  });

  it('manages the discard pile', () => {
    const deck = new Deck();
    expect(deck.getTopDiscard()).toBeNull();

    const first = deck.draw();
    const second = deck.draw();
    deck.discard(first);
    deck.discard(second);

    expect(deck.getTopDiscard()).toBe(second);
    expect(deck.drawFromDiscard()).toBe(second);
    expect(deck.getTopDiscard()).toBe(first);
  });

  it('round-trips through JSON', () => {
    const deck = new Deck();
    deck.discard(deck.draw());
    const restored = Deck.fromJSON(deck.toJSON());
    expect(restored.cardsRemaining).toBe(51);
    expect(restored.discardPile).toHaveLength(1);
    expect(restored.getTopDiscard().equals(deck.getTopDiscard())).toBe(true);
  });
});
