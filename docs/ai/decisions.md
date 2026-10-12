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

## ADR-004: Flutter Mobile App Alongside the Web Version

**Date:** 2026-10-11
**Status:** Accepted

**Context**
Tonk should ship as a mobile app on Android and iOS with a premium, "hype" feel (animations, haptics, sound, AI characters, progression). The web version is complete and working.

**Decision**
We will build a Flutter app in `app/` inside this repo. The game engine is ported 1:1 to pure Dart (`app/lib/engine/`), with the JS tests as the spec. The web version stays and keeps shipping. v1 is solo vs AI, offline, with no backend. Chips are play-only currency and are never sold for real money; cosmetic in-app purchases may come later. Online multiplayer is v2 and needs its own ADR. Android is developed and tested on the Windows PC; iOS on a Mac.

**Consequences**
- **Positive:** One codebase for Android and iOS; the pure Dart engine is testable and can later be reused for server-validated multiplayer; the web version is not at risk.
- **Negative:** Two engines (JS and Dart) to keep in sync on rule changes; iOS builds require macOS.
- **Neutral:** ADR-001 (no framework) and ADR-003 (localStorage) still apply to the web version only.

---

## ADR-005: Passing a Raise Means Folding (Mobile App)

**Date:** 2026-10-11
**Status:** Accepted

**Context**
With raises in the mobile app, a player who "passed" paid nothing and could still win the whole pot, so passing was always the best play and raising meant nothing. The web version has the same gap but its AI never responds to raises.

**Decision**
In the mobile app, passing on a raise means folding: the player sits out the rest of the round, can't win the round or the pot, and still takes their hand points at round end. If everyone else folds, the last player in wins (`WinCondition.allFolded`). The human may raise once per turn; each AI may raise once per round at the start of its turn.

**Consequences**
- **Positive:** Raises carry real pressure; AI personalities show up in betting (Aunt Dot never folds, Mr. Earl folds easily).
- **Negative:** The mobile and web rules now differ; the web version does not implement folding.
- **Neutral:** Fold state is saved with the match, including an unanswered call/fold prompt.

---
