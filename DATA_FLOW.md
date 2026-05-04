# DATA_FLOW.md

## Game State Flow

Source: User interaction (click/drag) in GameUI
Transport: Direct method calls
Processor: Game.js (state machine)
Storage: In-memory game state
Downstream Consumers: GameUI (via event callbacks)

---

## Event-Driven Rendering

Source: Game.js state changes
Transport: Custom event emitter (game.emit → game.on)
Processor: GameUI event handlers
Storage: DOM
Downstream Consumers: Browser rendering engine

Key Events:
* gameInitialized → full UI setup
* turnStart → enable/disable controls
* cardDrawn → re-render hand
* cardDiscarded → re-render hand, discard pile
* spreadLaid → render spread area
* spreadHit → update spread display
* knock → trigger scoring
* gameOver → show modal, update stats

---

## AI Turn Flow

Source: GameUI triggers AI turn
Transport: Direct method calls
Processor: ComputerPlayer.executeTurn()
Storage: Game state (in-memory)
Downstream Consumers: Game.js emits events → GameUI renders

---

## Statistics Persistence

Source: Game.js gameOver event
Transport: GameUI handler calls storage functions
Processor: storage.js updateStatistics()
Storage: localStorage (tonk_statistics)
Downstream Consumers: Stats display in UI

---

## Settings Persistence

Source: User changes in settings modal
Transport: GameUI handler calls storage functions
Processor: storage.js saveSettings()
Storage: localStorage (tonk_settings)
Downstream Consumers: GameUI reads on init

---

## Theme Persistence

Source: User selects deck theme
Transport: GameUI handler
Processor: storage.js saveDeckTheme()
Storage: localStorage (tonk_deck_theme)
Downstream Consumers: CardRenderer applies CSS classes
