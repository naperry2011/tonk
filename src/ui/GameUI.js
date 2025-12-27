import { CardRenderer } from './CardRenderer.js';
import { Spread } from '../game/Spread.js';
import { PHASES } from '../game/rules.js';
import { loadDeckTheme, saveDeckTheme } from '../utils/storage.js';

/**
 * Main UI controller for the game
 */
export class GameUI {
  constructor(game) {
    this.game = game;
    this.selectedCards = [];
    this.selectedSpread = null;
    this.elements = {};
    this.messageTimeout = null;

    this.cacheElements();
    this.bindEvents();
    this.bindGameEvents();
    this.initializeTheme();
  }

  /**
   * Cache DOM element references
   */
  cacheElements() {
    this.elements = {
      gameContainer: document.getElementById('game-container'),
      startScreen: document.getElementById('start-screen'),
      numPlayers: document.getElementById('num-players'),
      btnStartGame: document.getElementById('btn-start-game'),
      header: document.getElementById('game-header'),
      turnIndicator: document.getElementById('turn-indicator'),
      opponentArea: document.getElementById('opponent-area'),
      tableArea: document.getElementById('table-area'),
      spreadsArea: document.getElementById('spreads-area'),
      deck: document.getElementById('deck'),
      deckCount: document.getElementById('deck-count'),
      discardPile: document.getElementById('discard-pile'),
      discardLabel: document.getElementById('discard-label'),
      playerArea: document.getElementById('player-area'),
      playerName: document.getElementById('player-name'),
      cardCount: document.getElementById('card-count'),
      pointCount: document.getElementById('point-count'),
      playerHand: document.getElementById('player-hand'),
      btnFormSpread: document.getElementById('btn-form-spread'),
      btnHitSpread: document.getElementById('btn-hit-spread'),
      btnKnock: document.getElementById('btn-knock'),
      btnDraw: document.getElementById('btn-draw'),
      btnDiscard: document.getElementById('btn-discard'),
      messageArea: document.getElementById('message-area'),
      gameOverModal: document.getElementById('game-over-modal'),
      gameOverTitle: document.getElementById('game-over-title'),
      gameOverMessage: document.getElementById('game-over-message'),
      finalScores: document.getElementById('final-scores'),
      btnNewGame: document.getElementById('btn-new-game'),
      btnContinueRound: document.getElementById('btn-continue-round'),
      rulesModal: document.getElementById('rules-modal'),
      btnRules: document.getElementById('btn-rules'),
      btnCloseRules: document.getElementById('btn-close-rules'),
      matchScores: document.getElementById('match-scores'),
      settingsModal: document.getElementById('settings-modal'),
      btnSettings: document.getElementById('btn-settings'),
      btnCloseSettings: document.getElementById('btn-close-settings'),
      themeOptions: document.querySelectorAll('.theme-option')
    };
  }

  /**
   * Bind UI event listeners
   */
  bindEvents() {
    // Start game button
    this.elements.btnStartGame.addEventListener('click', () => {
      const numPlayers = parseInt(this.elements.numPlayers.value, 10);
      this.startGame(numPlayers);
    });

    // Deck click (draw from deck)
    this.elements.deck.addEventListener('click', () => {
      if (this.canDrawFromDeck()) {
        this.handleDrawFromDeck();
      }
    });

    // Discard pile click (draw from discard)
    this.elements.discardPile.addEventListener('click', () => {
      if (this.canDrawFromDiscard()) {
        this.handleDrawFromDiscard();
      }
    });

    // Action buttons
    this.elements.btnFormSpread.addEventListener('click', () => {
      this.handleFormSpread();
    });

    this.elements.btnHitSpread.addEventListener('click', () => {
      this.handleHitSpread();
    });

    this.elements.btnKnock.addEventListener('click', () => {
      this.handleKnock();
    });

    this.elements.btnDraw.addEventListener('click', () => {
      this.handleProceedToDraw();
    });

    this.elements.btnDiscard.addEventListener('click', () => {
      this.handleDiscard();
    });

    // New game button
    this.elements.btnNewGame.addEventListener('click', () => {
      this.elements.gameOverModal.classList.add('hidden');
      this.elements.startScreen.classList.remove('hidden');
    });

    // Continue round button
    this.elements.btnContinueRound.addEventListener('click', () => {
      this.elements.gameOverModal.classList.add('hidden');
      this.game.startNextRound();
    });

    // Rules modal
    this.elements.btnRules.addEventListener('click', () => {
      this.elements.rulesModal.classList.remove('hidden');
    });

    this.elements.btnCloseRules.addEventListener('click', () => {
      this.elements.rulesModal.classList.add('hidden');
    });

    // Close rules modal when clicking outside content
    this.elements.rulesModal.addEventListener('click', (e) => {
      if (e.target === this.elements.rulesModal) {
        this.elements.rulesModal.classList.add('hidden');
      }
    });

    // Settings modal
    this.elements.btnSettings.addEventListener('click', () => {
      this.elements.settingsModal.classList.remove('hidden');
    });

    this.elements.btnCloseSettings.addEventListener('click', () => {
      this.elements.settingsModal.classList.add('hidden');
    });

    // Close settings modal when clicking outside content
    this.elements.settingsModal.addEventListener('click', (e) => {
      if (e.target === this.elements.settingsModal) {
        this.elements.settingsModal.classList.add('hidden');
      }
    });

    // Theme selection
    this.elements.themeOptions.forEach(option => {
      option.addEventListener('click', () => {
        const theme = option.dataset.theme;
        this.setDeckTheme(theme);
      });
    });
  }

  /**
   * Bind game event listeners
   */
  bindGameEvents() {
    this.game.on('gameInitialized', () => {
      this.render();
    });

    this.game.on('turnStart', (data) => {
      this.selectedCards = [];
      this.selectedSpread = null;
      this.render();

      if (!data.player.isHuman) {
        this.handleAITurn(data.player);
      }
    });

    this.game.on('cardDrawn', () => {
      this.render();
    });

    this.game.on('spreadLaid', () => {
      this.render();
    });

    this.game.on('spreadHit', () => {
      this.render();
    });

    this.game.on('cardDiscarded', () => {
      this.render();
    });

    this.game.on('gameOver', (data) => {
      this.showGameOver(data);
    });
  }

  /**
   * Start a new game
   */
  startGame(numPlayers) {
    this.elements.startScreen.classList.add('hidden');
    this.game.initialize(numPlayers);
  }

  /**
   * Render the entire game UI
   */
  render() {
    this.renderOpponents();
    this.renderDeck();
    this.renderDiscardPile();
    this.renderSpreads();
    this.renderPlayerHand();
    this.renderPlayerInfo();
    this.renderTurnIndicator();
    this.renderMatchScores();
    this.updateActionButtons();
  }

  /**
   * Render opponent hands
   */
  renderOpponents() {
    this.elements.opponentArea.innerHTML = '';

    const opponents = this.game.players.filter(p => !p.isHuman);
    for (const opponent of opponents) {
      const opponentEl = CardRenderer.createOpponentHand(opponent);
      this.elements.opponentArea.appendChild(opponentEl);
    }
  }

  /**
   * Render the deck
   */
  renderDeck() {
    const count = this.game.getDeckCount();
    this.elements.deck.innerHTML = '';

    // Create stacked cards
    const stackCount = Math.min(count, 5);
    for (let i = 0; i < stackCount; i++) {
      const cardBack = CardRenderer.createCardBack();
      cardBack.style.position = 'absolute';
      cardBack.style.top = `${i * 2}px`;
      cardBack.style.left = `${i * 2}px`;
      this.elements.deck.appendChild(cardBack);
    }

    // Add count badge
    const countEl = document.createElement('span');
    countEl.id = 'deck-count';
    countEl.textContent = count;
    this.elements.deck.appendChild(countEl);

    // Update clickable state
    if (this.canDrawFromDeck()) {
      this.elements.deck.classList.remove('disabled');
    } else {
      this.elements.deck.classList.add('disabled');
    }
  }

  /**
   * Render the discard pile
   */
  renderDiscardPile() {
    this.elements.discardPile.innerHTML = '';

    const topCard = this.game.getTopDiscard();
    if (topCard) {
      const cardEl = CardRenderer.createCardElement(topCard, true, false);
      this.elements.discardPile.appendChild(cardEl);
    } else {
      const placeholder = CardRenderer.createEmptyPile();
      this.elements.discardPile.appendChild(placeholder);
    }

    // Add label
    const label = document.createElement('span');
    label.id = 'discard-label';
    label.textContent = 'Discard';
    this.elements.discardPile.appendChild(label);

    // Update clickable state
    if (this.canDrawFromDiscard()) {
      this.elements.discardPile.classList.remove('disabled');
    } else {
      this.elements.discardPile.classList.add('disabled');
    }
  }

  /**
   * Render all spreads on the table
   */
  renderSpreads() {
    this.elements.spreadsArea.innerHTML = '';

    for (const spread of this.game.spreadsOnTable) {
      const spreadEl = CardRenderer.createSpreadElement(spread);

      // Check if selected card can hit this spread (allowed in START_OF_TURN and ACTION phases)
      const canHitPhase = this.game.phase === PHASES.ACTION || this.game.phase === PHASES.START_OF_TURN;
      if (this.selectedCards.length === 1 && canHitPhase) {
        const card = this.getHumanPlayer().hand.find(
          c => c.id === this.selectedCards[0]
        );
        if (card && spread.canAddCard(card)) {
          spreadEl.classList.add('can-hit');
          spreadEl.addEventListener('click', () => {
            this.selectedSpread = spread;
            this.handleHitSpread();
          });
        }
      }

      this.elements.spreadsArea.appendChild(spreadEl);
    }
  }

  /**
   * Render the player's hand
   */
  renderPlayerHand() {
    this.elements.playerHand.innerHTML = '';

    const player = this.getHumanPlayer();
    if (!player) return;

    const isPlayerTurn = this.game.getCurrentPlayer() === player;
    // Allow card selection in both START_OF_TURN and ACTION phases
    const canSelect = isPlayerTurn &&
      (this.game.phase === PHASES.ACTION || this.game.phase === PHASES.START_OF_TURN);

    for (const card of player.hand) {
      const cardEl = CardRenderer.createCardElement(card, true, canSelect);

      if (this.selectedCards.includes(card.id)) {
        cardEl.classList.add('selected');
      }

      if (canSelect) {
        cardEl.addEventListener('click', () => {
          this.toggleCardSelection(card.id);
        });
      }

      this.elements.playerHand.appendChild(cardEl);
    }
  }

  /**
   * Render player info
   */
  renderPlayerInfo() {
    const player = this.getHumanPlayer();
    if (!player) return;

    this.elements.cardCount.textContent = `Cards: ${player.cardCount}`;
    this.elements.pointCount.textContent = `Points: ${player.calculatePoints()}`;
  }

  /**
   * Render match scores in header
   */
  renderMatchScores() {
    this.elements.matchScores.innerHTML = '';

    const matchScores = this.game.getMatchScores();
    for (const { player, score } of matchScores) {
      const scoreEl = document.createElement('div');
      scoreEl.className = `player-score${player.isHuman ? ' human' : ''}`;
      scoreEl.innerHTML = `
        <span class="name">${player.isHuman ? 'You' : player.name}:</span>
        <span class="points">${score} pts</span>
      `;
      this.elements.matchScores.appendChild(scoreEl);
    }
  }

  /**
   * Render turn indicator
   */
  renderTurnIndicator() {
    const currentPlayer = this.game.getCurrentPlayer();
    const isHumanTurn = currentPlayer.isHuman;

    if (this.game.phase === PHASES.GAME_OVER) {
      this.elements.turnIndicator.textContent = 'Game Over';
      this.elements.turnIndicator.classList.remove('your-turn');
    } else if (isHumanTurn) {
      let phaseText = 'Your turn';
      if (this.game.phase === PHASES.START_OF_TURN) {
        phaseText = 'Spread cards or click Draw';
      } else if (this.game.phase === PHASES.DRAW) {
        phaseText = 'Draw a card';
      } else if (this.game.phase === PHASES.ACTION) {
        phaseText = 'Play cards or discard';
      }
      this.elements.turnIndicator.textContent = phaseText;
      this.elements.turnIndicator.classList.add('your-turn');
    } else {
      this.elements.turnIndicator.innerHTML = `
        <span class="thinking-indicator">
          ${currentPlayer.name} thinking
          <span class="thinking-dots">
            <span></span><span></span><span></span>
          </span>
        </span>
      `;
      this.elements.turnIndicator.classList.remove('your-turn');
    }
  }

  /**
   * Update action button states
   */
  updateActionButtons() {
    const player = this.getHumanPlayer();
    const isPlayerTurn = this.game.getCurrentPlayer() === player;
    const inActionPhase = this.game.phase === PHASES.ACTION;
    const inStartPhase = this.game.phase === PHASES.START_OF_TURN;
    const inDrawPhase = this.game.phase === PHASES.DRAW;
    const canActOnCards = inActionPhase || inStartPhase;

    // Form Spread button (allowed in START_OF_TURN and ACTION phases)
    const canFormSpread = isPlayerTurn && canActOnCards &&
      this.selectedCards.length >= 3 &&
      this.isValidSpreadSelection();
    this.elements.btnFormSpread.disabled = !canFormSpread;

    // Hit Spread button (allowed in START_OF_TURN and ACTION phases)
    const canHit = isPlayerTurn && canActOnCards &&
      this.selectedCards.length === 1 &&
      this.canHitAnySpread();
    this.elements.btnHitSpread.disabled = !canHit;

    // Knock button (allowed at START_OF_TURN only)
    const canKnock = isPlayerTurn && inStartPhase && player && player.canKnock();
    this.elements.btnKnock.disabled = !canKnock;

    // Draw button (only in START_OF_TURN phase to proceed to draw)
    if (this.elements.btnDraw) {
      const canDraw = isPlayerTurn && inStartPhase;
      this.elements.btnDraw.disabled = !canDraw;
      this.elements.btnDraw.style.display = inStartPhase ? 'inline-block' : 'none';
    }

    // Discard button (only in ACTION phase)
    const canDiscard = isPlayerTurn && inActionPhase && this.selectedCards.length === 1;
    this.elements.btnDiscard.disabled = !canDiscard;
  }

  /**
   * Toggle card selection
   */
  toggleCardSelection(cardId) {
    const index = this.selectedCards.indexOf(cardId);
    if (index === -1) {
      this.selectedCards.push(cardId);
    } else {
      this.selectedCards.splice(index, 1);
    }
    this.render();
  }

  /**
   * Clear card selection
   */
  clearSelection() {
    this.selectedCards = [];
    this.selectedSpread = null;
    this.render();
  }

  /**
   * Check if current selection forms a valid spread
   */
  isValidSpreadSelection() {
    const player = this.getHumanPlayer();
    const cards = this.selectedCards
      .map(id => player.hand.find(c => c.id === id))
      .filter(Boolean);

    return Spread.validate(cards).valid;
  }

  /**
   * Check if selected card can hit any spread
   */
  canHitAnySpread() {
    if (this.selectedCards.length !== 1) return false;

    const player = this.getHumanPlayer();
    const card = player.hand.find(c => c.id === this.selectedCards[0]);
    if (!card) return false;

    return this.game.spreadsOnTable.some(spread => spread.canAddCard(card));
  }

  /**
   * Check if can draw from deck
   */
  canDrawFromDeck() {
    return this.game.isHumanTurn() &&
      (this.game.phase === PHASES.DRAW || this.game.phase === PHASES.START_OF_TURN) &&
      !this.game.isStockEmpty();
  }

  /**
   * Check if can draw from discard
   */
  canDrawFromDiscard() {
    return this.game.isHumanTurn() &&
      (this.game.phase === PHASES.DRAW || this.game.phase === PHASES.START_OF_TURN) &&
      this.game.getTopDiscard() !== null;
  }

  /**
   * Handle draw from deck
   */
  handleDrawFromDeck() {
    try {
      // Auto-transition to draw phase if at start of turn
      if (this.game.phase === PHASES.START_OF_TURN) {
        this.game.proceedToDraw();
      }
      this.game.drawFromDeck();
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle draw from discard
   */
  handleDrawFromDiscard() {
    try {
      // Auto-transition to draw phase if at start of turn
      if (this.game.phase === PHASES.START_OF_TURN) {
        this.game.proceedToDraw();
      }
      this.game.drawFromDiscard();
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle form spread action
   */
  handleFormSpread() {
    try {
      const player = this.getHumanPlayer();
      const cards = this.selectedCards
        .map(id => player.hand.find(c => c.id === id))
        .filter(Boolean);

      this.game.laySpread(cards);
      this.clearSelection();
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle hit spread action
   */
  handleHitSpread() {
    try {
      const player = this.getHumanPlayer();
      const card = player.hand.find(c => c.id === this.selectedCards[0]);

      // Find first spread that can accept this card if not already selected
      if (!this.selectedSpread) {
        this.selectedSpread = this.game.spreadsOnTable.find(s => s.canAddCard(card));
      }

      if (card && this.selectedSpread) {
        this.game.hitSpread(card, this.selectedSpread);
        this.clearSelection();
      }
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle proceed to draw (from START_OF_TURN phase)
   */
  handleProceedToDraw() {
    try {
      this.game.proceedToDraw();
      this.render();
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle knock action
   */
  handleKnock() {
    try {
      this.game.knock();
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle discard action
   */
  handleDiscard() {
    try {
      const player = this.getHumanPlayer();
      const card = player.hand.find(c => c.id === this.selectedCards[0]);

      if (card) {
        this.game.discard(card);
        this.clearSelection();
      }
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Handle AI turn
   */
  async handleAITurn(aiPlayer) {
    // Delay for AI "thinking"
    await this.delay(800);

    // START_OF_TURN phase: Check if AI should knock first
    if (this.game.phase === PHASES.START_OF_TURN) {
      if (aiPlayer.shouldKnock && aiPlayer.shouldKnock()) {
        try {
          this.game.knock();
          return;
        } catch (error) {
          // Can't knock, continue with normal turn
        }
      }

      // Try to form spreads before drawing
      if (aiPlayer.findAllSpreadsToLay) {
        const spreadsToLay = aiPlayer.findAllSpreadsToLay();
        for (const spreadInfo of spreadsToLay) {
          try {
            this.game.laySpread(spreadInfo.cards);
            this.showMessage(`${aiPlayer.name} laid a ${spreadInfo.type}`, 'info');
            await this.delay(500);

            if (this.game.isGameOver()) return;
          } catch (error) {
            // Skip invalid spread
          }
        }
      }

      // Try to hit spreads before drawing
      if (aiPlayer.findHitOpportunities) {
        const hits = aiPlayer.findHitOpportunities(this.game.spreadsOnTable);
        for (const hit of hits) {
          if (aiPlayer.hasCard(hit.card)) {
            try {
              this.game.hitSpread(hit.card, hit.spread);
              this.showMessage(`${aiPlayer.name} hit a spread`, 'info');
              await this.delay(400);

              if (this.game.isGameOver()) return;
            } catch (error) {
              // Skip invalid hit
            }
          }
        }
      }

      // Proceed to draw phase
      this.game.proceedToDraw();
      this.render();
    }

    // Draw phase
    const discardTop = this.game.getTopDiscard();
    const drawSource = aiPlayer.decideDraw ? aiPlayer.decideDraw(discardTop) : 'deck';

    await this.delay(400);

    if (drawSource === 'discard' && discardTop) {
      this.game.drawFromDiscard();
      this.showMessage(`${aiPlayer.name} drew from discard`, 'info');
    } else {
      this.game.drawFromDeck();
      this.showMessage(`${aiPlayer.name} drew from deck`, 'info');
    }

    await this.delay(600);

    // ACTION phase: Try to form spreads
    if (aiPlayer.findAllSpreadsToLay) {
      const spreadsToLay = aiPlayer.findAllSpreadsToLay();
      for (const spreadInfo of spreadsToLay) {
        try {
          this.game.laySpread(spreadInfo.cards);
          this.showMessage(`${aiPlayer.name} laid a ${spreadInfo.type}`, 'info');
          await this.delay(500);

          // Check if game ended
          if (this.game.isGameOver()) return;
        } catch (error) {
          // Skip invalid spread
        }
      }
    }

    // Try to hit spreads
    if (aiPlayer.findHitOpportunities) {
      const hits = aiPlayer.findHitOpportunities(this.game.spreadsOnTable);
      for (const hit of hits) {
        if (aiPlayer.hasCard(hit.card)) {
          try {
            this.game.hitSpread(hit.card, hit.spread);
            this.showMessage(`${aiPlayer.name} hit a spread`, 'info');
            await this.delay(400);

            if (this.game.isGameOver()) return;
          } catch (error) {
            // Skip invalid hit
          }
        }
      }
    }

    // Discard
    if (aiPlayer.hand.length > 0 && !this.game.isGameOver()) {
      const cardToDiscard = aiPlayer.decideDiscard ? aiPlayer.decideDiscard() : aiPlayer.hand[0];
      if (cardToDiscard) {
        await this.delay(400);
        this.game.discard(cardToDiscard);
        this.showMessage(`${aiPlayer.name} discarded ${cardToDiscard.toString()}`, 'info');
      }
    }
  }

  /**
   * Show game over modal
   */
  showGameOver(data) {
    const { winner, condition, knocker } = data;
    const isHumanWinner = winner.isHuman;

    // Apply round scoring
    const losers = this.game.applyRoundScoring();

    // Check if match has ended
    const matchEnded = this.game.checkMatchEnd();

    if (matchEnded) {
      // Match is over
      const matchWinner = this.game.matchWinner;
      const isHumanMatchWinner = matchWinner.isHuman;

      this.elements.gameOverTitle.textContent = isHumanMatchWinner ? 'Match Won!' : 'Match Lost!';
      this.elements.gameOverMessage.textContent = `${matchWinner.isHuman ? 'You win' : matchWinner.name + ' wins'} the match!`;

      // Show Continue button hidden, only New Game
      this.elements.btnContinueRound.classList.add('hidden');
    } else {
      // Round ended, match continues
      this.elements.gameOverTitle.textContent = `Round ${this.game.roundNumber} - ${isHumanWinner ? 'You Win!' : 'You Lose!'}`;

      // Set message based on condition
      let message = '';
      switch (condition) {
        case 'tonk':
          message = `${winner.isHuman ? 'You went' : winner.name + ' went'} out with an empty hand!`;
          break;
        case 'initial-tonk':
          message = `${winner.isHuman ? 'You had' : winner.name + ' had'} 49-50 points - Initial Tonk!`;
          break;
        case 'knock':
          message = `${knocker.isHuman ? 'You dropped' : knocker.name + ' dropped'} and had the lowest points!`;
          break;
        case 'caught':
          message = `${knocker.isHuman ? 'You dropped' : knocker.name + ' dropped'} but ${winner.isHuman ? 'you had' : winner.name + ' had'} fewer points!`;
          break;
        case 'stock-empty':
          message = `Stock ran out! ${winner.isHuman ? 'You had' : winner.name + ' had'} the lowest points.`;
          break;
        default:
          message = `${winner.isHuman ? 'You win' : winner.name + ' wins'}!`;
      }
      this.elements.gameOverMessage.textContent = message;

      // Show Continue button
      this.elements.btnContinueRound.classList.remove('hidden');
    }

    // Show scores with match totals
    this.elements.finalScores.innerHTML = '';

    // Add header for scores
    const headerRow = document.createElement('div');
    headerRow.className = 'score-row score-header';
    headerRow.innerHTML = `
      <span>Player</span>
      <span>Hand</span>
      <span>Match Total</span>
    `;
    this.elements.finalScores.appendChild(headerRow);

    const scores = this.game.getScores();
    scores.sort((a, b) => a.matchScore - b.matchScore);

    for (const score of scores) {
      const row = document.createElement('div');
      row.className = 'score-row';
      if (score.player === winner) {
        row.classList.add('winner');
      }

      // Find if this player had points added
      const loserInfo = losers.find(l => l.player === score.player);
      const pointsAddedText = loserInfo ? ` (+${loserInfo.pointsAdded})` : '';

      row.innerHTML = `
        <span>${score.player.isHuman ? 'You' : score.player.name}</span>
        <span>${score.points} pts</span>
        <span>${score.matchScore}${pointsAddedText}</span>
      `;
      this.elements.finalScores.appendChild(row);
    }

    this.elements.gameOverModal.classList.remove('hidden');
  }

  /**
   * Show a message
   */
  showMessage(text, type = 'info') {
    this.elements.messageArea.textContent = text;
    this.elements.messageArea.className = `visible ${type}`;

    if (this.messageTimeout) {
      clearTimeout(this.messageTimeout);
    }

    this.messageTimeout = setTimeout(() => {
      this.elements.messageArea.classList.remove('visible');
    }, 2500);
  }

  /**
   * Get the human player
   */
  getHumanPlayer() {
    return this.game.players.find(p => p.isHuman);
  }

  /**
   * Delay helper
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Initialize theme from storage
   */
  initializeTheme() {
    const savedTheme = loadDeckTheme();
    this.setDeckTheme(savedTheme, false);
  }

  /**
   * Set the deck theme
   */
  setDeckTheme(theme, save = true) {
    // Apply theme to body
    document.body.dataset.deckTheme = theme;

    // Update selected state on theme options
    this.elements.themeOptions.forEach(option => {
      if (option.dataset.theme === theme) {
        option.classList.add('selected');
        option.querySelector('.theme-preview').classList.add('selected');
      } else {
        option.classList.remove('selected');
        option.querySelector('.theme-preview').classList.remove('selected');
      }
    });

    // Save to storage
    if (save) {
      saveDeckTheme(theme);
    }
  }
}
