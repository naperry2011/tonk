/**
 * CardLayoutManager - Dynamic card layout and overlap calculations
 *
 * Manages responsive card positioning by dynamically calculating overlap
 * based on container width and number of cards, ensuring cards always
 * fit within their container across all screen sizes.
 */
export class CardLayoutManager {
  constructor() {
    this.resizeObserver = null;
    this.observedContainers = new Map();

    // Configuration for layout calculations
    this.config = {
      minVisiblePercent: 0.30,  // Minimum 30% of card must be visible (touch-friendly)
      maxOverlap: 0.70,         // Maximum 70% overlap allowed
      containerPadding: 16,     // Account for container padding (8px each side)
    };

    this.init();
  }

  /**
   * Initialize the layout manager
   */
  init() {
    // Create ResizeObserver for responsive updates
    this.resizeObserver = new ResizeObserver(entries => {
      for (const entry of entries) {
        this.updateLayout(entry.target);
      }
    });

    // Listen for orientation changes
    window.addEventListener('orientationchange', () => {
      // Small delay to allow layout to settle after orientation change
      setTimeout(() => this.updateAllLayouts(), 100);
    });

    // Also listen for resize events as a fallback
    window.addEventListener('resize', this.debounce(() => {
      this.updateAllLayouts();
    }, 150));
  }

  /**
   * Register a container for dynamic layout management
   * @param {HTMLElement} container - The container element
   * @param {string} type - Container type: 'hand', 'opponent', or 'spread'
   */
  observe(container, type = 'hand') {
    if (!container) return;

    // Store container config
    this.observedContainers.set(container, { type });

    // Start observing for size changes
    this.resizeObserver.observe(container);

    // Initial layout update
    this.updateLayout(container);
  }

  /**
   * Unregister a container from layout management
   * @param {HTMLElement} container - The container to unobserve
   */
  unobserve(container) {
    if (!container) return;

    this.resizeObserver.unobserve(container);
    this.observedContainers.delete(container);
  }

  /**
   * Calculate and apply optimal overlap for a container
   * @param {HTMLElement} container - The container element
   */
  updateLayout(container) {
    const config = this.observedContainers.get(container);
    if (!config) return;

    const cards = container.querySelectorAll('.card');
    const cardCount = cards.length;

    // No cards or single card - no overlap needed
    if (cardCount <= 1) {
      cards.forEach(card => {
        card.style.marginLeft = '0';
      });
      return;
    }

    // Get dimensions
    const containerWidth = container.clientWidth - this.config.containerPadding;
    const cardWidth = this.getCardWidth(container, config.type);

    // Calculate optimal overlap
    const overlap = this.calculateOptimalOverlap(
      containerWidth,
      cardWidth,
      cardCount
    );

    // Calculate the margin in pixels
    const marginPx = -cardWidth * overlap;

    // Apply margin to each card except the first
    cards.forEach((card, index) => {
      if (index > 0) {
        card.style.marginLeft = `${marginPx}px`;
      } else {
        card.style.marginLeft = '0';
      }
    });

    // Check if container needs scroll indicator
    this.updateScrollIndicator(container, containerWidth, cardWidth, cardCount, overlap);
  }

  /**
   * Calculate optimal overlap to fit cards in container
   * @param {number} containerWidth - Available width in pixels
   * @param {number} cardWidth - Width of a single card in pixels
   * @param {number} cardCount - Number of cards
   * @returns {number} Overlap ratio (0 to maxOverlap)
   */
  calculateOptimalOverlap(containerWidth, cardWidth, cardCount) {
    // Total width needed with no overlap
    const noOverlapWidth = cardWidth * cardCount;

    // If cards fit without overlap, use no overlap
    if (noOverlapWidth <= containerWidth) {
      return 0;
    }

    // Calculate required overlap
    // Formula: containerWidth = cardWidth + (cardCount - 1) * cardWidth * (1 - overlap)
    // Solving for overlap:
    // containerWidth = cardWidth + (cardCount - 1) * cardWidth - (cardCount - 1) * cardWidth * overlap
    // containerWidth = cardCount * cardWidth - (cardCount - 1) * cardWidth * overlap
    // (cardCount - 1) * cardWidth * overlap = cardCount * cardWidth - containerWidth
    // overlap = (cardCount * cardWidth - containerWidth) / ((cardCount - 1) * cardWidth)

    const visiblePerCard = (containerWidth - cardWidth) / (cardCount - 1);
    const overlap = 1 - (visiblePerCard / cardWidth);

    // Clamp overlap to acceptable range
    const minOverlap = 0;
    const maxOverlap = 1 - this.config.minVisiblePercent;

    return Math.min(Math.max(overlap, minOverlap), maxOverlap);
  }

  /**
   * Get card width based on container type and current CSS variables
   * @param {HTMLElement} container - The container element
   * @param {string} type - Container type
   * @returns {number} Card width in pixels
   */
  getCardWidth(container, type) {
    const styles = getComputedStyle(document.documentElement);
    const baseWidth = parseFloat(styles.getPropertyValue('--card-width')) || 70;

    if (type === 'opponent') {
      const scale = parseFloat(styles.getPropertyValue('--card-scale-opponent')) || 0.65;
      return baseWidth * scale;
    } else if (type === 'spread') {
      const scale = parseFloat(styles.getPropertyValue('--card-scale-spread')) || 0.7;
      return baseWidth * scale;
    }

    // Player hand - use player scale (for 4-player mode scaling)
    const playerScale = parseFloat(styles.getPropertyValue('--card-scale-player')) || 1;
    return baseWidth * playerScale;
  }

  /**
   * Update scroll indicator visibility
   * @param {HTMLElement} container - The container element
   * @param {number} containerWidth - Container width
   * @param {number} cardWidth - Card width
   * @param {number} cardCount - Number of cards
   * @param {number} overlap - Current overlap ratio
   */
  updateScrollIndicator(container, containerWidth, cardWidth, cardCount, overlap) {
    // Calculate actual content width
    const contentWidth = cardWidth + (cardCount - 1) * cardWidth * (1 - overlap);

    // If content overflows (at max overlap), show scroll indicator
    if (contentWidth > containerWidth) {
      container.classList.add('scrollable');
    } else {
      container.classList.remove('scrollable');
    }
  }

  /**
   * Update all observed containers
   */
  updateAllLayouts() {
    for (const container of this.observedContainers.keys()) {
      this.updateLayout(container);
    }
  }

  /**
   * Debounce helper function
   * @param {Function} func - Function to debounce
   * @param {number} wait - Wait time in milliseconds
   * @returns {Function} Debounced function
   */
  debounce(func, wait) {
    let timeout;
    return (...args) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }

  /**
   * Clean up resources
   */
  destroy() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    this.observedContainers.clear();
  }
}
