# IMPORT_GRAPH_SUMMARY.md

## Core Dependency Nodes

* src/game/rules.js - Imported by: Game.js, Player.js, ComputerPlayer.js, Spread.js
* src/game/Spread.js - Imported by: Game.js, Player.js, ComputerPlayer.js, GameUI.js
* src/game/Player.js - Imported by: Game.js, ComputerPlayer.js
* src/game/Card.js - Imported by: Deck.js, Spread.js
* src/game/Game.js - Imported by: main.js (root dependency)
* src/ui/GameUI.js - Imported by: main.js (root dependency)

## Import Tree

```
main.js
├── Game.js
│   ├── Deck.js → Card.js
│   ├── Player.js → Spread.js → Card.js, rules.js
│   ├── ComputerPlayer.js → Player.js, Spread.js, rules.js
│   ├── Spread.js
│   └── rules.js
└── GameUI.js
    ├── CardRenderer.js (no imports)
    ├── CardLayoutManager.js (no imports)
    ├── Spread.js
    └── storage.js (no imports)
```

## Circular Dependencies

* None detected

## Isolation Characteristics

* Game logic (src/game/) has zero DOM dependencies
* UI layer (src/ui/) imports Spread.js from game layer (read-only validation)
* CardRenderer.js, CardLayoutManager.js, animations.js are fully self-contained
* storage.js is fully self-contained
* helpers.js is fully self-contained (not imported by any src file directly)

## Potential Refactor Risk Areas

* src/game/Game.js (703 lines - largest file, high coupling to all game modules)
* src/ui/GameUI.js (500+ lines - largest UI file, handles all user interaction)
* src/game/Spread.js (shared between game and UI layers - bridge dependency)
