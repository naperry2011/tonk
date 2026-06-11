# Git Analysis

Repo at HEAD `2311420` on branch `main`.

## Top-Level Stats

| Metric | Value |
|---|---|
| Total commits (all branches) | 12 |
| Branches | main (local), origin/main |
| Tags | none |
| Merge commits | 0 |
| First commit | 2025-12-26 |
| Last commit | 2026-05-03 |
| Active span | ~4.5 months (active development Dec 26 to Jan 21, then one docs commit in May) |

## Contributors

| Name | Email | Commits | First | Last |
|---|---|---|---|---|
| Perry | nuperry2011@gmail.com | 11 | 2025-12-26 | 2026-01-21 |
| Nicholas Perry | 122832986+naperry2011@users.noreply.github.com | 1 | 2026-05-03 | 2026-05-03 |

Both identities are the same individual (personal email plus GitHub noreply address). This is a single-developer project; bus factor is 1, which is expected and acceptable for a personal project.

## Commit Cadence

Monthly commit volume:

| Month | Commits |
|---|---|
| 2025-12 | 4 |
| 2026-01 | 7 |
| 2026-05 | 1 |

Top single-day commit counts:

| Day | Commits | Note |
|---|---|---|
| 2026-01-12 | 4 | Peak feature day |
| 2026-01-11 | 2 | |
| 2025-12-27 | 2 | Early build sprint |

Pattern: an intense initial sprint (Dec 26 to Jan 21), a 3.5-month gap, then a documentation commit via PR #1 in May. Bursty, hobby-paced cadence.

## Commit Size Distribution

Total churn: **4,744 insertions and 1,160 deletions** (net +3,584 lines) across 35 files.

Largest single commit: the 2026-01-21 refactor (~2,002 insertions, ~2,937 deletions). Most other commits are large feature drops; small focused commits are rare.

## Commit Message Quality

**High quality samples:**
- `Initial commit - Tonk Card Game`
- `add docs and map files (#1)`

**Low quality samples:**
- `more updates`, `more changes`, `more features`, `major changes`
- `last change of the day`, `last for the day`, `i promise this is it`
- `I like thisgit add .` (accidental paste of the staging command into the message)

Classification: 2 of 12 descriptive (17%), 10 of 12 poor (83%). Messages do not describe what changed; `git log` is not usable as a change history.

## Branching & Workflow

- Branch model: single-main, linear history
- Merge strategy: none used (0 merge commits; PR #1 landed without a merge commit)
- Tags: none, no release marking
- Force-push evidence: none detected

## Hygiene Scorecard

Each item rated 0 (absent/broken) to 3 (excellent).

| Area | Score | Note |
|---|---|---|
| Branching model | 1 | Single main, fine for solo, but no feature isolation |
| Commit cadence | 1 | Bursty with multi-month gaps |
| Commit message quality | 0 | 83% vague or accidental messages |
| PR usage | 1 | One PR (#1), used for docs only |
| Code review | 0 | No evidence of review (solo project) |
| Merge strategy | 1 | Linear, consistent by default |
| Tag usage | 0 | No tags or releases |
| `.gitignore` hygiene | 1 | Covers node_modules and .env, but `dist/` is tracked (F-003) |
| Repo size / large files | 2 | 2.85 MiB pack; ~1 MB screenshot PNGs and dist/ artifacts committed |
| History rewrites | 3 | Clean, no force pushes |

**Total: 10 / 30.**

## Red Flags

1. `dist/` build artifacts are tracked in git and `.gitignore` does not exclude them (see F-003 in `findings.md`).
2. Commit messages are not a usable change record; the May docs commit shows the standard is improvable.
3. Screenshot PNGs (`two_player_slop.png` ~1 MB, `image.png`, `not_centered.png`) are committed at the repo root with no clear purpose.

## Documentation Hygiene

- `README.md`: present and comprehensive (features, rules, tech stack, structure)
- `CONTRIBUTING.md`: missing
- `CHANGELOG.md`: missing
- `LICENSE`: missing
- AI-facing docs: present and unusually strong (`CLAUDE.md`, `CODE_MAP.md`, `ENTRY_POINTS.md`, `DATA_FLOW.md`, `IMPORT_GRAPH_SUMMARY.md`, `FEATURE_BOUNDARIES.md`, `docs/ai/*`, `llms.txt`)

---
generated_by: codebase-audit skill v1.0
generated_on: 2026-06-10
project: C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk
project_type: node
verification: full
---
