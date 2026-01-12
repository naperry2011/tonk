import { CardRenderer } from './CardRenderer.js';
import { CardLayoutManager } from './CardLayoutManager.js';
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
    this.layoutManager = new CardLayoutManager();

    // Drag and drop state
    this.draggedCardIndex = null;
    this.touchDragState = null;

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
      opponentLeftArea: document.querySelector('.opponent-left-area'),
      opponentRightArea: document.querySelector('.opponent-right-area'),
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
      themeOptions: document.querySelectorAll('.theme-option'),
      // Betting elements
      chipDisplay: document.getElementById('chip-display'),
      playerChips: document.getElementById('player-chips'),
      potDisplay: document.getElementById('pot-display'),
      potAmount: document.getElementById('pot-amount'),
      bettingControls: document.getElementById('betting-controls'),
      bettingToggle: document.getElementById('betting-toggle'),
      raiseButtons: document.querySelectorAll('.raise-btn')
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
      this.openModal(this.elements.rulesModal, this.elements.btnCloseRules);
    });

    this.elements.btnCloseRules.addEventListener('click', () => {
      this.closeModal(this.elements.rulesModal, this.elements.btnRules);
    });

    // Close rules modal when clicking outside content
    this.elements.rulesModal.addEventListener('click', (e) => {
      if (e.target === this.elements.rulesModal) {
        this.closeModal(this.elements.rulesModal, this.elements.btnRules);
      }
    });

    // Settings modal
    this.elements.btnSettings.addEventListener('click', () => {
      this.openModal(this.elements.settingsModal, this.elements.btnCloseSettings);
    });

    this.elements.btnCloseSettings.addEventListener('click', () => {
      this.closeModal(this.elements.settingsModal, this.elements.btnSettings);
    });

    // Close settings modal when clicking outside content
    this.elements.settingsModal.addEventListener('click', (e) => {
      if (e.target === this.elements.settingsModal) {
        this.closeModal(this.elements.settingsModal, this.elements.btnSettings);
      }
    });

    // Global escape key handler for modals
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        if (!this.elements.rulesModal.classList.contains('hidden')) {
          this.closeModal(this.elements.rulesModal, this.elements.btnRules);
        }
        if (!this.elements.settingsModal.classList.contains('hidden')) {
          this.closeModal(this.elements.settingsModal, this.elements.btnSettings);
        }
      }
    });

    // Theme selection
    this.elements.themeOptions.forEach(option => {
      option.addEventListener('click', () => {
        const theme = option.dataset.theme;
        this.setDeckTheme(theme);
      });

      // Keyboard support for theme options
      option.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          const theme = option.dataset.theme;
          this.setDeckTheme(theme);
        }
      });
    });

    // Raise buttons
    this.elements.raiseButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        const amount = parseInt(btn.dataset.amount, 10);
        this.handleRaise(amount);
      });
    });

    // Betting toggle for mobile
    if (this.elements.bettingToggle) {
      this.elements.bettingToggle.addEventListener('click', () => {
        this.toggleBettingControls();
      });
    }
  }

  /**
   * Toggle betting controls visibility on mobile
   */
  toggleBettingControls() {
    const controls = this.elements.bettingControls;
    const toggle = this.elements.bettingToggle;

    if (controls.classList.contains('expanded')) {
      controls.classList.remove('expanded');
      toggle.classList.remove('active');
      toggle.textContent = 'Raise Bet';
    } else {
      controls.classList.add('expanded');
      toggle.classList.add('active');
      toggle.textContent = 'Hide Bets';
    }
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
    // Set player count for CSS circular layout
    this.elements.gameContainer.dataset.playerCount = numPlayers;
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
    this.renderChips();
    this.renderPot();
    this.updateActionButtons();
  }

  /**
   * Render opponent hands in circular table layout
   * - 2 players: 1 opponent at top
   * - 3 players: 2 opponents at top
   * - 4 players: 1 left, 1 top, 1 right (circular)
   */
  renderOpponents() {
    // Clear all opponent areas
    this.elements.opponentArea.innerHTML = '';
    if (this.elements.opponentLeftArea) {
      this.elements.opponentLeftArea.innerHTML = '';
    }
    if (this.elements.opponentRightArea) {
      this.elements.opponentRightArea.innerHTML = '';
    }

    const opponents = this.game.players.filter(p => !p.isHuman);
    const playerCount = this.game.players.length;

    if (playerCount === 4 && opponents.length === 3) {
      // 4-player circular layout: left, top, right
      this.renderOpponentInArea(opponents[0], this.elements.opponentLeftArea);
      this.renderOpponentInArea(opponents[1], this.elements.opponentArea);
      this.renderOpponentInArea(opponents[2], this.elements.opponentRightArea);
    } else if (playerCount === 3 && opponents.length === 2) {
      // 3-player circular layout: left and right (no top)
      this.renderOpponentInArea(opponents[0], this.elements.opponentLeftArea);
      this.renderOpponentInArea(opponents[1], this.elements.opponentRightArea);
    } else {
      // 2 players: opponent at top
      for (const opponent of opponents) {
        this.renderOpponentInArea(opponent, this.elements.opponentArea);
      }
    }
  }

  /**
   * Render a single opponent in the specified area
   */
  renderOpponentInArea(opponent, areaElement) {
    if (!areaElement) return;

    const opponentEl = CardRenderer.createOpponentHand(opponent);
    areaElement.appendChild(opponentEl);

    // Register opponent cards container for dynamic layout
    const cardsContainer = opponentEl.querySelector('.opponent-cards');
    if (cardsContainer) {
      this.layoutManager.observe(cardsContainer, 'opponent');
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

      // Register spread cards container for dynamic layout
      const cardsContainer = spreadEl.querySelector('.spread-cards');
      if (cardsContainer) {
        this.layoutManager.observe(cardsContainer, 'spread');
      }
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

    player.hand.forEach((card, index) => {
      const cardEl = CardRenderer.createCardElement(card, true, canSelect);
      cardEl.dataset.handIndex = index;

      if (this.selectedCards.includes(card.id)) {
        cardEl.classList.add('selected');
      }

      // Enable drag and drop for reordering (always available during player's turn)
      if (isPlayerTurn) {
        cardEl.draggable = true;
        this.setupCardDragHandlers(cardEl, index, player);
      }

      if (canSelect) {
        cardEl.addEventListener('click', (e) => {
          // Don't toggle selection if we just finished a drag
          if (this.draggedCardIndex !== null) return;
          this.toggleCardSelection(card.id);
        });
      }

      this.elements.playerHand.appendChild(cardEl);
    });

    // Register player hand for dynamic layout
    this.layoutManager.observe(this.elements.playerHand, 'hand');
  }

  /**
   * Set up drag and drop handlers for a card element
   */
  setupCardDragHandlers(cardEl, index, player) {
    // Mouse drag handlers
    cardEl.addEventListener('dragstart', (e) => {
      this.draggedCardIndex = index;
      cardEl.classList.add('dragging');
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', index.toString());
    });

    cardEl.addEventListener('dragend', () => {
      cardEl.classList.remove('dragging');
      this.clearDragOverStates();
      this.draggedCardIndex = null;
    });

    cardEl.addEventListener('dragover', (e) => {
      e.preventDefault();
      if (this.draggedCardIndex === null || this.draggedCardIndex === index) return;

      e.dataTransfer.dropEffect = 'move';
      this.clearDragOverStates();
      cardEl.classList.add('drag-over');
    });

    cardEl.addEventListener('dragleave', () => {
      cardEl.classList.remove('drag-over');
    });

    cardEl.addEventListener('drop', (e) => {
      e.preventDefault();
      if (this.draggedCardIndex === null || this.draggedCardIndex === index) return;

      player.reorderCard(this.draggedCardIndex, index);
      this.clearDragOverStates();
      this.draggedCardIndex = null;
      this.renderPlayerHand();
    });

    // Touch drag handlers for mobile
    this.setupTouchDragHandlers(cardEl, index, player);
  }

  /**
   * Set up touch drag handlers for mobile devices
   */
  setupTouchDragHandlers(cardEl, index, player) {
    let touchTimeout = null;
    let isDragging = false;
    let startX = 0;
    let startY = 0;

    cardEl.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;

      // Start a timer to detect hold for drag
      touchTimeout = setTimeout(() => {
        isDragging = true;
        this.draggedCardIndex = index;
        cardEl.classList.add('dragging');

        // Provide haptic feedback if available
        if (navigator.vibrate) {
          navigator.vibrate(50);
        }
      }, 150);
    }, { passive: true });

    cardEl.addEventListener('touchmove', (e) => {
      const touchX = e.touches[0].clientX;
      const touchY = e.touches[0].clientY;

      // Cancel drag initiation if user moves finger before hold threshold
      if (!isDragging && touchTimeout) {
        const moveDistance = Math.sqrt(
          Math.pow(touchX - startX, 2) + Math.pow(touchY - startY, 2)
        );
        if (moveDistance > 10) {
          clearTimeout(touchTimeout);
          touchTimeout = null;
        }
      }

      if (!isDragging) return;

      e.preventDefault();

      // Find card under touch point
      const elemBelow = document.elementFromPoint(touchX, touchY);
      const cardBelow = elemBelow?.closest('.card[data-hand-index]');

      this.clearDragOverStates();
      if (cardBelow && cardBelow !== cardEl) {
        cardBelow.classList.add('drag-over');
      }
    }, { passive: false });

    cardEl.addEventListener('touchend', (e) => {
      clearTimeout(touchTimeout);
      touchTimeout = null;

      if (!isDragging) return;

      isDragging = false;
      cardEl.classList.remove('dragging');

      // Find card under final touch point
      const touch = e.changedTouches[0];
      const elemBelow = document.elementFromPoint(touch.clientX, touch.clientY);
      const cardBelow = elemBelow?.closest('.card[data-hand-index]');

      if (cardBelow && cardBelow !== cardEl) {
        const targetIndex = parseInt(cardBelow.dataset.handIndex, 10);
        player.reorderCard(this.draggedCardIndex, targetIndex);
        this.renderPlayerHand();
      }

      this.clearDragOverStates();
      this.draggedCardIndex = null;
    });

    cardEl.addEventListener('touchcancel', () => {
      clearTimeout(touchTimeout);
      touchTimeout = null;
      isDragging = false;
      cardEl.classList.remove('dragging');
      this.clearDragOverStates();
      this.draggedCardIndex = null;
    });
  }

  /**
   * Clear drag-over visual states from all cards
   */
  clearDragOverStates() {
    const cards = this.elements.playerHand.querySelectorAll('.card');
    cards.forEach(card => card.classList.remove('drag-over'));
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
   * Render player's chip count
   */
  renderChips() {
    const player = this.getHumanPlayer();
    if (!player) return;

    this.elements.playerChips.textContent = player.chips;
  }

  /**
   * Render the pot amount
   */
  renderPot() {
    this.elements.potAmount.textContent = this.game.getPot();
  }

  /**
   * Handle raise button click
   */
  handleRaise(amount) {
    try {
      const player = this.getHumanPlayer();
      if (!player || !this.game.isHumanTurn()) return;

      this.game.placeBet(player, amount);
      this.showMessage(`You raised ${amount} chips`, 'info');
      this.render();
    } catch (error) {
      this.showMessage(error.message, 'error');
    }
  }

  /**
   * Render turn indicator (disabled - element removed from UI)
   */
  renderTurnIndicator() {
    // Turn indicator has been removed from the UI
    // This method is kept for compatibility but does nothing
    if (!this.elements.turnIndicator) return;
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

    // Raise buttons (available during player's turn in ACTION phase)
    const canBet = isPlayerTurn && inActionPhase;
    this.elements.raiseButtons.forEach(btn => {
      const amount = parseInt(btn.dataset.amount, 10);
      btn.disabled = !canBet || !player.canAfford(amount);
    });
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

    // Award pot to winner
    const potWinnings = this.game.awardPot(winner);

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

    // Show pot winnings message
    const chipsMessage = document.createElement('div');
    chipsMessage.className = 'chips-won-message';
    chipsMessage.innerHTML = `
      <span class="pot-icon"></span>
      <span>${winner.isHuman ? 'You' : winner.name} won <strong>${potWinnings}</strong> chips!</span>
    `;
    this.elements.finalScores.appendChild(chipsMessage);

    // Add header for scores
    const headerRow = document.createElement('div');
    headerRow.className = 'score-row score-header';
    headerRow.innerHTML = `
      <span>Player</span>
      <span>Hand</span>
      <span>Chips</span>
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

      row.innerHTML = `
        <span>${score.player.isHuman ? 'You' : score.player.name}</span>
        <span>${score.points} pts</span>
        <span>${score.player.chips}</span>
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
      const isSelected = option.dataset.theme === theme;
      if (isSelected) {
        option.classList.add('selected');
        option.querySelector('.theme-preview').classList.add('selected');
        option.setAttribute('aria-checked', 'true');
      } else {
        option.classList.remove('selected');
        option.querySelector('.theme-preview').classList.remove('selected');
        option.setAttribute('aria-checked', 'false');
      }
    });

    // Save to storage
    if (save) {
      saveDeckTheme(theme);
    }
  }

  /**
   * Open a modal with focus management
   */
  openModal(modal, focusElement) {
    this.lastFocusedElement = document.activeElement;
    modal.classList.remove('hidden');

    // Focus the first focusable element or the specified element
    if (focusElement) {
      focusElement.focus();
    } else {
      const focusable = modal.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
      if (focusable) focusable.focus();
    }

    // Set up focus trap
    this.setupFocusTrap(modal);
  }

  /**
   * Close a modal and restore focus
   */
  closeModal(modal, returnFocusTo) {
    modal.classList.add('hidden');
    this.removeFocusTrap(modal);

    // Return focus to the element that opened the modal
    if (returnFocusTo) {
      returnFocusTo.focus();
    } else if (this.lastFocusedElement) {
      this.lastFocusedElement.focus();
    }
  }

  /**
   * Set up focus trap within a modal
   */
  setupFocusTrap(modal) {
    const focusableElements = modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    if (focusableElements.length === 0) return;

    const firstFocusable = focusableElements[0];
    const lastFocusable = focusableElements[focusableElements.length - 1];

    modal._focusTrapHandler = (e) => {
      if (e.key !== 'Tab') return;

      if (e.shiftKey) {
        // Shift + Tab
        if (document.activeElement === firstFocusable) {
          e.preventDefault();
          lastFocusable.focus();
        }
      } else {
        // Tab
        if (document.activeElement === lastFocusable) {
          e.preventDefault();
          firstFocusable.focus();
        }
      }
    };

    modal.addEventListener('keydown', modal._focusTrapHandler);
  }

  /**
   * Remove focus trap from a modal
   */
  removeFocusTrap(modal) {
    if (modal._focusTrapHandler) {
      modal.removeEventListener('keydown', modal._focusTrapHandler);
      delete modal._focusTrapHandler;
    }
  }
}
