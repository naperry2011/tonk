# Project Memory

Running history of what's been built and current state. Update after major changes.

## Current State

**Status:** Active Development
**Last Updated:** 2026-10-11
**Version:** main (Flutter M0, uncommitted)

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

- Flutter app in `app/` (ADR-004): playable on Android vs 1-3 AI characters with table talk, themes, sound, haptics, raise/call/fold betting, save/resume, and progression (XP, levels, bankroll, unlocks, achievements, daily challenge); 119 passing tests

### Known Issues
- Web: no save/load of active game state (new game each session; `tonk_game_state` API exists in storage.js but is unused). The Dart engine has `Game.toJson/fromJson` for the mobile app.
- Mobile: laying/hitting spreads, drag reorder, match end, stock-empty, the Tonk celebration, sound volume, and haptics were not yet hand-checked on a device (tests cover the logic).
- Rule divergence: the mobile app has folding (passing a raise = fold); the web version does not.

### In Progress
- Flutter mobile app: M0-M3 done; M4 build side done, store submission steps are with the user (store/README.md). See roadmap.md.

## Implementation History

### 2026-10-11 - Flutter M4: Store Readiness (build side)
**What was built:** Display name "Tonk"; app icon drawn in code (gold T card on felt) and generated for Android (adaptive) and iOS via flutter_launcher_icons; native splash via flutter_native_splash; release signing from `android/key.properties` with a debug-key fallback; `store/` kit with a 512 icon, 1024x500 feature graphic, five 1080x1920 RGB screenshots, a privacy policy page, and a release checklist with listing copy. Fixes found while capturing: awaiting `SystemChrome.setPreferredOrientations` stalled startup about 3s (portrait moved to manifest/Info.plist), sound preload no longer blocks `runApp`, the AI loop now hands control back immediately, and seat status lines no longer overlap mid-transition. Release build installed on the user's Samsung S948U: about 0.2s to fully drawn.
**Why:** M4 of the mobile plan. User decisions: keep betting and accept an 18+ rating; keep app ID com.tonk.tonk; host the privacy policy on the user's website; icon drawn in code. Verified Apple's rule: frequent simulated gambling = 18+ (R18+ in Australia even when infrequent).
**Files affected:** app/android/, app/ios/, app/assets/icon/, app/tool/, app/pubspec.yaml, app/lib/main.dart, app/lib/state/game_controller.dart, app/lib/ui/widgets/opponent_seat.dart, store/

### 2026-10-11 - Flutter M3: Progression
**What was built:** `lib/meta/` (pure progression rules; Profile + ProfileController persisted as `tonk_profile`; match setup helpers), `AppServices` wiring, a home dashboard (level/XP bar, bankroll, win streak, daily card, buy-in, refill, forfeit confirm), profile/stats screen, rewards on the round-end panel, level-up and daily-win celebrations, lock badges in settings, and a daily challenge with its own save slot. Engine: `initializeWithPlayers(startingChips:)`. Fixed: a 138px top-bar overflow at 360dp, the daily-bonus snackbar covering the hand, and settings not refreshing locks on level-up. Verified on the Android emulator: daily bonus, daily challenge end to end, buy-in and forfeit, profile stats.
**Why:** M3 of the mobile plan. User decisions: bankroll with buy-ins (play money only), start with some content and unlock the rest by level, daily challenge = same seeded deal for everyone.
**Files affected:** app/lib/meta/, app/lib/app_services.dart, app/lib/main.dart, app/lib/state/game_controller.dart, app/lib/engine/game.dart, app/lib/data/save_store.dart, app/lib/ui/ (home, profile, settings, table, round-end panel), app/test/meta/, app/test/widget_test.dart

### 2026-10-11 - Flutter M2: Swag + Fold Rule
**What was built:** Seven AI characters in `assets/content/characters.json` (Uncle Ray, Aunt Dot, Cousin Dre, Mr. Earl, Keisha, Lil Tre, Grandma Pearl), each with an `AiStyle` and clean, playful table talk picked by `TableTalk` per game event. Opponent seats show character color, emoji, and speech bubbles. Settings screen (3 table themes, 6 deck themes ported from the web CSS, sound/haptics toggles, nickname). Synthesized sound effects (`tool/gen_sfx.mjs`), haptics, deal/discard/spread animations, confetti celebration for Tonk and match wins. Audio mixes with other apps instead of taking focus (found via logcat: each sound was pausing other media). Fold rule: passing a raise = fold (out for the round, can't win the pot, still scores hand points); AIs can raise once per round with a call/fold prompt for the human; `WinCondition.allFolded`. Verified on the Android emulator: characters, talk, themes, settings persistence, AI raise prompt, folding.
**Why:** M2 of the mobile plan. User decisions: playful talk with no cursing; Claude drafts the roster for user review; generated sfx now, music later; styled initials for avatars; passing a raise means folding (without it, passing was always the best play).
**Files affected:** app/assets/, app/tool/, app/lib/content/, app/lib/engine/ (ai_style, computer_player, game, game_event, player, rules), app/lib/state/, app/lib/data/settings_store.dart, app/lib/ui/, app/test/, app/pubspec.yaml

### 2026-10-11 - Flutter M1: Playable Table
**What was built:** `GameController` (ChangeNotifier) driving human actions, paced AI turns via `runAiTurn`, round settlement into `RoundSummary`, and autosave to `tonk_game_state` after every step. Home screen (continue / new match, 1-3 opponents) and table screen (opponent seats with last-move text, stock/discard, spreads with tap-to-hit, status line, Knock/Spread/Discard/Raise, reorderable hand, round-end panel showing all hands). Raise now gets AI call/pass responses (`shouldCall`, unused in the web UI). Player and spread ids now include a per-launch seed so restored saves never collide. Verified on the Android emulator: deal, draw, discard, AI turns, raise, knock/caught, round end, force-kill and resume.
**Why:** Milestone M1 of the mobile plan (ADR-004). Riverpod skipped in favor of the built-in ChangeNotifier since there is one controller.
**Files affected:** app/lib/state/, app/lib/data/, app/lib/ui/, app/lib/main.dart, app/lib/engine/player.dart, app/lib/engine/spread.dart, app/test/state/, app/test/widget_test.dart, app/pubspec.yaml

### 2026-10-11 - Flutter Mobile App M0 + JS Redeal Fix
**What was built:** `app/` Flutter project (Android + iOS). Pure Dart port of src/game/ in `app/lib/engine/`: sealed GameEvent classes and listeners, injectable Random and deck factory, `runAiTurn` (step-by-step port of GameUI.handleAITurn; ComputerPlayer.executeTurn was dead code and was not ported), `settleRound`, full `toJson/fromJson` including match scores. 76 Flutter tests: ports of the JS suites plus AI turn, save/restore, seeded replay, and a 1,000-round AI-vs-AI simulation checking chip and card conservation. Flutter job added to CI. JS bug fixed: an initial-tonk redeal re-collected antes and dropped the first pot (`Game.dealAndCheckInitialTonk(collectAntes)`), with a regression test (61 JS tests).
**Why:** Major update to ship Tonk as a mobile app; decisions in ADR-004 (solo vs AI v1, play-only chips, culture/swag + progression focus).
**Files affected:** app/, .github/workflows/ci.yml, src/game/Game.js, tests/Game.test.js, CLAUDE.md, CODE_MAP.md, docs/ai/

### 2026-06-10 - Audit Horizon 2: Tests, Lint, CI
**What was built:** Vitest with 60 tests over src/game/ (Card, Spread, rules, Player, Deck, Game), ESLint flat config (16 issues found and fixed, including 5 dead imports/vars), GitHub Actions CI (lint + test + build), deleted dead modules animations.js and helpers.js
**Why:** Audit F-002 (no tests/lint/CI was the top operational gap) and F-005 (dead code)
**Files affected:** tests/, eslint.config.js, .github/workflows/ci.yml, package.json, src/game/, src/ui/GameUI.js, src/utils/storage.js

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

- Don't trust emulator startup timing: it showed 5-7s cold start while the real phone showed about 0.2s. Real Dart-side stalls still show up in the timing logs (e.g. the 3s orientation call).
- Play rejects PNGs with an alpha channel for screenshots and the feature graphic; Flutter and adb both produce RGBA, so convert (tool/store does).
- When editing docs from scripts in Git Bash, backticks inside double-quoted `node -e` strings get eaten by command substitution. Use the Edit tool for markdown.

- Dart `List.sort` is not stable and Dart has no object-key ordering quirks like JS `Object.values`; AI tie-breaks can differ slightly from the web version. Rules and outcomes match.
- Rare deals (double initial tonk) can't be reached by seed search in tests; stack the deck via `Game(deckFactory: ...)` instead.
- audioplayers defaults to taking audio focus on Android, which pauses the user's music on every sound; set `AudioContextConfigFocus.mixWithOthers` globally.
- To drive the app on the emulator from scripts, `uiautomator dump` exposes Flutter semantics labels as `content-desc` (set `MSYS_NO_PATHCONV=1` in Git Bash so `/sdcard` paths aren't rewritten).
