# Bug Log

Reproducible defects identified by code review and verification.

Severity: P0 = ship-blocker / unsafe; P1 = major user-visible bug; P2 = quality issue; P3 = minor.

Note: gameplay was not exercised end-to-end in this audit pass (no test harness exists). The build was verified (exit 0) and the codebase was reviewed statically. Only one defect met the bar for this log; everything else is registered as findings in `findings.md`.

---

## BUG-001: Statistics are never recorded despite a complete statistics subsystem (P2)

**File:** `src/utils/storage.js:92-150` (subsystem), `src/ui/GameUI.js:1-5` (imports)

```js
// src/ui/GameUI.js - the only storage functions the UI ever imports:
import { loadDeckTheme, saveDeckTheme } from '../utils/storage.js';
```

**Reproduction (VERIFIED via static trace):**

```
$ grep -rn "updateStatistics\|loadStatistics" src/ --include=*.js
src/utils/storage.js:92:export function loadStatistics() {
src/utils/storage.js:106:export function updateStatistics(won, condition, points) {
src/utils/storage.js:107:  const stats = loadStatistics();
```

`storage.js` implements a full statistics API (`loadStatistics`, `updateStatistics` covering wins, losses, streaks, tonks, knocks, writing to the `tonk_statistics` localStorage key), but no file outside `storage.js` calls it. The `gameOver` event handler in GameUI does not invoke it, and no UI surface displays statistics. The project documentation (`docs/ai/memory.md` "What's Working", `CLAUDE.md` localStorage keys) describes statistics tracking as a working feature; in the running game, `tonk_statistics` is never written.

The same pattern applies to `saveSettings`/`loadSettings` (the `tonk_settings` key): implemented, exported, never called. The Settings modal in `index.html:162` only contains the deck-theme picker, which uses the separate (and correctly wired) `tonk_deck_theme` path.

**Verification:** VERIFIED (static trace; the absence of any call site is conclusive)

**Fix:**
1. Wire `updateStatistics(won, condition, points)` into the `gameOver` event handler in `src/ui/GameUI.js`.
2. Add a statistics display surface (e.g., a section in the settings modal or game-over modal) backed by `loadStatistics()`.
3. Either wire `saveSettings`/`loadSettings` to real settings (e.g., the `animationsEnabled` default at `src/utils/storage.js:152`) or remove the dead API.
4. Update `docs/ai/memory.md` to reflect actual state until fixed.

---
generated_by: codebase-audit skill v1.0
generated_on: 2026-06-10
project: C:\Users\Perry\Dropbox\PC\Documents\GitHub\tonk
project_type: node
verification: full
---
