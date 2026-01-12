/**
 * Tonk game rules and constants
 */

// Game constants
export const CARDS_PER_PLAYER = 5;
export const INITIAL_TONK_MIN = 49;
export const INITIAL_TONK_MAX = 50;
export const MIN_SPREAD_SIZE = 3;
export const MAX_PLAYERS = 4;
export const MIN_PLAYERS = 2;
export const MATCH_POINT_LIMIT = 100; // First to this score loses the match

// Betting constants
export const BETTING = {
  STARTING_CHIPS: 1000,
  ANTE_AMOUNT: 10,
  RAISE_OPTIONS: [10, 25, 50, 100]
};

/**
 * Get the number of cards to deal per player (always 5)
 */
export function getCardsPerPlayer(playerCount) {
  return CARDS_PER_PLAYER;
}

/**
 * Check if a player can knock (drop) - always allowed, no threshold
 */
export function canKnock(points) {
  return true;
}

/**
 * Check if a player has an initial Tonk (49 or 50 points)
 */
export function hasInitialTonk(points) {
  return points >= INITIAL_TONK_MIN && points <= INITIAL_TONK_MAX;
}

/**
 * Determine the winner among players based on lowest points
 * Returns the player with the lowest points
 */
export function determineKnockWinner(players) {
  if (!players || players.length === 0) return null;

  return players.reduce((winner, player) => {
    const winnerPoints = winner.calculatePoints();
    const playerPoints = player.calculatePoints();

    // Lower points wins
    if (playerPoints < winnerPoints) {
      return player;
    }
    // Tie goes to the knocker (first player in comparison)
    return winner;
  });
}

/**
 * Game phases
 */
export const PHASES = {
  PRE_GAME: 'pre-game',
  INITIAL_TONK_CHECK: 'initial-tonk-check',
  START_OF_TURN: 'start-of-turn', // Can spread or knock before drawing
  DRAW: 'draw',
  ACTION: 'action',
  DISCARD: 'discard',
  GAME_OVER: 'game-over'
};

/**
 * Win conditions
 */
export const WIN_CONDITIONS = {
  TONK: 'tonk',           // Empty hand
  INITIAL_TONK: 'initial-tonk', // 49-50 points at deal
  INITIAL_TONK_DRAW: 'initial-tonk-draw', // Multiple players had 49-50, redeal
  KNOCK: 'knock',         // Lowest points when someone knocks (drops)
  CAUGHT: 'caught',       // Knocker didn't have lowest points
  STOCK_EMPTY: 'stock-empty' // Stock ran out, lowest points wins
};
