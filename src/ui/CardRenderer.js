/**
 * Renders playing cards as DOM elements
 */
export class CardRenderer {
  /**
   * Create a card element
   */
  static createCardElement(card, faceUp = true, selectable = false) {
    const cardEl = document.createElement('div');
    cardEl.className = 'card';
    cardEl.dataset.cardId = card.id;
    cardEl.dataset.suit = card.suit;
    cardEl.dataset.rank = card.rank;

    if (!faceUp) {
      cardEl.classList.add('card-back');
      return cardEl;
    }

    if (selectable) {
      cardEl.classList.add('selectable');
    }

    // Top left corner
    const topLeft = document.createElement('div');
    topLeft.className = 'card-corner top-left';
    topLeft.innerHTML = `
      <span class="rank">${card.rank}</span>
      <span class="suit">${card.getSuitSymbol()}</span>
    `;
    cardEl.appendChild(topLeft);

    // Center
    const center = document.createElement('div');
    center.className = 'card-center';
    center.innerHTML = `<span class="suit-large">${card.getSuitSymbol()}</span>`;
    cardEl.appendChild(center);

    // Bottom right corner
    const bottomRight = document.createElement('div');
    bottomRight.className = 'card-corner bottom-right';
    bottomRight.innerHTML = `
      <span class="rank">${card.rank}</span>
      <span class="suit">${card.getSuitSymbol()}</span>
    `;
    cardEl.appendChild(bottomRight);

    return cardEl;
  }

  /**
   * Create a face-down card element
   */
  static createCardBack() {
    const cardEl = document.createElement('div');
    cardEl.className = 'card card-back';
    return cardEl;
  }

  /**
   * Create a deck stack element
   */
  static createDeckStack(count) {
    const wrapper = document.createElement('div');
    wrapper.className = 'deck-stack';

    // Create stacked card appearance
    const stackCount = Math.min(count, 5);
    for (let i = 0; i < stackCount; i++) {
      const cardBack = this.createCardBack();
      cardBack.style.position = 'absolute';
      cardBack.style.top = `${i * 2}px`;
      cardBack.style.left = `${i * 2}px`;
      wrapper.appendChild(cardBack);
    }

    // Add count badge
    const badge = document.createElement('span');
    badge.className = 'deck-count-badge';
    badge.textContent = count;
    wrapper.appendChild(badge);

    return wrapper;
  }

  /**
   * Create an empty placeholder for discard pile
   */
  static createEmptyPile() {
    const placeholder = document.createElement('div');
    placeholder.className = 'card card-placeholder';
    placeholder.innerHTML = '<span class="placeholder-text">Empty</span>';
    return placeholder;
  }

  /**
   * Create a spread display element
   */
  static createSpreadElement(spread) {
    const spreadEl = document.createElement('div');
    spreadEl.className = `spread spread-${spread.type}`;
    spreadEl.dataset.spreadId = spread.id;

    // Add label
    const label = document.createElement('div');
    label.className = 'spread-label';
    label.textContent = spread.type === 'book' ?
      `${spread.cards[0].rank}s` :
      `Run`;
    spreadEl.appendChild(label);

    // Add cards
    const cardsContainer = document.createElement('div');
    cardsContainer.className = 'spread-cards';

    for (const card of spread.cards) {
      const cardEl = this.createCardElement(card, true, false);
      cardEl.classList.add('spread-card');
      cardsContainer.appendChild(cardEl);
    }
    spreadEl.appendChild(cardsContainer);

    return spreadEl;
  }

  /**
   * Create opponent hand display (face-down cards)
   */
  static createOpponentHand(player) {
    const container = document.createElement('div');
    container.className = 'opponent-hand';
    container.dataset.playerId = player.id;

    const nameLabel = document.createElement('div');
    nameLabel.className = 'opponent-name';
    nameLabel.textContent = player.name;
    container.appendChild(nameLabel);

    const cardsContainer = document.createElement('div');
    cardsContainer.className = 'opponent-cards';

    for (let i = 0; i < player.cardCount; i++) {
      const cardBack = this.createCardBack();
      cardBack.classList.add('opponent-card');
      cardsContainer.appendChild(cardBack);
    }
    container.appendChild(cardsContainer);

    const info = document.createElement('div');
    info.className = 'opponent-info';
    info.textContent = `${player.cardCount} cards`;
    container.appendChild(info);

    return container;
  }

  /**
   * Update selected state of a card
   */
  static setCardSelected(cardEl, selected) {
    if (selected) {
      cardEl.classList.add('selected');
    } else {
      cardEl.classList.remove('selected');
    }
  }

  /**
   * Add highlight to a card element
   */
  static highlightCard(cardEl, type = 'default') {
    cardEl.classList.add('highlighted', `highlight-${type}`);
  }

  /**
   * Remove highlight from a card element
   */
  static removeHighlight(cardEl) {
    cardEl.classList.remove('highlighted', 'highlight-default', 'highlight-valid', 'highlight-invalid');
  }
}
