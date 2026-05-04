# ENTRY_POINTS.md

## Browser Entry

Path: index.html
Responsibility: HTML shell, modal templates, CSS/JS loading
Invokes: src/main.js (ES module)
Depends On: styles/*.css

---

## Application Bootstrap

Path: src/main.js
Responsibility: Creates Game and GameUI instances, wires them together
Invokes: Game constructor, GameUI constructor
Depends On: src/game/Game.js, src/ui/GameUI.js

---

## Dev Server

Path: `npm run dev`
Responsibility: Starts Vite dev server on localhost:5173
Invokes: Vite CLI
Depends On: vite.config.js, package.json

---

## Production Build

Path: `npm run build`
Responsibility: Bundles to dist/
Invokes: Vite build
Depends On: vite.config.js, all src/ and styles/

---

## Debug Access

Path: Browser console (dev mode only)
Responsibility: Exposes window.game and window.ui for inspection
Invokes: N/A
Depends On: src/main.js setting globals
