# Architecture Decisions

ADR log. Write entries when a decision is hard to reverse, affects multiple components, or future-you will ask "why did we do it this way?"

---

## ADR-001: Vanilla JavaScript with No Framework

**Date:** 2026 (initial build)
**Status:** Accepted

**Context**
Needed a browser-based card game. Frameworks add bundle size and complexity for a self-contained game.

**Decision**
We will use vanilla JavaScript ES6 modules with no runtime dependencies. Vite for dev/build tooling only.

**Consequences**
- **Positive:** Zero dependencies, fast load, full control, no framework lock-in
- **Negative:** Manual DOM management, custom event system needed
- **Neutral:** Slightly more boilerplate than a reactive framework

---

## ADR-002: Event-Driven Game/UI Separation

**Date:** 2026 (initial build)
**Status:** Accepted

**Context**
Game logic needs to be testable and independent of rendering. UI needs to react to state changes.

**Decision**
Game.js is a custom event emitter. GameUI subscribes via `game.on()` and updates the DOM. Game logic has zero DOM imports.

**Consequences**
- **Positive:** Clean separation, game logic is pure and testable, UI is swappable
- **Negative:** Spread.js is shared across both layers (bridge dependency)
- **Neutral:** Event-based debugging requires knowing the event catalog

---

## ADR-003: localStorage for Persistence

**Date:** 2026 (initial build)
**Status:** Accepted

**Context**
Need to persist user preferences, statistics, and deck theme across sessions.

**Decision**
We will use browser localStorage with JSON serialization. No backend, no database.

**Consequences**
- **Positive:** Zero infrastructure, instant read/write, works offline
- **Negative:** Data is browser-local only, no cross-device sync
- **Neutral:** Active game state is not persisted (intentional — new game each session)

---
