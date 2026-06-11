# Tasks

Active work. Update as items are completed and new work is identified.

## Sprint / Iteration

**Range:** [Not yet defined]
**Goal:** [User to define]

## In Progress

- [None currently]

## Up Next

- [ ] Set up testing framework (Vitest over src/game/) — Medium — audit H2-1
- [ ] Add ESLint; delete or wire dead modules (animations.js, helpers.js) — Small — audit H2-2
- [ ] GitHub Actions CI (install, lint, test, build) — Small — audit H2-3
- [ ] Add game state save/load — Medium

## Blocked

- [None]

## Recently Completed

- [x] Codebase audit (docs/audit/) — 2026-06-10
- [x] npm audit fix: 4 toolchain vulnerabilities resolved — 2026-06-10
- [x] Statistics wired to gameOver + stats display in settings modal (BUG-001) — 2026-06-10
- [x] dist/ untracked and gitignored; MIT LICENSE added — 2026-06-10
- [x] Initial full game implementation
- [x] AI opponent logic
- [x] Betting system
- [x] Deck themes
- [x] Structural indexing (CODE_MAP, ENTRY_POINTS, DATA_FLOW, IMPORT_GRAPH_SUMMARY, FEATURE_BOUNDARIES)

## Bugs

- [None tracked]

## Tech Debt

- [ ] GameUI.js is ~1,300 lines — extract betting panel / modal manager when next touched — P3
- [ ] Game.js is ~700 lines — leave until tests exist — P3
- [ ] Dead modules: animations.js, helpers.js, storage game-state API — wire or delete — P3
- [ ] No linting configured — P2
- [ ] No test coverage — P2
