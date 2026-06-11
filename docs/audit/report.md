# Tonk Card Game: Codebase Audit Report

**Prepared for:** Nicholas Perry (project owner)
**Prepared by:** codebase-audit skill v1.0 (Claude)
**Date:** 2026-06-10
**Repo:** `C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk` at HEAD `2311420` on branch `main`.

---

## 1. Executive Summary

This is a healthy hobby codebase with deliberate architecture and zero critical findings. The game/UI separation is genuinely well done, the secret scan over full history is clean, the production bundle has zero runtime dependencies, and the build verifies green. The weaknesses are the classic solo-project ones: no tests, no CI, a documented feature that is not actually wired up, and git hygiene that would not survive a second contributor.

Three things matter most this week.

**First, the build toolchain has known vulnerabilities.** `npm audit` reports 4 issues (3 high), including arbitrary file read through the Vite dev server. One command fixes all of them: `npm audit fix`. (F-001)

**Second, the statistics feature does not exist at runtime.** A complete statistics subsystem sits in `storage.js` with zero callers, while the project docs claim it works. One event-handler wiring plus a doc correction closes it. (BUG-001 / F-004)

**Third, nothing guards correctness.** The pure, DOM-free game layer was built to be testable and has zero tests, no linter, and no CI. For a rules-heavy card game, this is the gap that compounds. (F-002)

**The recommended path is: fix the audit's Horizon 1 items this week, then invest in tests before any further feature work.**

The findings register lists **10 items across 6 dimensions, with 0 Critical and 2 High severity findings**. The High findings are both one-sitting fixes to start (audit fix; first test file). On the positive side: clean secret scan, clean build, zero-dependency production bundle, and an unusually strong AI-facing documentation system.

The three-horizon roadmap below sequences the work.

---

## 2. Findings by Dimension

Full evidence and recommendations are in [`findings.md`](findings.md).

### 2.1 Contributor Assessment

- Single developer (two git identities, same person); 12 commits over ~4.5 months.
- Bursty cadence: an intense Dec-Jan sprint, a 3.5-month gap, one docs commit in May.
- Bus factor of 1 is expected for a personal project and is not flagged.

**Assessment.** The work demonstrates strong architectural instincts (the event-driven separation and zero-dependency stance are intentional, documented decisions) paired with low process discipline (commit messages, artifacts in git). The May documentation push (`CODE_MAP.md`, `docs/ai/*`) shows the developer investing in maintainability; the same standard has not yet reached git practice.

### 2.2 Git Hygiene & Workflow (Hygiene scorecard: 10 / 30)

- Commit message quality 0/3: 83% vague or accidental messages (F-006)
- `.gitignore` 1/3: `dist/` build artifacts tracked (F-003)
- No tags, no branching model, no review trail; clean history (no force pushes) is the bright spot
- Full scorecard in [`git_analysis.md`](git_analysis.md)

### 2.3 Code Quality & Architecture (0 High, 2 Medium, 2 Low)

**Strengths:**
- Clean game/UI layering; `src/game/` is DOM-free and event-driven (ADR-002)
- Zero runtime dependencies; 45.5 kB JS bundle
- Comprehensive AI-facing docs (CODE_MAP, DATA_FLOW, docs/ai/) - rare at this project size

**Weaknesses:**
- `GameUI.js` is a 1,286-line god object (F-010)
- ~200 lines of dead modules: `animations.js`, `helpers.js`, unused storage APIs (F-005)
- Documentation drift: docs claim features that are not wired (F-009)

### 2.4 Bugs & Stability (0 P0, 0 P1, 1 P2)

**Verification commands:** `npm install` (exit 0), `npm run build` (exit 0, 352ms), `npm audit`, static traces via grep. No gameplay test harness exists; the full game loop was not exercised (see verification gaps).

**Headline bug:** BUG-001, statistics never recorded despite a complete subsystem and docs claiming otherwise. Details in [`bugs.md`](bugs.md).

### 2.5 Security & Compliance (0 Critical, 1 High, 0 Medium, 1 Low)

- F-001 (High): 4 npm audit vulnerabilities in the build toolchain; dev-server file-read exposure while `npm run dev` is running; all fixable now
- F-008 (Low): no CSP; 16 `innerHTML` sites, all currently game-controlled content
- Secret scan over full git history: clean (gitleaks unavailable; manual pattern sweep ran)
- No PII, no network calls, no auth surface: the app's attack surface is inherently minimal

### 2.6 Operational Readiness (0 Critical, 1 High, 0 Medium, 1 Low)

- F-002 (High): no tests, no linting, no CI
- F-007 (Low): no LICENSE (public repo defaults to all-rights-reserved), stray screenshots at root
- No deployment evidence; `dist/` committed to git suggests manual hosting at some point (F-003)

---

## 3. Three-Horizon Roadmap

### Horizon 1: Stop the Bleeding (this week)

| # | Item | Severity | Finding |
|---|---|---|---|
| H1-1 | `npm audit fix`; confirm clean | High | F-001 |
| H1-2 | Wire `updateStatistics` into the gameOver handler; correct memory.md | Medium | BUG-001 / F-004 / F-009 |
| H1-3 | Add `dist/` to `.gitignore`; `git rm -r --cached dist/` | Medium | F-003 |
| H1-4 | Add LICENSE | Low | F-007 |

### Horizon 2: Stabilize (this month)

| # | Item | Severity |
|---|---|---|
| H2-1 | Vitest + first test suite over `src/game/` (Spread validation, scoring, win conditions) | High (F-002) |
| H2-2 | ESLint; delete or wire dead modules it flags | Low (F-005) |
| H2-3 | GitHub Actions: install, lint, test, build on push | High (F-002) |
| H2-4 | Deploy to a static host from CI | - |

### Horizon 3: Build Forward (this quarter)

| # | Item |
|---|---|
| H3-1 | Stats display surface + AI difficulty levels |
| H3-2 | Game-state save/resume (roadmap item, fits ADR-003 with a deliberate exception) |
| H3-3 | Extract betting panel / modal manager from GameUI when next touched (F-010) |
| H3-4 | Multiplayer decision ADR before any multiplayer code |

---

## 4. Forward Look

This audit focuses on the engineering foundation. For a forward-looking read of what this project is trying to be, where it is versus where it should be, and what's next, see [`product_strategy.md`](product_strategy.md).

The condensed answer to "what comes after the audit fixes":

1. Wire stats and ship to a real URL: the retention mechanic and the audience are both one small step away.
2. Add AI difficulty levels and a stats screen, the cheapest depth the existing architecture supports.
3. Decide multiplayer deliberately (P2P vs thin server) with an ADR, since it is the only roadmap item that breaks the project's zero-backend founding decisions.

---

## Appendices

- [Findings Register](findings.md)
- [Git Analysis](git_analysis.md)
- [Dependency Inventory](dependencies.md)
- [Bug Log](bugs.md)
- [Architecture & Implementation](architecture_and_implementation.md)
- [Product Strategy](product_strategy.md)
- Pre-existing index files at repo root: `CODE_MAP.md`, `ENTRY_POINTS.md`, `DATA_FLOW.md`, `FEATURE_BOUNDARIES.md`, `IMPORT_GRAPH_SUMMARY.md`

---
generated_by: codebase-audit skill v1.0
generated_on: 2026-06-10
project: C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk
project_type: node
verification: full
---
