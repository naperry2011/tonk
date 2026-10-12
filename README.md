# Tonk

The classic Tonk card game, two ways:

- **Mobile app** (`app/`): Flutter for Android and iOS. Solo play against AI characters with personality and table talk, betting with folds, progression, and a daily challenge.
- **Web game** (repo root): the original browser version in vanilla JavaScript.

Both play against computer opponents, offline, with no accounts and no data collected.

## About the Game

Tonk (also known as Tunk) is a fast-paced rummy-style card game. Get rid of all your cards by forming spreads, or have the lowest hand when someone drops.

### Card Values
- **Ace**: 1 point
- **2-10**: Face value
- **J, Q, K**: 10 points each

### Key Rules
- **Spreads**: Books (3-4 cards of the same rank) or runs (3+ sequential cards of the same suit). You can also hit (add to) any spread on the table.
- **Knock / drop**: At the start of your turn, claim the lowest hand. If someone has the same or fewer points, you're caught and they win.
- **Tonk**: Empty your hand and you win the round.
- **Initial Tonk**: Get dealt 49 or 50 points for an automatic win (if two players have it, it's a redeal).
- **Stock runs out**: Lowest hand wins.
- **Match**: Losers add their hand points to their score; first to 100 loses the match.
- **Betting**: Everyone antes each round and the round winner takes the pot. In the mobile app, passing on a raise means folding: you sit out the round and can't win the pot.

## Mobile App (`app/`)

### Features
- 1-3 opponents drawn from 7 characters (Uncle Ray, Aunt Dot, Cousin Dre, Mr. Earl, Keisha, Lil Tre, Grandma Pearl), each with their own play style and clean, playful table talk
- Raise, call, and fold, with AI opponents that raise too
- Chip bankroll that carries between matches (1,000 buy-in, daily bonus, refill if you go broke). Chips are play money only.
- XP and levels that unlock tables, card backs, and tougher opponents
- Daily challenge: the same deal for everyone, every day, with streaks
- 10 achievements and a stats screen
- 3 tables (Card Room, Backyard Cookout, Rooftop) and 6 card backs
- Sound effects, haptics, card animations, and a Tonk celebration
- Saves automatically; pick up any match where you left off

### Run it

Requires the Flutter SDK (3.44+) and an Android emulator or device.

```bash
cd app
flutter pub get
flutter run          # debug build on a connected device or emulator
flutter test         # engine, controller, content, and widget tests
flutter analyze
```

### How it's built
- `app/lib/engine/`: pure Dart game engine (a port of `src/game/`, no Flutter imports)
- `app/lib/state/`: game controller, paced AI turns, table talk
- `app/lib/meta/`: progression, profile, bankroll, daily challenge
- `app/lib/ui/`: screens, widgets, themes, sound and haptics
- `app/assets/content/characters.json`: the AI roster and every line they say (edit freely; tests check it)
- `app/tool/`: scripts that generate the sound effects, app icon, and store art

### Releasing

See [`store/README.md`](store/README.md) for the release checklist: upload key, building the app bundle, Play Console answers, iOS notes, and draft listing copy. Store art and the privacy policy page are in `store/`.

The app contains simulated gambling (betting play chips every round), so expect an 18+ rating on the App Store.

## Web Game (repo root)

### Features
- Play against 1-3 AI opponents
- Six deck themes (Rose Gold, Midnight Gold, Royal Velvet, Emerald Isle, Crimson Club, Ocean Blue)
- Spreads, hits, knocking, betting, and match scoring
- Win/loss statistics saved in the browser
- Mobile-responsive layout with drag-to-reorder hand

### Run it

Requires Node.js (v18 or higher recommended).

```bash
npm install
npm run dev        # dev server at http://localhost:5173
npm test           # Vitest suites in tests/
npm run lint       # ESLint
npm run build      # production build to dist/
npm run preview    # preview the production build
```

`dist/` is static and can be deployed to any static host (Vercel, Netlify, GitHub Pages).

### Project Structure

```
index.html            # Page structure and modals
src/
  main.js             # Entry point
  game/               # Pure game logic (no DOM)
    Game.js           # Game controller and event emitter
    Deck.js, Card.js, Player.js, Spread.js, rules.js
    ComputerPlayer.js # AI decisions
  ui/                 # DOM rendering and input
    GameUI.js, CardRenderer.js, CardLayoutManager.js
  utils/
    storage.js        # localStorage (settings, statistics)
styles/               # main.css, cards.css, layout.css, themes.css
tests/                # Vitest suites over src/game/
```

### How to Play
1. Pick the number of opponents and start the game.
2. On your turn, you can knock, lay spreads, or hit spreads first.
3. Draw from the stock or the discard pile.
4. Lay or hit spreads, then discard to end your turn.
5. Win by emptying your hand, knocking with the lowest hand, or holding the lowest hand when the stock runs out.

## Project Docs

- `CLAUDE.md`: working notes for both codebases
- `docs/ai/`: memory, roadmap, tasks, and architecture decisions (ADRs)
- `CODE_MAP.md` and the other map files: where things live

CI (GitHub Actions) runs the web lint, tests, and build plus the Flutter analyze and tests on every push and pull request to `main`.

## License

MIT
