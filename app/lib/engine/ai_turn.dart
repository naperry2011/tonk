import 'card.dart';
import 'computer_player.dart';
import 'game.dart';
import 'rules.dart';
import 'spread.dart';

/// One visible step of an AI turn, for UI pacing and table talk.
sealed class AiAction {
  const AiAction();
}

class AiKnocked extends AiAction {
  const AiKnocked();
}

class AiLaidSpread extends AiAction {
  const AiLaidSpread(this.spread);
  final Spread spread;
}

class AiHitSpread extends AiAction {
  const AiHitSpread(this.card, this.spread);
  final Card card;
  final Spread spread;
}

class AiProceededToDraw extends AiAction {
  const AiProceededToDraw();
}

class AiDrew extends AiAction {
  const AiDrew(this.source, this.card);
  final DrawSource source;

  /// Null when the stock was empty (the round ended).
  final Card? card;
}

class AiDiscarded extends AiAction {
  const AiDiscarded(this.card);
  final Card card;
}

/// Plays the current AI player's turn one action at a time.
///
/// Each action is applied to [game] when the iterator advances, so a UI can
/// pause between steps while a simulation just runs `.toList()`. Port of
/// `GameUI.handleAITurn` in src/ui/GameUI.js.
Iterable<AiAction> runAiTurn(Game game) sync* {
  final ai = game.currentPlayer;
  if (ai is! ComputerPlayer) {
    throw const GameRuleException('Current player is not an AI');
  }

  if (game.phase == Phase.startOfTurn) {
    if (ai.shouldKnock()) {
      game.knock();
      yield const AiKnocked();
      return;
    }

    yield* _layAndHit(game, ai);
    if (game.isGameOver) return;

    game.proceedToDraw();
    yield const AiProceededToDraw();
  }

  if (game.phase == Phase.draw) {
    final discardTop = game.topDiscard;
    final source = ai.decideDraw(discardTop);
    final card = source == DrawSource.discard && discardTop != null
        ? game.drawFromDiscard()
        : game.drawFromDeck();
    yield AiDrew(
      source == DrawSource.discard && discardTop != null
          ? DrawSource.discard
          : DrawSource.deck,
      card,
    );
    if (game.isGameOver) return;
  }

  yield* _layAndHit(game, ai);
  if (game.isGameOver) return;

  if (ai.hand.isNotEmpty) {
    final card = ai.decideDiscard();
    game.discard(card);
    yield AiDiscarded(card);
  }
}

Iterable<AiAction> _layAndHit(Game game, ComputerPlayer ai) sync* {
  for (final candidate in ai.findAllSpreadsToLay()) {
    if (!candidate.cards.every(ai.hasCard)) continue;
    final spread = game.laySpread(candidate.cards);
    yield AiLaidSpread(spread);
    if (game.isGameOver) return;
  }

  for (final hit in ai.findHitOpportunities(game.spreadsOnTable)) {
    if (!ai.hasCard(hit.card) || !hit.spread.canAddCard(hit.card)) continue;
    game.hitSpread(hit.card, hit.spread);
    yield AiHitSpread(hit.card, hit.spread);
    if (game.isGameOver) return;
  }
}
