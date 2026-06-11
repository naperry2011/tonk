# IMPORT_GRAPH_SUMMARY.md

## Core Dependency Nodes

* src/game/rules.js - Imported by: Game.js, Player.js, ComputerPlayer.js, Spread.js, GameUI.js
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
    ├── rules.js
    └── storage.js (no imports; only theme functions imported)
```

## Circular Dependencies

* None detected

## Isolation Characteristics

* Game logic (src/game/) has zero DOM dependencies
* UI layer (src/ui/) imports Spread.js from game layer (read-only validation)
* CardRenderer.js and CardLayoutManager.js are fully self-contained
* storage.js is fully self-contained
* (animations.js and helpers.js were dead modules, deleted 2026-06-10)

## Potential Refactor Risk Areas

* src/ui/GameUI.js (1286 lines - largest file, handles all user interaction)
* src/game/Game.js (702 lines - high coupling to all game modules)
* src/game/Spread.js (shared between game and UI layers - bridge dependency)
