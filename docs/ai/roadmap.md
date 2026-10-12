# Roadmap

Forward-looking direction. Pair with tasks.md (active work) and memory.md (history).

## Vision

Tonk as a hype mobile card game on Android and iOS: solo play against AI characters with personality and trash talk, a cookout / card-night look, and progression that keeps players coming back. The web version stays live alongside it. See ADR-004.

## Current Focus

**Theme:** Flutter mobile app v1 (solo vs AI, offline, no backend)
**Goals:**
1. Playable, polished table on Android (M1)
2. Culture/swag and progression features that make it feel hype (M2, M3)
3. Store-ready builds (M4)

## Now

- **M4: Store readiness.** Done on the build side (icon, splash, signing config, store art, privacy policy, checklist in store/README.md). Remaining, user-owned: upload key, hosting the privacy policy, Play Console setup and closed test, iOS archive on the Mac. Ratings: simulated gambling means 18+ on iOS.

## Next

- Background music (track to be chosen; sfx and toggles already exist).

## Later

- **v2: Online multiplayer** (backend such as Supabase or Firebase realtime, friends, private tables). Needs its own ADR.
- Cosmetic in-app purchases (never chips for real money).
- Web: deploy to a static host from CI.

## Recently Completed

- M3: progression (XP, levels, bankroll and buy-ins, unlocks, achievements, daily challenge, profile screen), 119 tests (2026-10-11)
- M2: swag (7 characters with table talk, themes, sfx, haptics, animations, celebration) and the fold rule with AI raises, 105 tests (2026-10-11)
- M1: playable table on Android (controller, AI pacing, raise/call, round end panel, save/resume), 81 tests (2026-10-11)
- M0: Flutter scaffold in `app/`, pure Dart engine port, 76 tests (JS parity plus AI turn, save/restore, 1,000-round simulation), Flutter CI job (2026-10-11)
- JS fix: initial-tonk redeal no longer re-collects antes (2026-10-11)
- Tests, lint, CI for the web version (2026-06-10)
- Core game engine with full Tonk rules, AI, betting, deck themes, mobile-responsive web UI, statistics

## Deferred / Cancelled

- [None yet]
