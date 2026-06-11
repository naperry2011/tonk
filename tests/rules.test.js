import { describe, it, expect } from 'vitest';
import {
  canKnock,
  hasInitialTonk,
  determineKnockWinner,
  getCardsPerPlayer,
  CARDS_PER_PLAYER,
  MATCH_POINT_LIMIT,
  BETTING
} from '../src/game/rules.js';
import { Card } from '../src/game/Card.js';
import { Player } from '../src/game/Player.js';

const playerWithPoints = (name, ranks) => {
  const p = new Player(name);
  p.addCards(ranks.map(rank => new Card('hearts', rank)));
  return p;
};

describe('hasInitialTonk', () => {
  it('is true only for 49 and 50 points', () => {
    expect(hasInitialTonk(48)).toBe(false);
    expect(hasInitialTonk(49)).toBe(true);
    expect(hasInitialTonk(50)).toBe(true);
    expect(hasInitialTonk(51)).toBe(false);
  });
});

describe('canKnock', () => {
  it('allows knocking at any point total (no threshold)', () => {
    expect(canKnock(0)).toBe(true);
    expect(canKnock(50)).toBe(true);
  });
});

describe('determineKnockWinner', () => {
  it('picks the player with the lowest hand points', () => {
    const low = playerWithPoints('Low', ['A', '2']); // 3 points
    const high = playerWithPoints('High', ['K', 'Q']); // 20 points
    expect(determineKnockWinner([high, low])).toBe(low);
  });

  it('breaks ties in favor of the first player listed', () => {
    const first = playerWithPoints('First', ['5']);
    const second = playerWithPoints('Second', ['5']);
    expect(determineKnockWinner([first, second])).toBe(first);
  });

  it('returns null for an empty list', () => {
    expect(determineKnockWinner([])).toBeNull();
  });
});

describe('constants', () => {
  it('deals 5 cards regardless of player count', () => {
    expect(getCardsPerPlayer(2)).toBe(CARDS_PER_PLAYER);
    expect(getCardsPerPlayer(4)).toBe(CARDS_PER_PLAYER);
    expect(CARDS_PER_PLAYER).toBe(5);
  });

  it('plays matches to 100 points', () => {
    expect(MATCH_POINT_LIMIT).toBe(100);
  });

  it('defines the betting structure', () => {
    expect(BETTING.STARTING_CHIPS).toBeGreaterThan(0);
    expect(BETTING.ANTE_AMOUNT).toBeGreaterThan(0);
    expect(BETTING.RAISE_OPTIONS.length).toBeGreaterThan(0);
  });
});
