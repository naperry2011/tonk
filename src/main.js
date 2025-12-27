/**
 * Tonk Card Game - Main Entry Point
 */

import { Game } from './game/Game.js';
import { GameUI } from './ui/GameUI.js';

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  // Create game instance
  const game = new Game();

  // Create UI controller
  const ui = new GameUI(game);

  // Expose game for debugging (optional, remove in production)
  if (import.meta.env.DEV) {
    window.game = game;
    window.ui = ui;
    console.log('Tonk Game loaded. Access game state via window.game');
  }
});
