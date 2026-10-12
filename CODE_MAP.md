# CODE_MAP.md

## Game Engine

Category: Service

Primary Files:
* src/game/Game.js - Game controller, state machine, event emitter
* src/game/rules.js - Constants, phases, win conditions, betting config

Supporting Files:
* src/game/Card.js - Card representation, value calculation
* src/game/Deck.js - Deck creation, shuffle, draw/discard piles
* src/game/Spread.js - Spread validation (books/runs), card addition
* src/game/Player.js - Base player, hand management, point calculation

Entry Points:
* Game constructor called from src/main.js

---

## AI System

Category: Service

Primary Files:
* src/game/ComputerPlayer.js - AI decision-making (draw, discard, knock, bet, spread)

Supporting Files:
* src/game/Player.js - Base class
* src/game/Spread.js - Spread analysis for AI decisions
* src/game/rules.js - Thresholds and constants

---

## UI Layer

Category: UI

Primary Files:
* src/ui/GameUI.js - Main UI controller, event subscriptions, input handling, modals
* src/ui/CardRenderer.js - Card DOM element factory (face-up, face-down, spreads)
* src/ui/CardLayoutManager.js - Responsive card sizing via ResizeObserver

Supporting Files:
* index.html - Game structure, modal templates
* styles/main.css - Global styles, CSS variables
* styles/cards.css - Card element styling
* styles/layout.css - Game table layout, opponent areas
* styles/themes.css - Deck theme variations

---

## Persistence

Category: Service

Primary Files:
* src/utils/storage.js - LocalStorage wrapper for stats, settings, themes

External Integrations:
* Browser localStorage

localStorage Keys:
* tonk_settings (includes deckTheme)
* tonk_statistics
* tonk_game_state (reserved, unused)

---

## Tests

Category: Other

Primary Files:
* tests/Card.test.js, tests/Spread.test.js, tests/rules.test.js, tests/Player.test.js, tests/Deck.test.js, tests/Game.test.js - Vitest suites over src/game/

---

## Mobile App (Flutter)

Category: Service + UI

Primary Files:
* app/lib/engine/game.dart - Dart port of Game.js: state machine, listeners, betting, settleRound, toJson/fromJson
* app/lib/engine/ai_turn.dart - runAiTurn: step-by-step AI turn (port of GameUI.handleAITurn)
* app/lib/engine/computer_player.dart - Dart port of ComputerPlayer.js (injectable Random)

Supporting Files:
* app/lib/engine/card.dart, deck.dart, spread.dart, player.dart, rules.dart - Ports of the matching src/game/ files
* app/lib/engine/game_event.dart - Sealed GameEvent classes (same catalog as the JS events)
* app/lib/engine/engine.dart - Barrel export
* app/lib/main.dart - App entry point (portrait lock, TonkApp with an injected GameController)
* app/lib/state/game_controller.dart - Match driver for the UI: human actions, paced AI turns, RoundSummary, autosave
* app/lib/data/save_store.dart - SaveStore (shared_preferences, tonk_game_state) and MemorySaveStore
* app/lib/ui/screens/home_screen.dart, table_screen.dart - Home (continue/new match) and the game table
* app/lib/ui/screens/settings_screen.dart - Table theme, card backs, sound/haptics toggles, nickname
* app/lib/ui/widgets/ - playing_card (+ DealIn), opponent_seat (speech bubble), hand_view, round_end_panel, celebration
* app/lib/ui/theme.dart - TonkColors, theme, felt background
* app/lib/ui/themes.dart - DeckTheme (6, from styles/themes.css), TableTheme (Card Room, Backyard Cookout, Rooftop)
* app/lib/ui/table_feel.dart - Sound effects and haptics driven by GameController.events
* app/lib/content/roster.dart - Character, Roster, TalkKey; loads assets/content/characters.json
* app/lib/state/table_talk.dart - Picks AI lines per game event, with cooldown
* app/lib/engine/ai_style.dart - AiStyle play-style knobs per ComputerPlayer
* app/lib/data/settings_store.dart - SettingsController (tonk_settings)
* app/assets/content/characters.json - AI roster and table talk (editable content)
* app/assets/sfx/ - Generated sound effects; app/tool/gen_sfx.mjs regenerates them
* app/test/engine/ - Ported engine tests plus AI turn, save/restore, and 1,000-round simulation tests
* app/test/state/ - GameController tests (full matches, raise/call/fold, AI raise prompt, resume)
* app/test/content/ - Roster validation (clean talk, known keys, sane styles) and TableTalk tests
* app/test/engine/fold_test.dart - Fold rule and AI call/fold decisions
* app/lib/app_services.dart - AppServices bundle passed to screens; connects tables to the profile
* app/lib/meta/progression.dart - XP rules, level curve, unlock track, achievements (pure)
* app/lib/meta/profile.dart - Profile + Stats data, dayKey, dailySeed
* app/lib/meta/profile_controller.dart - ProfileController (tonk_profile): bankroll, buy-in, cash-out, refill, daily bonus/streak, applyRound -> RoundRewards
* app/lib/meta/match_setup.dart - startMatch, unlockedCharacters, dailyOpponents, connectProfile
* app/lib/ui/screens/profile_screen.dart - Level, stats grid, achievements, unlock track
* app/test/meta/progression_test.dart - Levels, XP, unlocks, profile economy, daily streak, table wiring
* app/tool/icon/icon_painter.dart, render_icon_test.dart - App icon drawn in code, rendered to app/assets/icon/
* app/tool/store/render_store_assets_test.dart - Play icon, feature graphic, RGB screenshot conversion (writes to store/)
* app/android/app/build.gradle.kts - Release signing from android/key.properties (debug-key fallback)
* store/ - Release kit: README.md (checklist + listing copy), privacy-policy.html, icon-512.png, feature-graphic.png, screenshots/
* app/pubspec.yaml, app/analysis_options.yaml - Flutter project config
* app/android/, app/ios/ - Platform projects (generated by flutter create)

Entry Points:
* main() in app/lib/main.dart

---

## Build System

Category: Infra

Primary Files:
* vite.config.js - Vite configuration
* eslint.config.js - ESLint flat config
* package.json - Project metadata, scripts (dev, build, preview, test, lint)
* .github/workflows/ci.yml - CI: web job (install, lint, test, build) and flutter job (pub get, analyze, test)

External Integrations:
* Vite, Vitest, ESLint (dev dependencies only)
* Flutter SDK 3.44.2 (subosito/flutter-action in CI)
* GitHub Actions
