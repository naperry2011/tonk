# Tasks

Active work. Update as items are completed and new work is identified.

## Sprint / Iteration

**Range:** Flutter M4
**Goal:** Store readiness: icon, splash, privacy policy, release build, store policy check

## In Progress

- [None currently]

## Up Next

- [ ] User review of characters.json (names, lines, styles) - Small
- [ ] Manually verify on device: lay spread, hit spread, drag reorder, match end, stock empty, Tonk celebration, sound volume, haptics on a phone - Small
- [ ] Background music: pick or commission a track, add a music toggle - Small
- [ ] Tune economy and XP numbers after real play (progression.dart, profile_controller.dart) - Small
- [ ] User: replace [CONTACT EMAIL] in store/privacy-policy.html and host it on the website - Small
- [ ] User: create the upload key and android/key.properties (store/README.md step 1) - Small
- [ ] User: Play Console app, content rating (simulated gambling), data safety (none), 18+ audience, closed test (12 testers / 14 days for new personal accounts; confirm) - Medium
- [ ] Retake the profile screenshot once real stats exist - Small
- [ ] iOS on the Mac: archive, age rating 18+, test portrait lock, sounds, haptics - Medium

- [ ] Deploy to a static host from CI — Small — audit H2-4
- [ ] Stats display polish + reset-stats button — Small
- [ ] AI difficulty levels — Medium — audit H3-1
- [ ] Add game state save/load — Medium — audit H3-2

## Blocked

- [None]

## Recently Completed

- [x] Flutter M4 (Android build side): app name, icon, splash, release signing config, store art and screenshots, privacy policy page, release checklist; startup stall and AI-turn lag fixes; release build verified on the Samsung (about 0.2s cold start) - 2026-10-11

- [x] Flutter M3: XP/levels, bankroll with buy-ins, daily bonus and refill, unlock track, 10 achievements, profile/stats screen, daily challenge; 360dp overflow fixes; verified on Android emulator - 2026-10-11
- [x] Flutter M2: 7 AI characters with play styles and table talk, table/deck themes, settings, sfx + haptics, animations, Tonk celebration, AI raises with call/fold (fold rule); verified on Android emulator - 2026-10-11
- [x] Flutter M1: playable table, AI turns, raise/call, round end, save/resume; verified on Android emulator - 2026-10-11
- [x] Flutter M0: app/ scaffold, Dart engine port, 76 tests, Flutter CI job - 2026-10-11
- [x] JS fix: initial-tonk redeal re-collected antes (regression test added) - 2026-10-11

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
- [ ] Two engines (src/game/ JS and app/lib/engine/ Dart) must stay in sync on rule changes - P2
