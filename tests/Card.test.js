import { describe, it, expect } from 'vitest';
import { Card, SUITS, RANKS } from '../src/game/Card.js';

describe('Card', () => {
  describe('point values', () => {
    it('values an Ace at 1', () => {
      expect(new Card('hearts', 'A').value).toBe(1);
    });

    it('values number cards at face value', () => {
      for (const rank of ['2', '3', '4', '5', '6', '7', '8', '9', '10']) {
        expect(new Card('spades', rank).value).toBe(parseInt(rank, 10));
      }
    });

    it('values face cards at 10', () => {
      expect(new Card('clubs', 'J').value).toBe(10);
      expect(new Card('clubs', 'Q').value).toBe(10);
      expect(new Card('clubs', 'K').value).toBe(10);
    });
  });

  describe('rank ordering', () => {
    it('orders A low through K high', () => {
      expect(new Card('hearts', 'A').getRankIndex()).toBe(0);
      expect(new Card('hearts', 'K').getRankIndex()).toBe(12);
    });

    it('exposes 13 ranks and 4 suits', () => {
      expect(RANKS).toHaveLength(13);
      expect(SUITS).toHaveLength(4);
    });
  });

  describe('color and identity', () => {
    it('treats hearts and diamonds as red', () => {
      expect(new Card('hearts', '5').isRed()).toBe(true);
      expect(new Card('diamonds', '5').isRed()).toBe(true);
      expect(new Card('clubs', '5').isRed()).toBe(false);
      expect(new Card('spades', '5').isRed()).toBe(false);
    });

    it('compares cards by suit and rank', () => {
      expect(new Card('hearts', '7').equals(new Card('hearts', '7'))).toBe(true);
      expect(new Card('hearts', '7').equals(new Card('spades', '7'))).toBe(false);
    });

    it('round-trips through JSON', () => {
      const card = new Card('diamonds', 'Q');
      const restored = Card.fromJSON(card.toJSON());
      expect(restored.equals(card)).toBe(true);
      expect(restored.value).toBe(10);
    });
  });
});
