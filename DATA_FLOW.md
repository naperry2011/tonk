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
* roundStart / cardsDealt → deal animation, hand render
* turnStart / turnEnd → enable/disable controls
* phaseChanged → control state updates
* cardDrawn → re-render hand
* cardDiscarded → re-render hand, discard pile
* spreadLaid → render spread area
* spreadHit → update spread display
* knock / initialTonkDraw → trigger scoring
* gameOver → show modal
* antesCollected / betPlaced / potAwarded → betting UI updates

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
Transport: GameUI.showGameOver() calls updateStatistics()
Processor: storage.js updateStatistics()
Storage: localStorage (tonk_statistics)
Downstream Consumers: Stats display in settings modal (GameUI.renderStatistics())

---

## Settings Persistence (theme only)

Source: User selects deck theme in settings modal
Transport: GameUI calls saveDeckTheme() → updateSetting() → saveSettings()
Storage: localStorage (tonk_settings, deckTheme field)
Downstream Consumers: GameUI.initializeTheme() on load
Note: other settings fields (sound, difficulty, hints) have defaults in storage.js but no UI

---

## Theme Persistence

Source: User selects deck theme
Transport: GameUI handler
Processor: storage.js saveDeckTheme() (stores into tonk_settings)
Storage: localStorage (tonk_settings)
Downstream Consumers: CardRenderer applies CSS classes
