# CODE_MAP.md

## Game Engine

Category: Service

Primary Files:
* src/game/Game.js - Game controller, state machine, event emitter
* src/game/rules.js - Constants, phases, win conditions, betting config

Supporting Files:
* src/game/Card.js - Card representation, value calculation
* src/game/Deck.js - Deck creation, shuffle, draw/discard piles
* src/game/Spread.js - Spread validation (books/runs), card addition
* src/game/Player.js - Base player, hand management, point calculation

Entry Points:
* Game constructor called from src/main.js

---

## AI System

Category: Service

Primary Files:
* src/game/ComputerPlayer.js - AI decision-making (draw, discard, knock, bet, spread)

Supporting Files:
* src/game/Player.js - Base class
* src/game/Spread.js - Spread analysis for AI decisions
* src/game/rules.js - Thresholds and constants

---

## UI Layer

Category: UI

Primary Files:
* src/ui/GameUI.js - Main UI controller, event subscriptions, input handling, modals
* src/ui/CardRenderer.js - Card DOM element factory (face-up, face-down, spreads)
* src/ui/CardLayoutManager.js - Responsive card sizing via ResizeObserver
* src/ui/animations.js - CSS-based animation utilities (deal, flip, move, shake, pulse)

Supporting Files:
* index.html - Game structure, modal templates
* styles/main.css - Global styles, CSS variables
* styles/cards.css - Card element styling
* styles/layout.css - Game table layout, opponent areas
* styles/themes.css - Deck theme variations

---

## Persistence

Category: Service

Primary Files:
* src/utils/storage.js - LocalStorage wrapper for stats, settings, themes

External Integrations:
* Browser localStorage

localStorage Keys:
* tonk_deck_theme
* tonk_statistics
* tonk_settings

---

## Utilities

Category: Other

Primary Files:
* src/utils/helpers.js - generateId, shuffleArray, delay, debounce, clamp, isMobile

---

## Build System

Category: Infra

Primary Files:
* vite.config.js - Vite configuration
* package.json - Project metadata, scripts

External Integrations:
* Vite (dev dependency only)
