# Project Memory

Running history of what's been built and current state. Update after major changes.

## Current State

**Status:** Active Development
**Last Updated:** 2026-06-10
**Version:** main (post-audit fixes, uncommitted)

### What's Working
- Full Tonk card game playable in browser against 1-3 AI opponents
- Spread system (books and runs) with validation, laying, and hitting
- Knock/drop mechanics with caught-knocking penalty
- Initial Tonk detection (49-50 points)
- Match scoring (first to 100 loses)
- Ante-based betting system with chips
- Six deck themes (Rose Gold, Midnight, Royal, Emerald, Crimson, Ocean)
- Mobile-responsive layout with drag-drop card reordering
- Statistics tracking (wins, losses, streaks, tonks, knocks) recorded per round and shown in the settings modal (wired 2026-06-10)
- Theme persistence via localStorage (stored in `tonk_settings.deckTheme`; other settings fields have defaults but no UI yet)

### Known Issues
- No linting or testing framework configured
- No save/load of active game state (new game each session; `tonk_game_state` API exists in storage.js but is unused)
- `src/ui/animations.js` and `src/utils/helpers.js` are dead modules (never imported)

### In Progress
- Working through codebase audit findings (see docs/audit/report.md)

## Implementation History

### 2026-06-10 - Codebase Audit + Horizon 1 Fixes
**What was built:** Full engineering audit (docs/audit/), then fixes: npm audit clean (was 4 vulns), statistics wired into gameOver and displayed in settings modal, dist/ untracked and gitignored, MIT LICENSE added, doc drift corrected (localStorage keys, theme list)
**Why:** Audit found statistics subsystem complete but never called (BUG-001), plus toolchain CVEs and hygiene gaps
**Files affected:** src/ui/GameUI.js, index.html, styles/themes.css, .gitignore, LICENSE, CLAUDE.md, root map docs

### Initial Build - Tonk Card Game
**What was built:** Complete browser-based Tonk card game with AI opponents
**Why:** Single-player card game for browser play
**Files affected:** Full project (src/game/, src/ui/, src/utils/, styles/)

## Architecture Evolution

Vanilla JavaScript ES6 modules with Vite as build tool. Zero runtime dependencies. Event-driven architecture: Game.js emits state changes, GameUI.js subscribes and renders. Clean separation between pure game logic (src/game/) and DOM layer (src/ui/). See architecture.md for detail.

## Lessons Learned

- [To be filled as development continues]
