# Tasks

Active work. Update as items are completed and new work is identified.

## Sprint / Iteration

**Range:** [Not yet defined]
**Goal:** [User to define]

## In Progress

- [None currently]

## Up Next

- [ ] Deploy to a static host from CI — Small — audit H2-4
- [ ] Stats display polish + reset-stats button — Small
- [ ] AI difficulty levels — Medium — audit H3-1
- [ ] Add game state save/load — Medium — audit H3-2

## Blocked

- [None]

## Recently Completed

- [x] Vitest: 60 tests over src/game/ — 2026-06-10
- [x] ESLint flat config; 16 issues fixed; dead modules deleted — 2026-06-10
- [x] GitHub Actions CI (lint, test, build) — 2026-06-10
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
- [ ] Game.js is ~700 lines — tests now exist; refactor when convenient — P3
- [ ] storage.js game-state API (save/load/clear) unused — wire when save/resume lands — P3
- [ ] No linting configured — P2
- [ ] No test coverage — P2
