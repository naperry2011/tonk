import 'player.dart';

const int cardsPerPlayer = 5;
const int initialTonkMin = 49;
const int initialTonkMax = 50;
const int minSpreadSize = 3;
const int maxPlayers = 4;
const int minPlayers = 2;

/// First player to reach this match score loses the match.
const int matchPointLimit = 100;

abstract final class Betting {
  static const int startingChips = 1000;
  static const int anteAmount = 10;
  static const List<int> raiseOptions = [10, 25, 50, 100];
}

/// Always 5 cards, regardless of player count.
int getCardsPerPlayer(int playerCount) => cardsPerPlayer;

/// Knocking (dropping) is always allowed; there is no point threshold.
bool canKnock(int points) => true;

bool hasInitialTonk(int points) =>
    points >= initialTonkMin && points <= initialTonkMax;

/// Lowest hand points wins; ties go to the earlier player in the list.
Player? determineKnockWinner(List<Player> players) {
  if (players.isEmpty) return null;
  return players.reduce(
    (winner, player) =>
        player.calculatePoints() < winner.calculatePoints() ? player : winner,
  );
}

enum Phase {
  preGame('pre-game'),
  initialTonkCheck('initial-tonk-check'),

  /// Player may knock, lay spreads, or hit before drawing.
  startOfTurn('start-of-turn'),
  draw('draw'),
  action('action'),
  discard('discard'),
  gameOver('game-over');

  const Phase(this.value);
  final String value;

  static Phase fromValue(String value) =>
      Phase.values.firstWhere((p) => p.value == value);
}

enum WinCondition {
  /// Empty hand.
  tonk('tonk'),

  /// 49-50 points at the deal.
  initialTonk('initial-tonk'),

  /// Multiple players had 49-50 at the deal; redeal.
  initialTonkDraw('initial-tonk-draw'),

  /// Knocker had strictly the lowest points.
  knock('knock'),

  /// Knocker did not have the lowest points.
  caught('caught'),

  /// Stock ran out; lowest points wins.
  stockEmpty('stock-empty'),

  /// Everyone else folded on a raise.
  allFolded('all-folded');

  const WinCondition(this.value);
  final String value;

  static WinCondition fromValue(String value) =>
      WinCondition.values.firstWhere((c) => c.value == value);
}
