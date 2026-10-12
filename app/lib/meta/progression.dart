import '../engine/engine.dart';
import 'profile.dart';

/// What happened to the human in one finished round.
class RoundFacts {
  const RoundFacts({
    required this.won,
    required this.condition,
    this.humanKnocked = false,
    this.humanFolded = false,
    this.potWon = 0,
    this.spreadsLaid = 0,
    this.matchEnded = false,
    this.matchWon = false,
    this.isDaily = false,
  });

  final bool won;
  final WinCondition condition;
  final bool humanKnocked;
  final bool humanFolded;
  final int potWon;
  final int spreadsLaid;
  final bool matchEnded;
  final bool matchWon;
  final bool isDaily;
}

/// XP for one round, itemized for the round-end panel.
List<({String label, int xp})> xpBreakdown(RoundFacts f) => [
  if (f.won)
    (label: 'Round win', xp: 50)
  else if (f.humanFolded)
    (label: 'Played', xp: 5)
  else
    (label: 'Played', xp: 10),
  if (f.won && f.condition == WinCondition.tonk) (label: 'Tonk', xp: 50),
  if (f.won && f.condition == WinCondition.initialTonk)
    (label: 'Dealt a Tonk', xp: 25),
  if (f.won && f.condition == WinCondition.knock && f.humanKnocked)
    (label: 'Knock', xp: 25),
  if (f.won && f.condition == WinCondition.caught)
    (label: 'Caught a knocker', xp: 25),
  if (f.matchEnded) (label: 'Match finished', xp: 50),
  if (f.matchWon) (label: 'Match won', xp: 200),
  if (f.isDaily) (label: 'Daily challenge', xp: f.won ? 150 : 25),
];

int xpFor(RoundFacts f) => xpBreakdown(f).fold(0, (sum, e) => sum + e.xp);

/// Total XP needed to reach [level]: 0, 100, 300, 600, 1000, ...
int xpForLevel(int level) => 50 * level * (level - 1);

int levelForXp(int xp) {
  var level = 1;
  while (xp >= xpForLevel(level + 1)) {
    level++;
  }
  return level;
}

enum UnlockKind { table, deck, character }

class Unlock {
  const Unlock(this.level, this.kind, this.id, this.label);
  final int level;
  final UnlockKind kind;
  final String id;
  final String label;
}

/// Everything not listed here is available from the start: the Card Room
/// table, Rose Gold and Midnight Gold backs, and Uncle Ray, Mr. Earl,
/// Keisha, and Lil Tre.
const List<Unlock> unlockTrack = [
  Unlock(2, UnlockKind.deck, 'emerald', 'Emerald Isle card backs'),
  Unlock(3, UnlockKind.table, 'cookout', 'Backyard Cookout table'),
  Unlock(3, UnlockKind.character, 'aunt_dot', 'Aunt Dot joins the table'),
  Unlock(4, UnlockKind.deck, 'royal', 'Royal Velvet card backs'),
  Unlock(
    5,
    UnlockKind.character,
    'grandma_pearl',
    'Grandma Pearl joins the table',
  ),
  Unlock(6, UnlockKind.table, 'rooftop', 'Rooftop table'),
  Unlock(7, UnlockKind.deck, 'crimson', 'Crimson Club card backs'),
  Unlock(8, UnlockKind.character, 'cousin_dre', 'Cousin Dre joins the table'),
  Unlock(10, UnlockKind.deck, 'ocean', 'Ocean Blue card backs'),
];

/// Level that unlocks [id], or 1 if it's available from the start.
int unlockLevel(UnlockKind kind, String id) {
  for (final u in unlockTrack) {
    if (u.kind == kind && u.id == id) return u.level;
  }
  return 1;
}

bool isUnlocked(UnlockKind kind, String id, int level) =>
    level >= unlockLevel(kind, id);

List<Unlock> unlocksBetween(int fromLevel, int toLevel) => [
  for (final u in unlockTrack)
    if (u.level > fromLevel && u.level <= toLevel) u,
];

class Achievement {
  const Achievement(this.id, this.title, this.description, this.earned);
  final String id;
  final String title;
  final String description;
  final bool Function(Profile p) earned;
}

final List<Achievement> achievements = [
  Achievement(
    'first_win',
    'First Blood',
    'Win a round.',
    (p) => p.stats.roundsWon >= 1,
  ),
  Achievement(
    'tonk',
    'Tonk!',
    'Go out with an empty hand.',
    (p) => p.stats.tonks >= 1,
  ),
  Achievement(
    'knock',
    'Knock Knock',
    'Win a round by knocking.',
    (p) => p.stats.knockWins >= 1,
  ),
  Achievement(
    'gotcha',
    'Gotcha',
    'Catch someone knocking.',
    (p) => p.stats.catches >= 1,
  ),
  Achievement(
    'hot_hand',
    'Hot Hand',
    'Win 3 rounds in a row.',
    (p) => p.stats.bestWinStreak >= 3,
  ),
  Achievement(
    'on_fire',
    'On Fire',
    'Win 5 rounds in a row.',
    (p) => p.stats.bestWinStreak >= 5,
  ),
  Achievement('champ', 'Champ', 'Win a match.', (p) => p.stats.matchesWon >= 1),
  Achievement(
    'spread_master',
    'Spread Master',
    'Lay 25 spreads.',
    (p) => p.stats.spreadsLaid >= 25,
  ),
  Achievement(
    'high_roller',
    'High Roller',
    'Hold 5,000 chips.',
    (p) => p.bankroll >= 5000,
  ),
  Achievement(
    'daily_grind',
    'Daily Grind',
    'Play the daily 3 days in a row.',
    (p) => p.dailyStreak >= 3,
  ),
];
