# Findings Register

Severity: **C**ritical / **H**igh / **M**edium / **L**ow.
Each finding: id, dimension, severity, evidence (file:line), impact, recommendation, verification label.

---

## F-001: Known vulnerabilities in the build toolchain (High / Security & Compliance)

**Verification:** VERIFIED

**Evidence:**
- `npm audit` (2026-06-10): 4 vulnerabilities (3 high, 1 moderate) in vite 7.3.0, rollup, picomatch, postcss. Details in `dependencies.md`.
- Three of the vite advisories affect the dev server: arbitrary file read via WebSocket, `server.fs.deny` bypass, path traversal in `.map` handling.

**Impact:** The production bundle is unaffected (zero runtime dependencies), but while `npm run dev` is running, a reachable dev server can leak arbitrary files from the machine. All issues have published fixes.

**Recommendation:**
1. Run `npm audit fix` (stays within the `^7.3.0` range; resolves all 4).
2. Optionally evaluate vite 8.x after confirming local Node version compatibility.
3. Re-run `npm audit` to confirm a clean result.

---

## F-002: No tests, no linting, no CI (High / Operational Readiness)

**Verification:** VERIFIED

**Evidence:**
- `package.json:5-9` defines only `dev`, `build`, `preview` scripts; no test or lint configuration exists anywhere in the repo.
- No `.github/workflows/` directory; no CI of any kind.

**Impact:** Every change is verified by hand, or not at all. The game logic in `src/game/` is pure and DOM-free (by deliberate design, ADR-002), which makes it cheap to unit test; that investment is currently unrealized. Regressions in rules logic (spread validation, scoring, knock/caught resolution) would ship silently. BUG-001 is an example of a gap that a single integration test would have caught.

**Recommendation:**
1. Add Vitest (pairs natively with Vite) and start with `Spread.validate`, scoring, and win-condition tests in `src/game/`.
2. Add ESLint with the recommended ruleset; `no-unused-vars`/import checks would flag the dead modules in F-005.
3. Add a minimal GitHub Actions workflow: install, lint, test, build on push.

---

## F-003: Build artifacts committed to git; .gitignore does not exclude dist/ (Medium / Git Hygiene)

**Verification:** VERIFIED

**Evidence:**
- `dist/index.html`, `dist/assets/index-B37T2itt.js`, `dist/assets/index-Dy_2hu0m.css` are tracked.
- `.gitignore` covers `node_modules/` and `.env*` but not `dist/`.

**Impact:** The committed bundle goes stale the moment source changes, inflates the repo, and creates ambiguity about what is actually deployed. (If GitHub Pages-style deployment from `dist/` is intentional, that intent is undocumented.)

**Recommendation:**
1. Add `dist/` to `.gitignore`.
2. `git rm -r --cached dist/` and commit.
3. If static-host deployment is the goal, deploy via CI (F-002) instead of committing artifacts.

---

## F-004: Statistics and settings persistence implemented but never wired (Medium / Bugs & Stability)

**Verification:** VERIFIED

**Evidence:**
- `src/utils/storage.js:92-179` implements statistics and settings APIs; no call sites exist outside the module (full trace in `bugs.md`, BUG-001).
- `src/ui/GameUI.js:5` imports only the theme functions.

**Impact:** Two of the three documented localStorage features do not function. Project docs (`docs/ai/memory.md`, `CLAUDE.md`) describe statistics tracking and settings persistence as working, so any future contributor (human or AI) will reason from a false premise.

**Recommendation:**
1. Fix per BUG-001 steps 1-3.
2. Correct `docs/ai/memory.md` "What's Working" list.

---

## F-005: Dead modules and unused exports (Low / Code Quality)

**Verification:** VERIFIED

**Evidence:**
- `src/ui/animations.js` (117 lines): imported by no file.
- `src/utils/helpers.js` (89 lines): imported by no file.
- Unused exports in `src/utils/storage.js` (settings/statistics APIs, overlaps F-004).

**Impact:** ~200 lines of maintained-looking but unreachable code. Low direct risk; it misleads readers (the docs list `animations.js` as the animation system, while actual animations live in CSS and GameUI).

**Recommendation:**
1. Decide per module: wire it in or delete it.
2. Add ESLint (F-002) to prevent recurrence.

---

## F-006: Commit history is not a usable change record (Low / Git Hygiene)

**Verification:** VERIFIED

**Evidence:**
- 10 of 12 commit messages are vague or accidental (`more updates`, `i promise this is it`, `I like thisgit add .`). Full table in `git_analysis.md`.
- No tags, no release marking; hygiene scorecard 10/30.

**Impact:** `git log` cannot answer "what changed and when". For a solo project the cost is low today, but it compounds and removes the ability to bisect regressions.

**Recommendation:**
1. Adopt a minimal convention going forward (imperative summary line stating what changed).
2. Tag releases (`v1.0.0` exists in package.json but not in git).

---

## F-007: No LICENSE; repo-root clutter (Low / Operational Readiness)

**Verification:** VERIFIED

**Evidence:**
- No `LICENSE`, `CHANGELOG.md`, or `CONTRIBUTING.md` at root.
- Stray screenshots at root: `image.png`, `not_centered.png`, `two_player_slop.png` (~1 MB).

**Impact:** Without a license, the public repo is all-rights-reserved by default; nobody can legally reuse it. Screenshots at root add repo weight with no referencing documentation.

**Recommendation:**
1. Add a LICENSE (MIT is the conventional choice for a project like this).
2. Move screenshots to `docs/images/` and reference them from README, or delete them.

---

## F-008: No Content Security Policy; broad innerHTML usage (Low / Security & Compliance)

**Verification:** STATIC-ONLY

**Evidence:**
- `index.html` has no CSP meta tag.
- 16 `innerHTML` assignments (`src/ui/GameUI.js`: 12, `src/ui/CardRenderer.js`: 4); all observed inputs are game-controlled strings, not user input.

**Impact:** Low today: the game accepts no user-authored content, so the XSS surface is theoretical. A CSP would be cheap defense-in-depth if the game is published, and matters more if multiplayer/chat is ever added (it is on the roadmap).

**Recommendation:**
1. Add a restrictive CSP meta tag (self-only scripts/styles, plus the Google Fonts origins).
2. Prefer `textContent`/element construction for any future user-influenced strings.

---

## F-009: Documentation drift between docs and code (Low / Code Quality)

**Verification:** VERIFIED

**Evidence:**
- `docs/ai/memory.md:20-21` claims statistics tracking and settings persistence work (contradicted by F-004).
- `docs/ai/tasks.md:37-38` carries stale line counts; theme list in `docs/ai/memory.md:18` ("Classic, Royal, Midnight, Emerald, Crimson") does not match the actual six themes in `index.html` (rosegold, midnight, royal, emerald, crimson, ocean).

**Impact:** The AI-facing doc system is this repo's standout strength, but drift converts it from an asset into a source of false premises for future sessions.

**Recommendation:**
1. Correct `memory.md` (What's Working, theme list) and `tasks.md` (line counts now 1286/702).
2. Treat doc updates as part of the definition of done for feature work.

---

## F-010: God-object UI controller (Medium / Code Quality)

**Verification:** STATIC-ONLY

**Evidence:**
- `src/ui/GameUI.js`: 1,286 lines handling rendering, input, drag-drop, modals, betting UI, AI turn sequencing, and theme application.
- `src/game/Game.js`: 702 lines (state machine plus dealing, betting, scoring).

**Impact:** GameUI is the place where every UI change lands, and it is approaching the size where changes routinely collide. The game layer's separation is clean (a genuine strength); the UI layer has no equivalent decomposition.

**Recommendation:**
1. When next touching UI, extract cohesive units first (betting panel, modal manager, drag-drop handling) rather than refactoring wholesale.
2. Keep `Game.js` as-is until tests exist (F-002); refactoring untested logic inverts the risk/benefit.

---

## Severity Summary

| Severity | Count | IDs |
|---|---|---|
| Critical | 0 | - |
| High | 2 | F-001, F-002 |
| Medium | 3 | F-003, F-004, F-010 |
| Low | 5 | F-005, F-006, F-007, F-008, F-009 |
| Informational | 1 | Secret scan clean (full history, zero hits) |

---
generated_by: codebase-audit skill v1.0
generated_on: 2026-06-10
project: C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk
project_type: node
verification: full
---
