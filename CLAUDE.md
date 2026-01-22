# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
npm install        # Install dependencies
npm run dev        # Start Vite dev server (http://localhost:5173)
npm run build      # Bundle to dist/
npm run preview    # Preview production build
```

No linting or testing framework is configured.

## Architecture Overview

Tonk is a browser-based card game built with vanilla JavaScript (ES6 modules), HTML5, CSS3, and Vite. No external runtime dependencies.

### Core Structure

- `src/main.js` - Entry point; creates Game and GameUI instances
- `src/game/` - Pure game logic (no DOM)
- `src/ui/` - DOM rendering and user interaction
- `src/utils/` - Storage and helper utilities
- `styles/` - CSS files (main.css, cards.css, layout.css, themes.css)

### Key Patterns

**Event-Driven Architecture**: Game.js is a custom event emitter. GameUI subscribes via `game.on(event, callback)` and updates the DOM reactively. Key events: `gameInitialized`, `turnStart`, `turnEnd`, `cardDrawn`, `cardDiscarded`, `spreadLaid`, `spreadHit`, `knock`, `gameOver`.

**Game Phases** (defined in `rules.js`): `PRE_GAME` → `INITIAL_TONK_CHECK` → `START_OF_TURN` → `DRAW` → `ACTION` → `GAME_OVER`. Actions must check `game.phase` before executing.

**Turn Flow**: At `START_OF_TURN`, player can knock or lay spreads. Call `game.proceedToDraw()` to enter `DRAW` phase. After drawing, phase becomes `ACTION` where player can lay spreads, hit spreads, then must discard.

**Spread Validation**: `Spread.validate(cards)` returns `{ valid: bool, type: 'book'|'run'|null }`. Books = 3-4 same rank. Runs = 3+ sequential same suit.

**AI**: ComputerPlayer extends Player. Key methods: `decideDraw()`, `findBestSpread()`, `shouldKnock()`, `decideDiscard()`, `decideBet()`.

**Betting System**: Ante-based betting with chips. Constants in `rules.js`: `BETTING.STARTING_CHIPS`, `BETTING.ANTE_AMOUNT`, `BETTING.RAISE_OPTIONS`.

### Debugging

In dev mode (`npm run dev`), `window.game` and `window.ui` are available for console inspection.

### localStorage Keys

- `tonk_deck_theme` - Selected card theme
- `tonk_statistics` - Win/loss stats
- `tonk_settings` - User preferences

## Game Rules Quick Reference

- **Spreads**: Books (3-4 same rank) or Runs (3+ sequential same suit)
- **Card Points**: A=1, 2-10=face value, J/Q/K=10
- **Initial Tonk**: 49-50 points at deal = automatic win (if multiple players have it, redeal)
- **Knock/Drop**: At start of turn, claim lowest points. If wrong, opponent with lowest wins ("caught")
- **Win Conditions**: TONK (empty hand), INITIAL_TONK, KNOCK, CAUGHT, STOCK_EMPTY
- **Match**: First to 100 points loses
