import { describe, it, expect } from 'vitest';
import { Player } from '../src/game/Player.js';
import { Card } from '../src/game/Card.js';

const c = (rank, suit = 'hearts') => new Card(suit, rank);

describe('Player hand management', () => {
  it('adds and removes cards by equality', () => {
    const p = new Player('Test');
    p.addCards([c('5'), c('K', 'spades')]);
    expect(p.cardCount).toBe(2);

    const removed = p.removeCard(c('K', 'spades'));
    expect(removed.rank).toBe('K');
    expect(p.cardCount).toBe(1);
    expect(p.removeCard(c('Q'))).toBeNull();
  });

  it('calculates hand points', () => {
    const p = new Player('Test');
    p.addCards([c('A'), c('10'), c('J')]); // 1 + 10 + 10
    expect(p.calculatePoints()).toBe(21);
  });

  it('reports an empty hand', () => {
    const p = new Player('Test');
    expect(p.hasEmptyHand()).toBe(true);
    p.addCard(c('2'));
    expect(p.hasEmptyHand()).toBe(false);
  });

  it('reorders cards within bounds and ignores out-of-bounds moves', () => {
    const p = new Player('Test');
    p.addCards([c('2'), c('3'), c('4')]);
    p.reorderCard(0, 2);
    expect(p.hand.map(card => card.rank)).toEqual(['3', '4', '2']);
    p.reorderCard(0, 5); // out of bounds, no-op
    expect(p.hand.map(card => card.rank)).toEqual(['3', '4', '2']);
  });
});

describe('Player betting', () => {
  it('deducts chips on a bet and tracks the current bet', () => {
    const p = new Player('Test');
    p.chips = 100;
    expect(p.bet(30)).toBe(30);
    expect(p.chips).toBe(70);
    expect(p.currentBet).toBe(30);
  });

  it('caps a bet at remaining chips (all-in)', () => {
    const p = new Player('Test');
    p.chips = 20;
    expect(p.bet(50)).toBe(20);
    expect(p.chips).toBe(0);
    expect(p.isAllIn()).toBe(true);
  });

  it('checks affordability', () => {
    const p = new Player('Test');
    p.chips = 25;
    expect(p.canAfford(25)).toBe(true);
    expect(p.canAfford(26)).toBe(false);
  });
});
