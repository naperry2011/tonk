import { describe, it, expect } from 'vitest';
import { Game } from '../src/game/Game.js';
import { Card } from '../src/game/Card.js';
import { PHASES, WIN_CONDITIONS, BETTING } from '../src/game/rules.js';

const c = (rank, suit = 'hearts') => new Card(suit, rank);

/**
 * Initialize a 2-player game and force known hands and phase, so tests
 * are deterministic regardless of the shuffled deal (including the rare
 * initial-tonk auto-win).
 */
function gameWithHands(humanRanks, aiRanks) {
  const game = new Game();
  game.initialize(2);
  const [human, ai] = game.players;
  human.hand = humanRanks.map(rank => c(rank, 'hearts'));
  ai.hand = aiRanks.map(rank => c(rank, 'spades'));
  game.winner = null;
  game.winCondition = null;
  game.currentPlayerIndex = 0;
  game.phase = PHASES.START_OF_TURN;
  return { game, human, ai };
}

describe('Game.initialize', () => {
  it('deals 5 cards each, flips one discard, and collects antes', () => {
    const game = new Game();
    game.initialize(2);

    expect(game.players).toHaveLength(2);
    expect(game.players[0].isHuman).toBe(true);
    for (const player of game.players) {
      expect(player.cardCount).toBe(5);
    }
    // 52 - (2 players x 5 cards) - 1 discard = 41
    expect(game.deck.cardsRemaining).toBe(41);
    expect(game.deck.discardPile).toHaveLength(1);

    expect(game.pot).toBe(2 * BETTING.ANTE_AMOUNT);
    for (const player of game.players) {
      expect(player.chips).toBe(BETTING.STARTING_CHIPS - BETTING.ANTE_AMOUNT);
    }
  });

  it('starts at START_OF_TURN unless an initial tonk ended the round', () => {
    const game = new Game();
    game.initialize(2);
    if (game.winCondition === WIN_CONDITIONS.INITIAL_TONK) {
      expect(game.phase).toBe(PHASES.GAME_OVER);
      expect(game.winner).not.toBeNull();
    } else {
      expect(game.phase).toBe(PHASES.START_OF_TURN);
    }
  });
});

describe('Game.knock', () => {
  it('awards the round to the knocker with strictly lowest points', () => {
    const { game, human } = gameWithHands(['A', '2'], ['K', 'Q']); // 3 vs 20
    game.knock();
    expect(game.winner).toBe(human);
    expect(game.winCondition).toBe(WIN_CONDITIONS.KNOCK);
    expect(game.phase).toBe(PHASES.GAME_OVER);
  });

  it('catches a knocker who ties (tie does not win)', () => {
    const { game, ai } = gameWithHands(['5'], ['5']); // 5 vs 5
    game.knock();
    expect(game.winner).toBe(ai);
    expect(game.winCondition).toBe(WIN_CONDITIONS.CAUGHT);
  });

  it('catches a knocker with higher points', () => {
    const { game, ai } = gameWithHands(['K', 'Q'], ['A', '2']);
    game.knock();
    expect(game.winner).toBe(ai);
    expect(game.winCondition).toBe(WIN_CONDITIONS.CAUGHT);
  });

  it('only allows knocking at the start of a turn', () => {
    const { game } = gameWithHands(['A'], ['K']);
    game.phase = PHASES.ACTION;
    expect(() => game.knock()).toThrow();
  });

  it('emits knock and gameOver events', () => {
    const { game, human } = gameWithHands(['A'], ['K']);
    const events = [];
    game.on('knock', () => events.push('knock'));
    game.on('gameOver', data => events.push(data.condition));
    game.knock();
    expect(events).toEqual(['knock', WIN_CONDITIONS.KNOCK]);
    expect(game.winner).toBe(human);
  });
});

describe('round scoring and match end', () => {
  it('adds losers\' hand points to their match scores', () => {
    const { game, human, ai } = gameWithHands(['A'], ['K', 'Q']);
    game.knock();
    const losers = game.applyRoundScoring();

    expect(losers).toHaveLength(1);
    expect(losers[0].player).toBe(ai);
    expect(losers[0].pointsAdded).toBe(20);
    expect(game.matchScores[ai.id]).toBe(20);
    expect(game.matchScores[human.id]).toBe(0);
  });

  it('ends the match when a player reaches 100 and the lowest score wins', () => {
    const { game, human, ai } = gameWithHands(['A'], ['K']);
    game.matchScores[ai.id] = 100;
    expect(game.checkMatchEnd()).toBe(true);
    expect(game.matchWinner).toBe(human);
  });

  it('does not end the match below the limit', () => {
    const { game, ai } = gameWithHands(['A'], ['K']);
    game.matchScores[ai.id] = 99;
    expect(game.checkMatchEnd()).toBe(false);
  });
});

describe('turn flow', () => {
  it('endTurn advances to the next player and resets to START_OF_TURN', () => {
    const { game, ai } = gameWithHands(['A'], ['K']);
    game.phase = PHASES.ACTION;
    game.endTurn();
    expect(game.getCurrentPlayer()).toBe(ai);
    expect(game.phase).toBe(PHASES.START_OF_TURN);
    expect(game.hasDrawnThisTurn).toBe(false);
  });
});
