import { Deck } from './Deck.js';
import { Player } from './Player.js';
import { ComputerPlayer } from './ComputerPlayer.js';
import { Spread } from './Spread.js';
import {
  getCardsPerPlayer,
  hasInitialTonk,
  determineKnockWinner,
  PHASES,
  WIN_CONDITIONS,
  MATCH_POINT_LIMIT,
  BETTING
} from './rules.js';

// Pool of random names for AI players
const AI_NAME_POOL = [
  'Alex', 'Jordan', 'Sam', 'Casey', 'Riley', 'Morgan',
  'Taylor', 'Avery', 'Quinn', 'Blake', 'Parker', 'Reese',
  'Charlie', 'Frankie', 'Jamie', 'Skyler', 'Drew', 'Sage',
  'Max', 'Jessie', 'Robin', 'Dana', 'Chris', 'Pat'
];

/**
 * Get random unique names from the pool
 */
function getRandomAINames(count) {
  const shuffled = [...AI_NAME_POOL].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, count);
}

/**
 * Main game controller
 */
export class Game {
  constructor() {
    this.deck = null;
    this.players = [];
    this.currentPlayerIndex = 0;
    this.phase = PHASES.PRE_GAME;
    this.spreadsOnTable = [];
    this.winner = null;
    this.winCondition = null;
    this.turnActions = [];
    this.hasDrawnThisTurn = false;
    this.eventListeners = {};

    // Match scoring
    this.matchScores = {};  // { playerId: totalPoints }
    this.pointLimit = MATCH_POINT_LIMIT;
    this.matchWinner = null;
    this.roundNumber = 0;

    // Betting system
    this.pot = 0;
    this.highestBet = 0;
  }

  /**
   * Initialize a new game/match
   */
  initialize(playerCount, humanPlayerName = 'You') {
    this.deck = new Deck();
    this.players = [];
    this.currentPlayerIndex = 0;
    this.phase = PHASES.PRE_GAME;
    this.spreadsOnTable = [];
    this.winner = null;
    this.winCondition = null;
    this.turnActions = [];
    this.hasDrawnThisTurn = false;
    this.roundNumber = 1;
    this.matchWinner = null;

    // Create human player
    this.players.push(new Player(humanPlayerName, true));

    // Create computer players with random names
    const aiNames = getRandomAINames(playerCount - 1);
    for (let i = 0; i < playerCount - 1; i++) {
      this.players.push(new ComputerPlayer(aiNames[i], 'medium'));
    }

    // Initialize match scores
    this.matchScores = {};
    for (const player of this.players) {
      this.matchScores[player.id] = 0;
    }

    // Initialize chips for all players
    for (const player of this.players) {
      player.chips = BETTING.STARTING_CHIPS;
      player.currentBet = 0;
      player.isEliminated = false;
    }

    // Reset betting state
    this.pot = 0;
    this.highestBet = 0;

    // Deal cards and check initial tonk (may redeal if multiple players have 49-50)
    this.dealAndCheckInitialTonk();

    this.emit('gameInitialized', { players: this.players });
  }

  /**
   * Deal cards and check for initial tonk, redealing if multiple players have 49-50
   */
  dealAndCheckInitialTonk() {
    // Collect antes before dealing
    this.collectAntes();

    this.deal();

    // Check for initial tonk
    this.phase = PHASES.INITIAL_TONK_CHECK;
    const playersWithTonk = this.checkInitialTonk();

    if (playersWithTonk.length > 1) {
      // Multiple players have 49-50 - it's a draw, redeal
      this.emit('initialTonkDraw', { players: playersWithTonk });

      // Reset for redeal
      for (const player of this.players) {
        player.reset();
      }
      this.deck = new Deck();
      this.dealAndCheckInitialTonk(); // Recursive redeal
    } else if (playersWithTonk.length === 1) {
      // Single player has initial tonk - they win
      this.winner = playersWithTonk[0];
      this.winCondition = WIN_CONDITIONS.INITIAL_TONK;
      this.phase = PHASES.GAME_OVER;
      this.emit('gameOver', { winner: this.winner, condition: this.winCondition });
    } else {
      // No initial tonk - start first player's turn
      this.phase = PHASES.START_OF_TURN;
      this.emit('turnStart', { player: this.getCurrentPlayer() });
    }
  }

  /**
   * Deal cards to all players
   */
  deal() {
    const cardsPerPlayer = getCardsPerPlayer(this.players.length);

    // Deal cards one at a time to each player
    for (let i = 0; i < cardsPerPlayer; i++) {
      for (const player of this.players) {
        const card = this.deck.draw();
        if (card) {
          player.addCard(card);
        }
      }
    }

    // Flip top card to start discard pile
    const firstDiscard = this.deck.draw();
    if (firstDiscard) {
      this.deck.discard(firstDiscard);
    }

    this.emit('cardsDealt', { cardsPerPlayer });
  }

  /**
   * Check if any player has initial Tonk (49-50 points)
   * Returns array of players with initial tonk
   */
  checkInitialTonk() {
    const playersWithTonk = [];
    for (const player of this.players) {
      if (hasInitialTonk(player.calculatePoints())) {
        playersWithTonk.push(player);
      }
    }
    return playersWithTonk;
  }

  /**
   * Get the current player
   */
  getCurrentPlayer() {
    return this.players[this.currentPlayerIndex];
  }

  /**
   * Check if it's the human player's turn
   */
  isHumanTurn() {
    return this.getCurrentPlayer().isHuman;
  }

  /**
   * Draw a card from the deck
   * If stock is empty, game ends - lowest points wins
   */
  drawFromDeck() {
    if (this.phase !== PHASES.DRAW) {
      throw new Error('Cannot draw - not in draw phase');
    }

    const card = this.deck.draw();
    if (card) {
      this.getCurrentPlayer().addCard(card);
      this.hasDrawnThisTurn = true;
      this.turnActions.push({ type: 'draw', source: 'deck', card });
      this.phase = PHASES.ACTION;
      this.emit('cardDrawn', { player: this.getCurrentPlayer(), source: 'deck', card });
      return card;
    } else {
      // Stock is empty - end game, lowest points wins
      this.endGameStockEmpty();
      return null;
    }
  }

  /**
   * End the game when stock runs out
   * Player with lowest points wins
   */
  endGameStockEmpty() {
    let lowestPlayer = this.players[0];
    let lowestPoints = lowestPlayer.calculatePoints();

    for (const player of this.players) {
      const points = player.calculatePoints();
      if (points < lowestPoints) {
        lowestPoints = points;
        lowestPlayer = player;
      }
    }

    this.winner = lowestPlayer;
    this.winCondition = WIN_CONDITIONS.STOCK_EMPTY;
    this.phase = PHASES.GAME_OVER;
    this.emit('gameOver', { winner: this.winner, condition: this.winCondition });
  }

  /**
   * Draw a card from the discard pile
   */
  drawFromDiscard() {
    if (this.phase !== PHASES.DRAW) {
      throw new Error('Cannot draw - not in draw phase');
    }

    const card = this.deck.drawFromDiscard();
    if (card) {
      this.getCurrentPlayer().addCard(card);
      this.hasDrawnThisTurn = true;
      this.turnActions.push({ type: 'draw', source: 'discard', card });
      this.phase = PHASES.ACTION;
      this.emit('cardDrawn', { player: this.getCurrentPlayer(), source: 'discard', card });
    }
    return card;
  }

  /**
   * Lay down a spread (allowed in START_OF_TURN and ACTION phases)
   */
  laySpread(cards) {
    if (this.phase !== PHASES.ACTION && this.phase !== PHASES.START_OF_TURN) {
      throw new Error('Cannot lay spread - not in valid phase');
    }

    const validation = Spread.validate(cards);
    if (!validation.valid) {
      throw new Error('Invalid spread');
    }

    const player = this.getCurrentPlayer();

    // Remove cards from player's hand
    player.removeCards(cards);

    // Create spread and add to table
    const spread = new Spread(cards, validation.type, player);
    this.spreadsOnTable.push(spread);
    player.addSpread(spread);

    this.turnActions.push({ type: 'spread', cards, spreadType: validation.type });
    this.emit('spreadLaid', { player, spread });

    // Check for Tonk (empty hand)
    if (player.hasEmptyHand()) {
      this.winner = player;
      this.winCondition = WIN_CONDITIONS.TONK;
      this.phase = PHASES.GAME_OVER;
      this.emit('gameOver', { winner: this.winner, condition: this.winCondition });
      return spread;
    }

    return spread;
  }

  /**
   * Proceed from START_OF_TURN to DRAW phase
   */
  proceedToDraw() {
    if (this.phase !== PHASES.START_OF_TURN) {
      throw new Error('Can only proceed to draw from start of turn');
    }
    this.phase = PHASES.DRAW;
    this.emit('phaseChanged', { phase: PHASES.DRAW });
  }

  /**
   * Hit an existing spread (add a card to it)
   */
  hitSpread(card, spread) {
    if (this.phase !== PHASES.ACTION && this.phase !== PHASES.START_OF_TURN) {
      throw new Error('Cannot hit spread - not in valid phase');
    }

    if (!spread.canAddCard(card)) {
      throw new Error('Cannot add this card to the spread');
    }

    const player = this.getCurrentPlayer();
    player.removeCard(card);
    spread.addCard(card);

    this.turnActions.push({ type: 'hit', card, spreadId: spread.id });
    this.emit('spreadHit', { player, card, spread });

    // Check for Tonk (empty hand)
    if (player.hasEmptyHand()) {
      this.winner = player;
      this.winCondition = WIN_CONDITIONS.TONK;
      this.phase = PHASES.GAME_OVER;
      this.emit('gameOver', { winner: this.winner, condition: this.winCondition });
    }
  }

  /**
   * Discard a card and end turn
   */
  discard(card) {
    if (this.phase !== PHASES.ACTION) {
      throw new Error('Cannot discard - not in action phase');
    }

    const player = this.getCurrentPlayer();
    const removedCard = player.removeCard(card);

    if (!removedCard) {
      throw new Error('Card not in player hand');
    }

    this.deck.discard(removedCard);
    this.turnActions.push({ type: 'discard', card: removedCard });
    this.emit('cardDiscarded', { player, card: removedCard });

    // Check for Tonk (empty hand after discard)
    if (player.hasEmptyHand()) {
      this.winner = player;
      this.winCondition = WIN_CONDITIONS.TONK;
      this.phase = PHASES.GAME_OVER;
      this.emit('gameOver', { winner: this.winner, condition: this.winCondition });
      return;
    }

    // Move to next player
    this.endTurn();
  }

  /**
   * Knock/Drop (must be done at start of turn, before drawing)
   * Claims to have lowest points - no threshold required
   */
  knock() {
    if (this.phase !== PHASES.START_OF_TURN) {
      throw new Error('Can only knock at the start of your turn');
    }

    const knocker = this.getCurrentPlayer();
    const knockerPoints = knocker.calculatePoints();

    // Find the lowest points among all other players
    let lowestOtherPlayer = null;
    let lowestOtherPoints = Infinity;

    for (const player of this.players) {
      if (player !== knocker) {
        const points = player.calculatePoints();
        if (points < lowestOtherPoints) {
          lowestOtherPoints = points;
          lowestOtherPlayer = player;
        }
      }
    }

    // Knocker wins only if they have strictly the lowest points
    if (knockerPoints < lowestOtherPoints) {
      this.winner = knocker;
      this.winCondition = WIN_CONDITIONS.KNOCK;
    } else {
      // Knocker got caught - lowest other player wins
      this.winner = lowestOtherPlayer;
      this.winCondition = WIN_CONDITIONS.CAUGHT;
    }

    this.phase = PHASES.GAME_OVER;
    this.emit('knock', { knocker, winner: this.winner });
    this.emit('gameOver', { winner: this.winner, condition: this.winCondition, knocker });
  }

  /**
   * End the current player's turn
   */
  endTurn() {
    // Move to next player
    this.currentPlayerIndex = (this.currentPlayerIndex + 1) % this.players.length;
    this.hasDrawnThisTurn = false;
    this.turnActions = [];
    this.phase = PHASES.START_OF_TURN;

    this.emit('turnEnd', { nextPlayer: this.getCurrentPlayer() });
    this.emit('turnStart', { player: this.getCurrentPlayer() });
  }

  /**
   * Check if the game is over
   */
  isGameOver() {
    return this.phase === PHASES.GAME_OVER;
  }

  /**
   * Get all players' current hand scores
   */
  getScores() {
    return this.players.map(player => ({
      player,
      points: player.calculatePoints(),
      cardCount: player.cardCount,
      matchScore: this.matchScores[player.id] || 0
    }));
  }

  /**
   * Get match scores for all players
   */
  getMatchScores() {
    return this.players.map(player => ({
      player,
      score: this.matchScores[player.id] || 0
    }));
  }

  /**
   * Calculate and apply round-end scoring
   * Returns the loser(s) who had points added
   */
  applyRoundScoring() {
    const losers = [];
    const winner = this.winner;

    for (const player of this.players) {
      if (player !== winner) {
        const points = player.calculatePoints();
        this.matchScores[player.id] = (this.matchScores[player.id] || 0) + points;
        losers.push({ player, pointsAdded: points, newTotal: this.matchScores[player.id] });
      }
    }

    return losers;
  }

  /**
   * Check if match has ended (someone hit point limit)
   */
  checkMatchEnd() {
    for (const player of this.players) {
      if (this.matchScores[player.id] >= this.pointLimit) {
        // Find player with lowest score - they win the match
        let matchWinner = this.players[0];
        let lowestScore = this.matchScores[matchWinner.id];

        for (const p of this.players) {
          if (this.matchScores[p.id] < lowestScore) {
            lowestScore = this.matchScores[p.id];
            matchWinner = p;
          }
        }

        this.matchWinner = matchWinner;
        return true;
      }
    }
    return false;
  }

  /**
   * Start the next round
   */
  startNextRound() {
    this.roundNumber++;

    // Reset players' hands and spreads
    for (const player of this.players) {
      player.reset();
      player.resetBet();
    }

    // Reset round state
    this.spreadsOnTable = [];
    this.winner = null;
    this.winCondition = null;
    this.hasDrawnThisTurn = false;
    this.turnActions = [];

    // Reset betting
    this.pot = 0;
    this.highestBet = 0;

    // Create new deck and deal
    this.deck = new Deck();

    this.emit('roundStart', { roundNumber: this.roundNumber });
    this.dealAndCheckInitialTonk();
  }

  /**
   * Get the discard pile top card
   */
  getTopDiscard() {
    return this.deck.getTopDiscard();
  }

  /**
   * Get remaining cards in deck
   */
  getDeckCount() {
    return this.deck.cardsRemaining;
  }

  /**
   * Check if stock (draw pile) is empty
   */
  isStockEmpty() {
    return this.deck.isEmpty();
  }

  /**
   * Reset game for new round
   */
  reset() {
    for (const player of this.players) {
      player.reset();
    }
    this.spreadsOnTable = [];
    this.winner = null;
    this.winCondition = null;
    this.currentPlayerIndex = 0;
    this.hasDrawnThisTurn = false;
    this.turnActions = [];
    this.phase = PHASES.PRE_GAME;
  }

  /**
   * Event system - register listener
   */
  on(event, callback) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    this.eventListeners[event].push(callback);
  }

  /**
   * Event system - remove listener
   */
  off(event, callback) {
    if (this.eventListeners[event]) {
      this.eventListeners[event] = this.eventListeners[event].filter(cb => cb !== callback);
    }
  }

  /**
   * Event system - emit event
   */
  emit(event, data) {
    if (this.eventListeners[event]) {
      for (const callback of this.eventListeners[event]) {
        callback(data);
      }
    }
  }

  // ==================
  // BETTING METHODS
  // ==================

  /**
   * Collect antes from all players at round start
   */
  collectAntes() {
    this.pot = 0;
    this.highestBet = BETTING.ANTE_AMOUNT;

    for (const player of this.players) {
      if (!player.isEliminated) {
        player.resetBet();
        const actualAnte = player.bet(BETTING.ANTE_AMOUNT);
        this.pot += actualAnte;
      }
    }

    this.emit('antesCollected', { pot: this.pot, ante: BETTING.ANTE_AMOUNT });
  }

  /**
   * Player places a raise bet
   */
  placeBet(player, amount) {
    if (player.isEliminated) {
      throw new Error('Eliminated players cannot bet');
    }

    const actualBet = player.bet(amount);
    this.pot += actualBet;

    // Update highest bet if this is a raise
    if (player.currentBet > this.highestBet) {
      this.highestBet = player.currentBet;
    }

    this.emit('betPlaced', { player, amount: actualBet, pot: this.pot });
    return actualBet;
  }

  /**
   * Award the pot to the winner
   */
  awardPot(winner) {
    const winnings = this.pot;
    winner.receiveChips(winnings);
    this.pot = 0;

    this.emit('potAwarded', { winner, amount: winnings });
    return winnings;
  }

  /**
   * Reset betting state for new round
   */
  resetBetting() {
    this.pot = 0;
    this.highestBet = 0;
    for (const player of this.players) {
      player.resetBet();
    }
  }

  /**
   * Get current pot amount
   */
  getPot() {
    return this.pot;
  }

  /**
   * Get player chips info
   */
  getChipsInfo() {
    return this.players.map(player => ({
      player,
      chips: player.chips,
      currentBet: player.currentBet,
      isEliminated: player.isEliminated
    }));
  }

  /**
   * Check if human player can afford to raise
   */
  canPlayerRaise(amount) {
    const humanPlayer = this.players.find(p => p.isHuman);
    return humanPlayer && humanPlayer.canAfford(amount);
  }

  /**
   * Serialize game state
   */
  toJSON() {
    return {
      deck: this.deck.toJSON(),
      players: this.players.map(p => p.toJSON()),
      currentPlayerIndex: this.currentPlayerIndex,
      phase: this.phase,
      spreadsOnTable: this.spreadsOnTable.map(s => s.toJSON()),
      winner: this.winner?.id || null,
      winCondition: this.winCondition,
      hasDrawnThisTurn: this.hasDrawnThisTurn,
      pot: this.pot,
      highestBet: this.highestBet
    };
  }
}
