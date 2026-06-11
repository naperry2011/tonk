import { describe, it, expect } from 'vitest';
import { Card } from '../src/game/Card.js';
import { Spread, findPossibleSpreads } from '../src/game/Spread.js';

const c = (rank, suit = 'hearts') => new Card(suit, rank);

describe('Spread.isValidBook', () => {
  it('accepts 3 cards of the same rank', () => {
    expect(Spread.isValidBook([c('7', 'hearts'), c('7', 'clubs'), c('7', 'spades')])).toBe(true);
  });

  it('accepts 4 cards of the same rank', () => {
    expect(
      Spread.isValidBook([c('K', 'hearts'), c('K', 'clubs'), c('K', 'spades'), c('K', 'diamonds')])
    ).toBe(true);
  });

  it('rejects fewer than 3 cards', () => {
    expect(Spread.isValidBook([c('7', 'hearts'), c('7', 'clubs')])).toBe(false);
  });

  it('rejects mixed ranks', () => {
    expect(Spread.isValidBook([c('7', 'hearts'), c('7', 'clubs'), c('8', 'spades')])).toBe(false);
  });
});

describe('Spread.isValidRun', () => {
  it('accepts 3 sequential cards of the same suit', () => {
    expect(Spread.isValidRun([c('4'), c('5'), c('6')])).toBe(true);
  });

  it('accepts unsorted input', () => {
    expect(Spread.isValidRun([c('6'), c('4'), c('5')])).toBe(true);
  });

  it('treats the Ace as low (A-2-3 is valid)', () => {
    expect(Spread.isValidRun([c('A'), c('2'), c('3')])).toBe(true);
  });

  it('does not wrap around (Q-K-A is invalid)', () => {
    expect(Spread.isValidRun([c('Q'), c('K'), c('A')])).toBe(false);
  });

  it('rejects mixed suits', () => {
    expect(Spread.isValidRun([c('4', 'hearts'), c('5', 'clubs'), c('6', 'hearts')])).toBe(false);
  });

  it('rejects gaps in the sequence', () => {
    expect(Spread.isValidRun([c('4'), c('5'), c('7')])).toBe(false);
  });
});

describe('Spread.validate', () => {
  it('identifies books', () => {
    expect(Spread.validate([c('9', 'hearts'), c('9', 'clubs'), c('9', 'spades')])).toEqual({
      valid: true,
      type: 'book'
    });
  });

  it('identifies runs', () => {
    expect(Spread.validate([c('9'), c('10'), c('J')])).toEqual({ valid: true, type: 'run' });
  });

  it('rejects invalid sets', () => {
    expect(Spread.validate([c('9'), c('10'), c('K')])).toEqual({ valid: false, type: null });
  });
});

describe('hitting spreads (canAddCard / addCard)', () => {
  it('allows the 4th card of a rank onto a book, but not a 5th', () => {
    const book = new Spread([c('7', 'hearts'), c('7', 'clubs'), c('7', 'spades')], 'book', null);
    expect(book.canAddCard(c('7', 'diamonds'))).toBe(true);
    book.addCard(c('7', 'diamonds'));
    expect(book.canAddCard(c('7', 'hearts'))).toBe(false);
  });

  it('rejects a different rank on a book', () => {
    const book = new Spread([c('7', 'hearts'), c('7', 'clubs'), c('7', 'spades')], 'book', null);
    expect(book.canAddCard(c('8', 'diamonds'))).toBe(false);
  });

  it('allows extending a run at either end only', () => {
    const run = new Spread([c('5'), c('6'), c('7')], 'run', null);
    expect(run.canAddCard(c('4'))).toBe(true);
    expect(run.canAddCard(c('8'))).toBe(true);
    expect(run.canAddCard(c('9'))).toBe(false);
    expect(run.canAddCard(c('4', 'clubs'))).toBe(false);
  });

  it('keeps runs sorted after adding and throws on invalid adds', () => {
    const run = new Spread([c('5'), c('6'), c('7')], 'run', null);
    run.addCard(c('4'));
    expect(run.cards.map(card => card.rank)).toEqual(['4', '5', '6', '7']);
    expect(() => run.addCard(c('J'))).toThrow();
  });
});

describe('Spread.getPoints', () => {
  it('sums card values', () => {
    const run = new Spread([c('9'), c('10'), c('J')], 'run', null);
    expect(run.getPoints()).toBe(29);
  });
});

describe('findPossibleSpreads', () => {
  it('finds books and runs in a hand', () => {
    const hand = [
      c('7', 'hearts'),
      c('7', 'clubs'),
      c('7', 'spades'),
      c('2', 'diamonds'),
      c('3', 'diamonds'),
      c('4', 'diamonds')
    ];
    const spreads = findPossibleSpreads(hand);
    const types = spreads.map(s => s.type).sort();
    expect(types).toEqual(['book', 'run']);
  });

  it('caps books at 4 cards', () => {
    const hand = ['hearts', 'clubs', 'spades', 'diamonds'].map(suit => c('Q', suit));
    const [book] = findPossibleSpreads(hand);
    expect(book.cards).toHaveLength(4);
  });

  it('returns nothing for a spreadless hand', () => {
    const hand = [c('2', 'hearts'), c('5', 'clubs'), c('9', 'spades'), c('K', 'diamonds')];
    expect(findPossibleSpreads(hand)).toEqual([]);
  });
});
