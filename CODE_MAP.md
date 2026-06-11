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
* tonk_settings (includes deckTheme)
* tonk_statistics
* tonk_game_state (reserved, unused)

---

## Tests

Category: Other

Primary Files:
* tests/Card.test.js, tests/Spread.test.js, tests/rules.test.js, tests/Player.test.js, tests/Deck.test.js, tests/Game.test.js - Vitest suites over src/game/

---

## Build System

Category: Infra

Primary Files:
* vite.config.js - Vite configuration
* eslint.config.js - ESLint flat config
* package.json - Project metadata, scripts (dev, build, preview, test, lint)
* .github/workflows/ci.yml - CI: install, lint, test, build

External Integrations:
* Vite, Vitest, ESLint (dev dependencies only)
* GitHub Actions
