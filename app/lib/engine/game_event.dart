import 'card.dart';
import 'computer_player.dart';
import 'player.dart';
import 'rules.dart';
import 'spread.dart';

/// Events emitted by Game. Mirrors the JS event catalog in src/game/Game.js.
sealed class GameEvent {
  const GameEvent();
}

class GameInitialized extends GameEvent {
  const GameInitialized(this.players);
  final List<Player> players;
}

class RoundStart extends GameEvent {
  const RoundStart(this.roundNumber);
  final int roundNumber;
}

class AntesCollected extends GameEvent {
  const AntesCollected({required this.pot, required this.ante});
  final int pot;
  final int ante;
}

class CardsDealt extends GameEvent {
  const CardsDealt(this.cardsPerPlayer);
  final int cardsPerPlayer;
}

/// More than one player was dealt 49-50 points; the hand is redealt.
class InitialTonkDraw extends GameEvent {
  const InitialTonkDraw(this.players);
  final List<Player> players;
}

class TurnStart extends GameEvent {
  const TurnStart(this.player);
  final Player player;
}

class PhaseChanged extends GameEvent {
  const PhaseChanged(this.phase);
  final Phase phase;
}

class CardDrawn extends GameEvent {
  const CardDrawn(this.player, this.source, this.card);
  final Player player;
  final DrawSource source;
  final Card card;
}

class SpreadLaid extends GameEvent {
  const SpreadLaid(this.player, this.spread);
  final Player player;
  final Spread spread;
}

class SpreadHit extends GameEvent {
  const SpreadHit(this.player, this.card, this.spread);
  final Player player;
  final Card card;
  final Spread spread;
}

class CardDiscarded extends GameEvent {
  const CardDiscarded(this.player, this.card);
  final Player player;
  final Card card;
}

class Knocked extends GameEvent {
  const Knocked(this.knocker, this.winner);
  final Player knocker;
  final Player winner;
}

class TurnEnd extends GameEvent {
  const TurnEnd(this.nextPlayer);
  final Player nextPlayer;
}

class GameOver extends GameEvent {
  const GameOver(this.winner, this.condition, {this.knocker});
  final Player winner;
  final WinCondition condition;
  final Player? knocker;
}

class BetPlaced extends GameEvent {
  const BetPlaced(this.player, this.amount, this.pot);
  final Player player;
  final int amount;
  final int pot;
}

class PotAwarded extends GameEvent {
  const PotAwarded(this.winner, this.amount);
  final Player winner;
  final int amount;
}

/// [player] passed on a raise and sits out the rest of the round.
class Folded extends GameEvent {
  const Folded(this.player);
  final Player player;
}
