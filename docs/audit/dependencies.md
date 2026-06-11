# Dependency Inventory

Source: `package.json` at `2311420`. Cross-checked with `npm outdated` and `npm audit`.

## Runtime / Tool Versions

- Language: vanilla JavaScript (ES6 modules), browser runtime
- Build tool: Vite ^7.3.0 (requires Node ^20.19.0 || >=22.12.0)
- App version: 1.0.0 (`package.json`; no git tags to match)

## Production Dependencies

| Package | Constraint | Latest | Notes |
|---|---|---|---|
| (none) | - | - | Zero runtime dependencies by design (ADR-001) |

## Dev / Test / Build Dependencies

| Package | Constraint | Used for |
|---|---|---|
| `vite` | `^7.3.0` | Dev server, bundler, production build |

Transitive footprint from the lockfile: ~62 resolved packages (esbuild, rollup, postcss cores plus ~46 platform-specific optional binaries).

## Outdated Status

(From `npm outdated`.)

- `vite 7.3.0 → 7.3.5` available within the current caret range (3 patches behind)
- `vite 8.0.16` available (1 major behind); requires a Node compatibility check before adopting

## Notable Absences

| Missing | Why It Matters |
|---|---|
| Test framework (Vitest/Jest/Playwright) | Game logic in `src/game/` is pure and DOM-free, ideal for unit tests, yet has zero coverage |
| Linter (ESLint) | No automated guard against unused code or common JS errors; unused modules already exist (F-005) |
| Formatter (Prettier) | Style consistency relies on discipline only |
| Error/crash reporting | Acceptable for a hobby project; needed only if the game is published for real users |

## Risk Notes

1. **Caret constraint on the only dependency**: `^7.3.0` is normal practice; the lockfile provides reproducibility. No unpinned (`*`/`latest`) constraints exist.
2. **No pre-1.0 community packages**: the entire tree is mainstream build tooling.
3. **node_modules absent at audit start**: dependencies were installed during verification; build then succeeded (exit 0).

## Vulnerability Posture

(From `npm audit`, 2026-06-10.)

- **4 known vulnerabilities (3 high, 1 moderate)**, all in the dev/build toolchain, all fixable via `npm audit fix`:

| Severity | Package | Issue |
|---|---|---|
| High | vite 7.0.0-7.3.1 | Path traversal in `.map` handling; `server.fs.deny` bypass; arbitrary file read via dev-server WebSocket |
| High | rollup 4.0.0-4.58.0 | Arbitrary file write via path traversal |
| High | picomatch 4.0.0-4.0.3 | POSIX character class injection; ReDoS |
| Moderate | postcss <8.5.10 | XSS via unescaped `</style>` in CSS stringify |

These do not ship in the production bundle (zero runtime deps), but the Vite dev-server issues are exploitable while `npm run dev` is running if the dev server is reachable by other parties. See F-001 in `findings.md`.

---
generated_by: codebase-audit skill v1.0
generated_on: 2026-06-10
project: C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk
project_type: node
verification: full
---
