# FEATURE_BOUNDARIES.md

## Game Engine (src/game/Game.js)

Owns:
* Game state machine (phases, turns, round progression)
* Event emission for all state changes
* Player management (creation, turn order)
* Dealing, drawing, discarding
* Spread laying and hitting validation
* Knock/catch mechanics
* Win condition evaluation
* Match scoring (first to 100 loses)
* Betting pot management

Does NOT Own:
* DOM rendering
* User input handling
* AI decision logic (delegates to ComputerPlayer)
* Persistence

Communicates With:
* Deck, Player, ComputerPlayer, Spread, rules (direct calls)
* GameUI (via event emission)

Isolation Level: Strong

---

## Card & Deck (src/game/Card.js, src/game/Deck.js)

Owns:
* Card value calculation
* Deck creation (52 cards)
* Shuffle algorithm
* Draw pile / discard pile management

Does NOT Own:
* Card rendering
* Card selection state

Communicates With:
* Game.js (consumed by)

Isolation Level: Strong

---

## Spread System (src/game/Spread.js)

Owns:
* Book validation (3-4 same rank)
* Run validation (3+ sequential same suit)
* Card addition rules (edge cards for runs, same rank for books)
* Spread point calculation
* Finding possible spreads from a hand

Does NOT Own:
* Deciding when to lay spreads
* Rendering spreads

Communicates With:
* Game.js, Player.js, ComputerPlayer.js, GameUI.js (imported by all)

Isolation Level: Moderate (shared across game and UI layers)

---

## Player (src/game/Player.js)

Owns:
* Hand management (add, remove, sort cards)
* Point calculation for hand
* Chip/betting state per player

Does NOT Own:
* Turn logic (Game owns)
* AI decisions (ComputerPlayer owns)

Communicates With:
* Game.js (managed by)
* Spread.js (for spread detection)

Isolation Level: Strong

---

## AI (src/game/ComputerPlayer.js)

Owns:
* Draw source decision
* Discard selection
* Knock decision
* Spread finding and laying strategy
* Hit opportunity detection
* Betting decisions (call, raise, fold)

Does NOT Own:
* Executing game actions (calls back to Game methods)
* Turn flow control

Communicates With:
* Game.js (called by, calls methods on)
* Player.js (extends)
* Spread.js (analysis)

Isolation Level: Strong

---

## UI Controller (src/ui/GameUI.js)

Owns:
* All DOM updates and rendering
* User input handling (clicks, drags)
* Card selection state
* Modal management (rules, settings, game-over)
* AI turn triggering and animation sequencing
* Betting UI controls
* Theme application

Does NOT Own:
* Game state
* Game rules enforcement
* AI logic
* Data persistence (delegates to storage.js)

Communicates With:
* Game.js (subscribes to events, calls methods)
* CardRenderer, CardLayoutManager (rendering)
* storage.js (read/write settings and stats)
* Spread.js (client-side validation before calling game)

Isolation Level: Moderate (tightly coupled to Game via events)

---

## Rendering (src/ui/CardRenderer.js, CardLayoutManager.js, animations.js)

Owns:
* Card DOM element creation
* Responsive card sizing and overlap
* Animation effects (deal, flip, move, shake, pulse, fade)

Does NOT Own:
* When to render (GameUI decides)
* Game state

Communicates With:
* GameUI.js (called by)

Isolation Level: Strong

---

## Persistence (src/utils/storage.js)

Owns:
* localStorage read/write operations
* Statistics tracking and aggregation
* Settings CRUD
* Theme persistence
* Storage availability detection

Does NOT Own:
* When to save/load (UI decides)
* Data format definitions (uses own defaults)

Communicates With:
* GameUI.js (called by — theme, statistics recording, and statistics display; saveGameState/loadGameState APIs currently uncalled)

Isolation Level: Strong
