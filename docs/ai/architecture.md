# Architecture

System design at a glance. Pair with CODE_MAP.md (file map) and DATA_FLOW.md (system flows).

## System Overview

Browser-based Tonk card game. Single-page application served as static files. All logic runs client-side.

**Style:** Monolith (client-side SPA)
**Hosting:** Static file hosting (any provider)

## Core Components

### Game Engine (src/game/)
- **Responsibility:** Game state machine, rules enforcement, turn flow, scoring
- **Tech:** Vanilla JS ES6 modules, custom event emitter
- **Key files:** Game.js, rules.js, Deck.js, Card.js, Player.js, Spread.js
- **Depends on:** Nothing external

### AI System (src/game/ComputerPlayer.js)
- **Responsibility:** Autonomous decision-making for computer opponents
- **Tech:** Heuristic-based AI (no ML)
- **Key files:** ComputerPlayer.js
- **Depends on:** Player.js, Spread.js, rules.js

### UI Layer (src/ui/)
- **Responsibility:** DOM rendering, user input, animations, modals
- **Tech:** Vanilla JS DOM manipulation, CSS animations
- **Key files:** GameUI.js, CardRenderer.js, CardLayoutManager.js
- **Depends on:** Game engine (via event subscription)

### Persistence (src/utils/storage.js)
- **Responsibility:** Read/write stats, settings, themes to localStorage
- **Tech:** localStorage + JSON
- **Key files:** storage.js
- **Depends on:** Nothing

## Data Flow (Critical Path)

1. User clicks/taps card or button — GameUI
2. GameUI calls Game method (draw, discard, laySpread, knock) — Game.js
3. Game validates action against current phase — rules.js
4. Game updates state and emits event — Event system
5. GameUI event handler re-renders affected DOM — CardRenderer

## Data Stores

- **localStorage** — User preferences, statistics, deck theme (3 keys)

## External Integrations

- None (zero runtime dependencies)

## Security Boundaries

- No auth. All state is client-local. No network calls.

## Known Constraints / Trade-offs

- No active game save/load — game resets on page refresh
- AI uses heuristics, not difficulty levels (single behavior profile)
- Spread.js is imported by both game and UI layers (bridge dependency)
