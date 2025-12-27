# Tonk Card Game - Prototype Specification

## Project Overview
Build a browser-based Tonk card game where players compete against computer opponents. This is a prototype/MVP focused on single-player gameplay with AI competitors.

## Game Rules - Tonk

### Objective
Be the first player to get rid of all cards by forming spreads (sets/runs) or have the lowest point total when someone knocks.

### Card Values
- Face cards (J, Q, K): 10 points each
- Aces: 1 point
- Number cards: Face value (2-10)

### Setup
- 2-4 players (for prototype: 1 human + 1-3 computer players)
- Standard 52-card deck
- Each player dealt 5 cards (or 7 cards for 2-player games)
- Remaining cards form the draw pile
- Top card flipped to start discard pile

### Gameplay Flow
1. **Initial Tonk Check**: After dealing, if any player's hand totals exactly 50 points, they immediately win
2. **Turn Structure**:
   - Draw a card (from draw pile or discard pile)
   - Optionally lay down spreads or add to existing spreads
   - Discard one card
3. **Valid Spreads**:
   - **Book/Set**: 3+ cards of same rank (e.g., 7♠ 7♥ 7♦)
   - **Run**: 3+ cards in sequence of same suit (e.g., 4♠ 5♠ 6♠)
4. **Winning Conditions**:
   - **Tonk**: Play all cards from hand
   - **Knock/Drop**: At start of turn, knock if hand totals ≤5 points
   - If someone knocks, all players reveal hands - lowest total wins

### Special Rules
- Can only knock at the START of your turn (before drawing)
- Must have ≤5 points to knock
- Can add cards to other players' spreads (called "hitting")
- If draw pile exhausted, reshuffle discard pile

---

## Technical Stack

### Recommended: Vite + Vanilla JavaScript
**Why**: Fast setup, no framework overhead, perfect for prototype, simple deployment

```bash
npm create vite@latest tonk-game -- --template vanilla
```

### Core Technologies
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **State Management**: JavaScript classes/objects
- **Storage**: LocalStorage for game state persistence
- **Animations**: CSS transitions + optional GSAP for card movements
- **AI Logic**: Rule-based decision trees (no ML needed for prototype)

### Alternative Stack (if you want more structure)
- **SvelteKit**: Better for scaling to multiplayer later
- **Astro + Vanilla JS islands**: If you want static pages + interactive game

---

## Core Features (MVP)

### Essential Features
1. ✅ Game initialization and card dealing
2. ✅ Player turn management
3. ✅ Draw from deck or discard pile
4. ✅ Form and display spreads (books and runs)
5. ✅ Discard cards
6. ✅ Computer AI opponents (basic strategy)
7. ✅ Knock/Drop functionality
8. ✅ Score calculation and winner determination
9. ✅ Game restart

### Nice-to-Have Features
- Card animations (deal, draw, discard, spread placement)
- Sound effects (optional)
- Game history/statistics
- Multiple difficulty levels for AI
- Persistent game state (resume games)
- Mobile-responsive design

---

## UI/UX Requirements

### Layout Structure
```
┌─────────────────────────────────────────────┐
│           TONK - Card Game                  │
├─────────────────────────────────────────────┤
│                                             │
│     [Computer Hand - Face Down]             │
│     Cards: 5  |  Points: ??                 │
│                                             │
│  ┌───────────────────────────┐             │
│  │   Spreads Area (Center)   │             │
│  │   [Displayed Sets/Runs]   │             │
│  └───────────────────────────┘             │
│                                             │
│  [Deck] [Discard: 7♥]                      │
│                                             │
│     [Your Hand]                             │
│     🂡 🂢 🂣 🂤 🂥                           │
│     Cards: 5  |  Points: 23                 │
│                                             │
│  [Form Spread] [Knock] [End Turn]          │
└─────────────────────────────────────────────┘
```

### Visual Design
- **Card Design**: Use Unicode playing card characters or CSS-based cards
- **Color Scheme**: 
  - Green felt background (#0B6E4F or #2D6A4F)
  - White/cream cards
  - Red/black for suits
- **Responsive**: Desktop-first, mobile-friendly
- **Animations**: Smooth card movements (300-500ms transitions)

### Card Rendering Options

**Option 1: Unicode Characters** (Fastest for prototype)
```
🂡 🂢 🂣 🂤 🂥 🂦 🂧 🂨 🂩 🂪 🂫 🂬 🂭 🂮
```

**Option 2: CSS Cards** (Better visual control)
```html
<div class="card">
  <span class="rank">7</span>
  <span class="suit">♥</span>
</div>
```

**Option 3: SVG/Images** (Most polished, use if time permits)

---

## Game Logic Architecture

### File Structure
```
tonk-game/
├── index.html
├── src/
│   ├── main.js                 # Game initialization
│   ├── game/
│   │   ├── Game.js            # Main game controller
│   │   ├── Deck.js            # Deck management
│   │   ├── Card.js            # Card class
│   │   ├── Player.js          # Player class
│   │   ├── ComputerPlayer.js  # AI logic
│   │   ├── Spread.js          # Spread validation/management
│   │   └── rules.js           # Game rules and validation
│   ├── ui/
│   │   ├── GameUI.js          # UI rendering
│   │   ├── CardRenderer.js    # Card display
│   │   └── animations.js      # Card animations
│   └── utils/
│       ├── storage.js         # LocalStorage helpers
│       └── helpers.js         # Utility functions
├── styles/
│   ├── main.css
│   ├── cards.css
│   └── layout.css
└── assets/
    └── sounds/ (optional)
```

### Core Classes

#### Card Class
```javascript
class Card {
  constructor(suit, rank) {
    this.suit = suit;  // ♠ ♥ ♦ ♣
    this.rank = rank;  // A, 2-10, J, Q, K
    this.value = this.calculateValue();
  }
  
  calculateValue() {
    // A=1, 2-10=face, J/Q/K=10
  }
  
  toString() {
    return `${this.rank}${this.suit}`;
  }
}
```

#### Deck Class
```javascript
class Deck {
  constructor() {
    this.cards = this.generateDeck();
    this.discardPile = [];
  }
  
  generateDeck() { /* Create 52 cards */ }
  shuffle() { /* Fisher-Yates shuffle */ }
  draw() { /* Remove and return top card */ }
  discard(card) { /* Add to discard pile */ }
}
```

#### Player Class
```javascript
class Player {
  constructor(name, isHuman = false) {
    this.name = name;
    this.hand = [];
    this.spreads = [];
    this.isHuman = isHuman;
  }
  
  calculatePoints() {
    // Sum all cards in hand
  }
  
  canKnock() {
    return this.calculatePoints() <= 5;
  }
  
  hasWon() {
    return this.hand.length === 0;
  }
}
```

#### ComputerPlayer Class (AI)
```javascript
class ComputerPlayer extends Player {
  constructor(name, difficulty = 'medium') {
    super(name, false);
    this.difficulty = difficulty;
  }
  
  decideDraw(discardTop) {
    // AI logic: take discard if it helps form spread
  }
  
  decideDiscard() {
    // AI logic: discard highest value card that doesn't help spreads
  }
  
  findSpreads() {
    // AI logic: identify possible books and runs
  }
  
  shouldKnock() {
    // AI logic: knock if points <= 3 (or 5 if desperate)
  }
}
```

---

## Computer AI Strategy

### Basic AI Logic (Easy Mode)
1. **Drawing Phase**:
   - Take discard if it completes a spread
   - Otherwise draw from deck
   
2. **Spread Formation**:
   - Look for any valid sets/runs in hand
   - Lay down immediately if found
   
3. **Discard Phase**:
   - Discard highest point card that doesn't contribute to potential spreads
   
4. **Knocking**:
   - Knock if points ≤ 3

### Medium AI Logic
1. **Drawing Phase**:
   - Take discard if it completes spread OR contributes to near-complete spread
   - Avoid giving next player useful cards
   
2. **Spread Formation**:
   - Calculate if laying down spreads improves position
   - Hold cards if one card away from multiple spreads
   
3. **Discard Phase**:
   - Track what opponents might need
   - Discard cards unlikely to help opponents
   - Break up low-value incomplete spreads if needed
   
4. **Knocking**:
   - Knock if points ≤ 5 and unlikely to get lower
   - Consider opponents' likely hand values

### Hard AI Logic (Future Enhancement)
- Memory of discarded cards
- Probabilistic analysis of opponent hands
- Optimal spread formation timing
- Strategic knocking based on game state

---

## Implementation Phases

### Phase 1: Core Game Logic (Day 1)
- [ ] Card, Deck, Player classes
- [ ] Deck shuffling and dealing
- [ ] Basic turn flow (draw, discard)
- [ ] Point calculation
- [ ] Win condition detection

### Phase 2: Spread Mechanics (Day 1-2)
- [ ] Spread validation (books and runs)
- [ ] Laying down spreads
- [ ] Adding to existing spreads
- [ ] Spread display in UI

### Phase 3: Basic UI (Day 2)
- [ ] Card rendering (Unicode or CSS)
- [ ] Hand display
- [ ] Deck and discard pile
- [ ] Action buttons
- [ ] Turn indicators

### Phase 4: Computer AI (Day 2-3)
- [ ] Basic AI decision making
- [ ] AI turn automation
- [ ] Difficulty levels (optional)

### Phase 5: Polish (Day 3)
- [ ] Card animations
- [ ] Sound effects (optional)
- [ ] Mobile responsive
- [ ] Game state persistence
- [ ] Statistics/history

---

## Key Game Rules Implementation

### Initial Tonk Check
```javascript
function checkInitialTonk(player) {
  const points = player.calculatePoints();
  if (points === 50) {
    // Player wins immediately
    return true;
  }
  return false;
}
```

### Spread Validation
```javascript
function isValidBook(cards) {
  // Check if all cards have same rank
  // Minimum 3 cards
  return cards.length >= 3 && 
         cards.every(card => card.rank === cards[0].rank);
}

function isValidRun(cards) {
  // Check if cards are sequential in same suit
  // Minimum 3 cards
  // Sort cards by value
  // Check consecutive values
}
```

### Knock Logic
```javascript
function processKnock(knockingPlayer, allPlayers) {
  const scores = allPlayers.map(p => ({
    player: p,
    points: p.calculatePoints()
  }));
  
  const winner = scores.reduce((min, curr) => 
    curr.points < min.points ? curr : min
  );
  
  return winner.player;
}
```

---

## User Interactions

### Player Actions
1. **Start Game**: Choose number of opponents (1-3)
2. **Draw Card**: Click deck or discard pile
3. **Select Cards**: Click cards to select/deselect
4. **Form Spread**: Click "Form Spread" with selected cards
5. **Discard**: Click selected card then "Discard"
6. **Knock**: Click "Knock" button (only if ≤5 points, start of turn)
7. **End Turn**: Automatic after discard

### Computer Turn Flow
1. Show "Computer thinking..." message
2. Brief delay (500-1000ms) for realism
3. Animate computer's action
4. Show what computer did (drew, laid spread, discarded)
5. Move to next player

---

## State Management

### Game State Object
```javascript
const gameState = {
  deck: Deck,
  players: [Player, ComputerPlayer, ...],
  currentPlayerIndex: 0,
  discardPile: [Card],
  phase: 'draw' | 'action' | 'discard',
  winner: null,
  gameOver: false,
  spreads: {
    player1: [Spread],
    player2: [Spread],
    // ...
  }
}
```

### LocalStorage Schema
```javascript
{
  currentGame: gameState,
  statistics: {
    gamesPlayed: 0,
    wins: 0,
    losses: 0,
    averagePoints: 0
  },
  settings: {
    soundEnabled: true,
    difficulty: 'medium',
    numberOfOpponents: 1
  }
}
```

---

## Testing Checklist

### Core Functionality
- [ ] Cards dealt correctly (5 or 7 per player)
- [ ] Initial 50-point tonk detection
- [ ] Valid spreads accepted
- [ ] Invalid spreads rejected
- [ ] Points calculated correctly
- [ ] Knock only available when ≤5 points
- [ ] Winner determined correctly
- [ ] Deck reshuffles when empty

### AI Behavior
- [ ] AI makes legal moves
- [ ] AI forms valid spreads
- [ ] AI doesn't cheat (no peeking at cards)
- [ ] AI knocking works correctly

### UI/UX
- [ ] All cards visible and clickable
- [ ] Turn indicators clear
- [ ] Game state saves/loads
- [ ] Mobile responsive
- [ ] No visual bugs

---

## Deployment

### Static Hosting Options
1. **Vercel**: `npm run build` → Deploy
2. **Netlify**: Drag and drop `dist/` folder
3. **GitHub Pages**: Push to `gh-pages` branch
4. **Your own hosting**: Upload `dist/` to server

### Build Command
```bash
npm run build
```

---

## Future Enhancements (Post-Prototype)

### Multiplayer
- Real-time multiplayer with Socket.io
- Private game rooms
- Friend invites
- Chat functionality

### Monetization
- Ads (non-intrusive)
- Premium features (themes, stats, AI difficulties)
- Tournament mode

### Features
- Achievements/badges
- Leaderboards
- Daily challenges
- Multiple game variants
- Custom card designs
- Replay/hand history

---

## Technical Considerations

### Performance
- Use event delegation for card clicks
- Debounce animations
- Lazy load sounds
- Optimize for mobile (60fps animations)

### Accessibility
- Keyboard navigation
- Screen reader support (ARIA labels)
- High contrast mode
- Colorblind-friendly suit colors

### Browser Support
- Modern browsers (Chrome, Firefox, Safari, Edge)
- Mobile browsers (iOS Safari, Chrome Android)
- No IE11 support needed

---

## Getting Started

### Quick Start Commands
```bash
# Create project
npm create vite@latest tonk-game -- --template vanilla

# Navigate to project
cd tonk-game

# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build
```

### First Steps for Claude Code
1. Set up project structure and files
2. Implement Card and Deck classes
3. Create basic HTML layout
4. Implement Player class and game initialization
5. Add draw/discard mechanics
6. Implement spread validation
7. Build Computer AI
8. Polish UI and add animations

---

## Success Criteria

The prototype is complete when:
- ✅ Can play full game against 1 computer opponent
- ✅ All Tonk rules implemented correctly
- ✅ Computer makes reasonable decisions
- ✅ Game is playable on desktop and mobile
- ✅ No game-breaking bugs
- ✅ Basic animations working
- ✅ Can restart game

---

## Questions to Consider

1. **Spread Display**: Show spreads in center area or in player zones?
2. **AI Difficulty**: Implement multiple difficulties or just one good AI?
3. **Card Design**: Unicode, CSS, or images?
4. **Sound**: Include or skip for MVP?
5. **Animations**: How smooth vs. development time?
6. **Mobile**: Touch gestures or just tap to select?

---

## Notes

- Focus on getting the game playable first
- Polish can come later
- Test frequently with different game scenarios
- Keep code modular for future multiplayer expansion
- Use Claude Code's iterative development approach
- Build in small, testable increments

**Target Timeline**: 1-2 days for full working prototype
**Difficulty**: Medium (card game logic + AI)
**Fun Factor**: High (Tonk is fast-paced and engaging!)

---

Ready to build? Start with the file structure and core classes, then iterate from there. Good luck! 🃏
