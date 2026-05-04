# Project Memory

Running history of what's been built and current state. Update after major changes.

## Current State

**Status:** Active Development
**Last Updated:** 2026-05-03
**Version:** a1ad535 (main)

### What's Working
- Full Tonk card game playable in browser against 1-3 AI opponents
- Spread system (books and runs) with validation, laying, and hitting
- Knock/drop mechanics with caught-knocking penalty
- Initial Tonk detection (49-50 points)
- Match scoring (first to 100 loses)
- Ante-based betting system with chips
- Multiple deck themes (Classic, Royal, Midnight, Emerald, Crimson)
- Mobile-responsive layout with drag-drop card reordering
- Statistics tracking (wins, losses, streaks, tonks, knocks)
- Settings persistence via localStorage

### Known Issues
- No linting or testing framework configured
- No save/load of active game state (new game each session)

### In Progress
- [Nothing currently tracked]

## Implementation History

### Initial Build - Tonk Card Game
**What was built:** Complete browser-based Tonk card game with AI opponents
**Why:** Single-player card game for browser play
**Files affected:** Full project (src/game/, src/ui/, src/utils/, styles/)

## Architecture Evolution

Vanilla JavaScript ES6 modules with Vite as build tool. Zero runtime dependencies. Event-driven architecture: Game.js emits state changes, GameUI.js subscribes and renders. Clean separation between pure game logic (src/game/) and DOM layer (src/ui/). See architecture.md for detail.

## Lessons Learned

- [To be filled as development continues]
