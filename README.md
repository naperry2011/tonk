# Tonk Card Game

A browser-based implementation of the classic Tonk card game, featuring single-player gameplay against AI opponents.

## About the Game

Tonk (also known as Tunk) is a fast-paced rummy-style card game where the objective is to be the first player to get rid of all your cards by forming spreads (sets and runs) or have the lowest point total when someone drops.

### Card Values
- **Ace**: 1 point
- **2-10**: Face value
- **J, Q, K**: 10 points each

### Key Rules
- **Spreads**: Form books (3-4 cards of same rank) or runs (3+ sequential cards of same suit)
- **Drop**: At the start of your turn, claim lowest points - but if you're wrong, you lose!
- **Initial Tonk**: Start with 49 or 50 points for an automatic win
- **Match Play**: First player to reach 100 points loses the match

## Features

- Play against 1-3 AI opponents
- Multiple deck themes (Classic, Royal, Midnight, Emerald, Crimson)
- Form spreads (books and runs)
- Hit existing spreads
- Drop/knock mechanics
- Match scoring system
- Mobile-responsive design
- Smooth card animations

## Tech Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Build Tool**: Vite
- **No external dependencies** - pure vanilla JS implementation

## Project Structure

```
tonk-game/
├── index.html           # Main HTML
├── src/
│   ├── main.js          # Entry point
│   ├── game/
│   │   ├── Game.js      # Main game controller
│   │   ├── Deck.js      # Deck management
│   │   ├── Card.js      # Card class
│   │   ├── Player.js    # Player class
│   │   ├── ComputerPlayer.js  # AI logic
│   │   ├── Spread.js    # Spread validation
│   │   └── rules.js     # Game rules
│   ├── ui/
│   │   ├── GameUI.js    # UI rendering
│   │   ├── CardRenderer.js
│   │   └── animations.js
│   └── utils/
│       ├── storage.js   # LocalStorage helpers
│       └── helpers.js
└── styles/
    ├── main.css
    ├── cards.css
    ├── layout.css
    └── themes.css
```

## Getting Started

### Prerequisites
- Node.js (v16 or higher recommended)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd tonk-game

# Install dependencies
npm install

# Start development server
npm run dev
```

### Build for Production

```bash
npm run build
```

The built files will be in the `dist/` directory, ready for deployment.

### Preview Production Build

```bash
npm run preview
```

## How to Play

1. **Start**: Select the number of players and click "Start Game"
2. **Your Turn**:
   - At the start, you can form spreads, hit existing spreads, or drop
   - Draw a card from the deck or discard pile
   - Form spreads or hit existing ones
   - Discard a card to end your turn
3. **Winning**:
   - Empty your hand by forming spreads
   - Drop with the lowest points
   - Have the lowest points when the deck runs out

## Deployment

Deploy to any static hosting service:

- **Vercel**: `npm run build` → Deploy `dist/`
- **Netlify**: Drag and drop `dist/` folder
- **GitHub Pages**: Push `dist/` to `gh-pages` branch

## License

MIT
