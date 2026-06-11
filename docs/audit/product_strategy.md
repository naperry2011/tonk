# Product Strategy & Forward Look

A read of what this project is trying to be, where it is versus where it should be, and what's next. Based on a structural review of the codebase, not on an interview with the owner. Limits acknowledged at the end.

---

## What this project was trying to be

This is a complete, faithful implementation of Tonk (Tunk), a rummy-family card game with a real betting culture, as a single-player browser experience against AI opponents. The evidence reads as a passion project executed with unusual engineering intent:

- The rule set is implemented in full depth, including the parts casual implementations skip: initial Tonk (49-50 points), caught-knocking penalties, hitting opponents' spreads, ante-and-raise betting with chips, and match scoring to 100.
- The architecture decisions (zero dependencies, event-driven game/UI split, pure DOM-free game logic) are choices someone makes when they care about the craft, not just the output.
- The polish surface (six deck themes, mobile-responsive layout, drag-drop hand reordering, ARIA labels) says the intended audience is real players on real devices, not just the developer.
- The roadmap (`docs/ai/roadmap.md`) names multiplayer as the long-term direction.

The wedge, if there is one: Tonk is culturally significant and underserved online. Most rummy implementations online are Gin Rummy; quality browser Tonk with betting is a thin field.

## Where it is vs. where it should be

The game shell is essentially feature-complete for single-player. The gap is not features; it is trust and reach.

Specific gaps that matter:

- **Trust gap (no tests)**: a card game lives or dies on rules correctness. One mis-scored knock and a player who knows Tonk stops trusting it. The pure game layer was designed to be testable and never was. This is the highest-leverage gap in the repo.
- **Feedback loop gap (stats unwired, BUG-001)**: statistics are the single-player retention mechanic - streaks, tonk counts, win rates are why someone plays game 50. The subsystem exists; it is one event handler away from working.
- **Reach gap (not deployed)**: there is no evidence of a live URL. A finished game that is not hosted has zero players. The build is static files; hosting is a one-hour task.
- **Depth gap (one AI profile)**: a single heuristic opponent gets predictable. Difficulty levels are cheap variation on existing heuristics (knock thresholds, draw aggressiveness).

## The order to do things in

**Now (with Horizon 1-2 fixes):** wire statistics (BUG-001), add Vitest over `src/game/`, deploy to a static host with CI. The game becomes trustworthy, sticky, and reachable in the same month.

**Next:** AI difficulty levels and a stats screen. Both build on what exists; neither requires new architecture.

**Later:** game-state save/resume (already on the roadmap; localStorage serialization of `Game` state), sound effects, then the multiplayer question.

**Multiplayer (the big fork):** this is the only roadmap item that breaks ADR-001/ADR-003 (zero deps, no backend). It deserves a deliberate ADR before any code: WebRTC peer-to-peer keeps the no-backend ethos; a thin WebSocket server is simpler but changes the project's nature. Do not drift into it.

## Future enhancements

1. **Hand history / replay**: the event-emitter architecture is naturally an event log; recording it gives replay nearly for free.
2. **PWA install**: manifest tags already exist in `index.html`; full offline PWA is a small step and fits a zero-backend game perfectly.
3. **Tonk rule variants**: house rules vary regionally (50-point spreads, drop penalties); a variants menu would differentiate against any competitor.

## What I'd want to know to sharpen this

- Is this meant for an audience, or is the build itself the point? (Both are valid; they order the roadmap differently.)
- Has anyone other than the developer played it, and what broke?
- Is multiplayer a genuine ambition or a roadmap placeholder?
- Any attachment to the committed `dist/` (e.g., a hosting workflow this audit should not break)?

---
generated_by: codebase-audit skill v1.0
generated_on: 2026-06-10
project: C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk
project_type: node
verification: full
---
