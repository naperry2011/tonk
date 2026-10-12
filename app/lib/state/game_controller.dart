import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/roster.dart';
import '../data/save_store.dart';
import '../engine/engine.dart';
import '../meta/profile.dart' show dailySeed;
import '../meta/profile_controller.dart' show RoundRewards;
import '../meta/progression.dart' show RoundFacts;
import 'table_talk.dart';

enum MatchMode { match, daily }

/// An AI raised; the human must call or fold.
class PendingRaise {
  const PendingRaise({
    required this.raiser,
    required this.amount,
    required this.toCall,
  });

  final Player raiser;
  final int amount;

  /// What calling costs the human (capped at their chips: all in).
  final int toCall;
}

/// Outcome of a finished round, shown on the round-end panel.
class RoundSummary {
  RoundSummary({
    required this.winner,
    required this.condition,
    required this.knocker,
    required this.potWinnings,
    required this.handPoints,
    required this.pointsAdded,
    required this.matchEnded,
    required this.matchWinner,
    this.isDaily = false,
  });

  /// True for the single-round daily challenge.
  final bool isDaily;

  /// XP, level-ups, unlocks, and achievements earned (set by the profile).
  RoundRewards? rewards;

  final Player winner;
  final WinCondition condition;
  final Player? knocker;
  final int potWinnings;

  /// Each player's hand points when the round ended, by player id.
  final Map<String, int> handPoints;

  /// Points added to each loser's match score, by player id.
  final Map<String, int> pointsAdded;
  final bool matchEnded;
  final Player? matchWinner;
}

/// Drives a match for the UI: human actions, paced AI turns, round
/// settlement, and save/resume.
class GameController extends ChangeNotifier {
  GameController({
    SaveStore? store,
    this.aiStepDelay = const Duration(milliseconds: 700),
    this.random,
    this.roster,
    Random? talkRandom,
    this.speechDuration = const Duration(milliseconds: 2800),
  }) : _store = store ?? SharedPrefsSaveStore(),
       _talk = roster == null
           ? null
           : TableTalk(roster: roster, random: talkRandom ?? Random());

  final SaveStore _store;
  final Random? random;
  final Duration aiStepDelay;

  /// AI characters. Without a roster, opponents get plain names and no talk.
  final Roster? roster;
  final TableTalk? _talk;
  final Duration speechDuration;

  /// What each AI is currently saying, by player id.
  final Map<String, String> speech = {};
  final Map<String, Timer> _speechTimers = {};

  final StreamController<GameEvent> _events =
      StreamController<GameEvent>.broadcast();

  /// Every engine event, for sound, haptics, and animation hooks.
  Stream<GameEvent> get events => _events.stream;

  /// What the AI calls the human in table talk.
  set nickname(String value) => _talk?.nickname = value;

  Character? characterFor(Player player) =>
      player is ComputerPlayer ? roster?.byId(player.characterId) : null;

  Game? _game;
  Game get game => _game ?? (throw StateError('No match in progress'));
  bool get hasGame => _game != null;

  /// Cards the human has tapped, in tap order.
  final List<Card> selected = [];

  /// Most recent visible action per player id, for seat bubbles.
  final Map<String, String> lastAction = {};

  /// Latest line for the table status bar.
  String? status;

  RoundSummary? roundSummary;
  bool aiThinking = false;
  bool raisedThisTurn = false;

  /// An AI raised and the human must call or fold before play continues.
  PendingRaise? pendingRaise;
  Completer<bool>? _raiseAnswer;

  /// Restored from a save made while the call/fold prompt was showing.
  ({String raiserId, int amount})? _restoredRaise;

  /// AIs that already raised this round (one raise each per round).
  final Set<String> _aiRaisedThisRound = {};

  MatchMode mode = MatchMode.match;

  /// Called once per finished round; returns what the round earned.
  RoundRewards Function(RoundFacts facts)? onRoundSettled;

  /// Called when a regular match ends, with the human's chips to cash out.
  void Function(int chips)? onMatchEnded;

  /// Spreads the human laid this round (for stats).
  int _humanSpreads = 0;

  /// Set when an action is rejected by the rules; the UI shows and clears it.
  String? error;

  bool _settled = false;

  /// Bumped on every new match or dispose, so stale AI loops stop.
  int _session = 0;
  bool _disposed = false;

  Player get human => game.players.firstWhere((p) => p.isHuman);

  List<Player> get opponents => game.players.where((p) => !p.isHuman).toList();

  bool get isHumanTurn =>
      hasGame && !game.isGameOver && game.currentPlayer.isHuman && !aiThinking;

  // ---------------------------------------------------------------------
  // Match lifecycle
  // ---------------------------------------------------------------------

  Future<bool> hasSavedMatch() async => await _store.load() != null;

  /// Deals a new match. [pool] limits which characters can be drawn
  /// (e.g. to unlocked ones); [startingChips] is each seat's stack.
  void newMatch(
    int opponentCount, {
    int startingChips = Betting.startingChips,
    List<Character>? pool,
  }) {
    _resetTable();
    mode = MatchMode.match;
    final game = Game(random: random)..addListener(_onEvent);
    _game = game;
    final roster = this.roster;
    if (roster == null) {
      game.initialize(opponentCount + 1);
    } else {
      final cast = Roster(
        characters: pool ?? roster.characters,
        shared: roster.shared,
      ).pick(opponentCount, game.random);
      game.initializeWithPlayers([
        Player('You', isHuman: true),
        for (final c in cast) _seat(c, game),
      ], startingChips: startingChips);
    }
    status = 'New match, first to 100 loses. ${_turnHint()}';
    _afterChange();
  }

  /// Deals the daily challenge: one round, same deal for everyone on [day].
  void newDaily(String day, List<Character> opponents) {
    _resetTable();
    mode = MatchMode.daily;
    final game = Game(random: Random(dailySeed(day)))..addListener(_onEvent);
    _game = game;
    game.initializeWithPlayers([
      Player('You', isHuman: true),
      for (final c in opponents) _seat(c, game),
    ]);
    status = "Today's deal. One round, make it count. ${_turnHint()}";
    _afterChange();
  }

  ComputerPlayer _seat(Character c, Game game) => ComputerPlayer(
    c.name,
    style: c.style,
    characterId: c.id,
    random: game.random,
  );

  /// Restores the saved match. Returns false if there is nothing to resume.
  Future<bool> resume() async {
    final saved = await _store.load();
    if (saved == null) return false;
    try {
      _resetTable();
      final game = Game.fromJson(
        saved['game'] as Map<String, dynamic>,
        random: random,
      )..addListener(_onEvent);
      _game = game;
      _settled = saved['settled'] as bool? ?? false;
      mode = saved['mode'] == 'daily' ? MatchMode.daily : MatchMode.match;
      _humanSpreads = saved['humanSpreads'] as int? ?? 0;
      _aiRaisedThisRound.addAll(
        (saved['aiRaised'] as List? ?? const []).cast<String>(),
      );
      final pending = saved['pendingRaise'] as Map<String, dynamic>?;
      if (pending != null) {
        _restoredRaise = (
          raiserId: pending['raiserId'] as String,
          amount: pending['amount'] as int,
        );
      }
      if (game.isGameOver && _settled) {
        // The round-end panel was showing; move on to the next round.
        if (game.matchWinner != null) {
          await _store.clear();
          _game = null;
          return false;
        }
        startNextRound();
        return true;
      }
      status = 'Welcome back. ${_turnHint()}';
      _afterChange();
      return true;
    } on Object {
      await _store.clear();
      _game = null;
      return false;
    }
  }

  void startNextRound() {
    roundSummary = null;
    _settled = false;
    selected.clear();
    lastAction.clear();
    _aiRaisedThisRound.clear();
    _humanSpreads = 0;
    game.startNextRound();
    status = 'Round ${game.roundNumber}. ${_turnHint()}';
    _afterChange();
  }

  /// Ends the match and forgets the save.
  Future<void> abandonMatch() async {
    _session++;
    _game = null;
    roundSummary = null;
    await _store.clear();
    _notify();
  }

  void _resetTable() {
    _session++;
    _clearSpeech();
    selected.clear();
    lastAction.clear();
    roundSummary = null;
    aiThinking = false;
    raisedThisTurn = false;
    error = null;
    _settled = false;
    _aiRaisedThisRound.clear();
    _humanSpreads = 0;
    _restoredRaise = null;
    _dropPendingRaise();
  }

  void _dropPendingRaise() {
    final answer = _raiseAnswer;
    if (answer != null && !answer.isCompleted) answer.complete(false);
    _raiseAnswer = null;
    pendingRaise = null;
  }

  // ---------------------------------------------------------------------
  // Human actions
  // ---------------------------------------------------------------------

  void toggleSelect(Card card) {
    if (!hasGame || game.isGameOver) return;
    selected.contains(card) ? selected.remove(card) : selected.add(card);
    _notify();
  }

  void reorderHand(int oldIndex, int newIndex) {
    human.reorderCard(oldIndex, newIndex);
    _notify();
    _save();
  }

  bool get canKnock => isHumanTurn && game.phase == Phase.startOfTurn;

  bool get canDraw =>
      isHumanTurn &&
      (game.phase == Phase.startOfTurn || game.phase == Phase.draw);

  bool get canLaySelected =>
      isHumanTurn &&
      (game.phase == Phase.startOfTurn || game.phase == Phase.action) &&
      Spread.validate(selected).valid;

  bool get canDiscard =>
      isHumanTurn && game.phase == Phase.action && selected.length == 1;

  bool canHit(Spread spread) =>
      isHumanTurn &&
      (game.phase == Phase.startOfTurn || game.phase == Phase.action) &&
      selected.length == 1 &&
      spread.canAddCard(selected.single);

  bool canRaise(int amount) =>
      isHumanTurn && !raisedThisTurn && human.canAfford(amount);

  void knock() => _humanAction(game.knock);

  void drawFromDeck() => _humanAction(() {
    if (game.phase == Phase.startOfTurn) game.proceedToDraw();
    game.drawFromDeck();
  });

  void drawFromDiscard() => _humanAction(() {
    if (game.topDiscard == null) {
      throw const GameRuleException('The discard pile is empty');
    }
    if (game.phase == Phase.startOfTurn) game.proceedToDraw();
    game.drawFromDiscard();
  });

  void laySelected() => _humanAction(() {
    game.laySpread(List.of(selected));
    selected.clear();
  });

  void hit(Spread spread) => _humanAction(() {
    game.hitSpread(selected.single, spread);
    selected.clear();
  });

  void discardSelected() => _humanAction(() {
    final card = selected.single;
    selected.clear();
    game.discard(card);
  });

  /// Human raises; each opponent still in calls or folds.
  void raise(int amount) => _humanAction(() {
    if (!canRaise(amount)) {
      throw const GameRuleException("You can't raise right now");
    }
    game.placeBet(human, amount);
    raisedThisTurn = true;
    status = 'You raised $amount';
    _respondToRaise(raiser: human, amount: amount);
  });

  /// Answer an AI's raise from the call/fold prompt.
  void answerRaise({required bool call}) {
    final answer = _raiseAnswer;
    if (answer != null && !answer.isCompleted) answer.complete(call);
  }

  /// Every AI still in (other than [raiser]) calls or folds.
  void _respondToRaise({required Player raiser, required int amount}) {
    final responses = <ComputerPlayer, bool>{};
    for (final ai in game.activePlayers.whereType<ComputerPlayer>()) {
      if (identical(ai, raiser) || game.isGameOver) continue;
      // Players with no chips left are all in and stay in for free.
      if (ai.chips <= 0 || ai.shouldCall(amount)) {
        final paid = game.placeBet(ai, amount);
        lastAction[ai.id] = paid < amount ? 'All in!' : 'Calls $paid';
        responses[ai] = true;
      } else {
        lastAction[ai.id] = 'Folds';
        responses[ai] = false;
        game.fold(ai);
      }
    }
    _showSpeech(_talk?.raiseResponses(responses));
  }

  /// At the start of an AI's turn it may raise (once per round). Other AIs
  /// respond, then the human is asked to call or fold. Returns false if the
  /// session changed while waiting.
  Future<bool> _maybeAiRaise(ComputerPlayer ai, int session) async {
    final restored = _restoredRaise;
    _restoredRaise = null;
    var amount = 0;

    if (restored != null && restored.raiserId == ai.id) {
      amount = restored.amount;
    } else {
      if (_aiRaisedThisRound.contains(ai.id)) return true;
      final wanted = ai.decideBet();
      if (wanted <= 0) return true;
      _aiRaisedThisRound.add(ai.id);
      amount = game.placeBet(ai, wanted);
      lastAction[ai.id] = 'Raised $amount';
      _showSpeech(_talk?.aiRaised(ai));
      _notify();
      _save();
      await Future<void>.delayed(aiStepDelay);
      if (session != _session || _disposed) return false;
      _respondToRaise(raiser: ai, amount: amount);
    }

    final h = human;
    if (!game.isGameOver && h.isActive && h.chips > 0) {
      final answer = _raiseAnswer = Completer<bool>();
      pendingRaise = PendingRaise(
        raiser: ai,
        amount: amount,
        toCall: amount < h.chips ? amount : h.chips,
      );
      status = '${ai.name} raised $amount. Call or fold?';
      _notify();
      _save();
      final call = await answer.future;
      if (session != _session || _disposed) return false;
      pendingRaise = null;
      _raiseAnswer = null;
      if (call) {
        game.placeBet(h, amount);
        status = 'You called.';
      } else {
        game.fold(h);
        status = 'You folded. Sit back and watch this one.';
      }
    }
    if (game.isGameOver) _settleRound();
    _notify();
    _save();
    return true;
  }

  void clearError() {
    error = null;
  }

  void _humanAction(void Function() action) {
    if (!hasGame || !isHumanTurn) return;
    try {
      action();
      error = null;
    } on GameRuleException catch (e) {
      error = e.message;
      _notify();
      return;
    }
    _afterChange();
  }

  // ---------------------------------------------------------------------
  // Flow
  // ---------------------------------------------------------------------

  void _afterChange() {
    if (game.isGameOver) _settleRound();
    _notify();
    _save();
    if (!game.isGameOver && !game.currentPlayer.isHuman && !aiThinking) {
      unawaited(_runAiTurns());
    }
  }

  Future<void> _runAiTurns() async {
    final session = _session;
    aiThinking = true;
    _notify();

    while (!game.isGameOver && !game.currentPlayer.isHuman) {
      final ai = game.currentPlayer as ComputerPlayer;
      if (game.phase == Phase.startOfTurn) {
        if (!await _maybeAiRaise(ai, session)) return;
        if (game.isGameOver) break;
      }
      final steps = runAiTurn(game).iterator;
      while (true) {
        await Future<void>.delayed(aiStepDelay);
        if (session != _session || _disposed) return;
        if (!steps.moveNext()) break;
        _notify();
        _save();
        // Hand control back right away once the AI's turn is over.
        if (game.isGameOver || !identical(game.currentPlayer, ai)) break;
      }
    }

    aiThinking = false;
    _afterChange();
  }

  void _settleRound() {
    if (_settled) return;
    _settled = true;
    selected.clear();

    final game = this.game;
    final isDaily = mode == MatchMode.daily;
    final handPoints = {
      for (final p in game.players) p.id: p.calculatePoints(),
    };
    final settlement = game.settleRound();
    // The daily challenge is a single round.
    final matchEnded = settlement.matchEnded || isDaily;
    final winner = game.winner!;
    final human = this.human;
    final summary = roundSummary = RoundSummary(
      winner: winner,
      condition: game.winCondition!,
      knocker: _lastKnocker,
      potWinnings: settlement.potWinnings,
      handPoints: handPoints,
      pointsAdded: {
        for (final loss in settlement.losers) loss.player.id: loss.pointsAdded,
      },
      matchEnded: matchEnded,
      matchWinner: isDaily ? winner : game.matchWinner,
      isDaily: isDaily,
    );

    summary.rewards = onRoundSettled?.call(
      RoundFacts(
        won: winner.isHuman,
        condition: summary.condition,
        humanKnocked: _lastKnocker?.isHuman ?? false,
        humanFolded: human.hasFolded,
        potWon: winner.isHuman ? settlement.potWinnings : 0,
        spreadsLaid: _humanSpreads,
        matchEnded: settlement.matchEnded && !isDaily,
        matchWon:
            !isDaily && settlement.matchEnded && game.matchWinner == human,
        isDaily: isDaily,
      ),
    );
    if (settlement.matchEnded && !isDaily) onMatchEnded?.call(human.chips);

    _lastKnocker = null;
    if (matchEnded) _showSpeech(_talk?.matchEnd(game));
  }

  Player? _lastKnocker;

  void _onEvent(GameEvent event) {
    final game = _game;
    if (game != null) _showSpeech(_talk?.react(event, game));
    if (!_disposed) _events.add(event);

    switch (event) {
      case TurnStart(:final player):
        if (player.isHuman) {
          raisedThisTurn = false;
          status = _turnHint();
        } else {
          status = "${player.name}'s turn";
        }
      case CardDrawn(:final player, :final source):
        if (player.isHuman) {
          status = 'Spread, hit, or pick a card to discard.';
        } else {
          lastAction[player.id] = source == DrawSource.discard
              ? 'Took the discard'
              : 'Drew a card';
        }
      case SpreadLaid(:final player, :final spread):
        if (player.isHuman) _humanSpreads++;
        _say(player, 'Laid ${_spreadName(spread)}');
      case SpreadHit(:final player, :final card):
        _say(player, 'Hit with $card');
      case CardDiscarded(:final player, :final card):
        if (!player.isHuman) lastAction[player.id] = 'Dropped $card';
      case Knocked(:final knocker):
        _lastKnocker = knocker;
        _say(knocker, 'Knock knock!');
      case InitialTonkDraw():
        status = 'Double 49-50 on the deal. Redeal!';
      case GameOver() ||
          GameInitialized() ||
          RoundStart() ||
          AntesCollected() ||
          CardsDealt() ||
          PhaseChanged() ||
          TurnEnd() ||
          Folded() ||
          BetPlaced() ||
          PotAwarded():
        break;
    }
  }

  String _turnHint() {
    final game = this.game;
    if (game.isGameOver) return '';
    final player = game.currentPlayer;
    return player.isHuman
        ? 'Your turn: knock, spread, or draw.'
        : "${player.name}'s turn.";
  }

  void _say(Player player, String text) {
    if (player.isHuman) {
      status = text
          .replaceFirst('Laid', 'You laid')
          .replaceFirst('Hit with', 'You hit with');
    } else {
      lastAction[player.id] = text;
    }
  }

  static String _spreadName(Spread spread) => spread.type == SpreadType.book
      ? 'a book of ${spread.cards.first.rank}s'
      : 'a run';

  void _save() {
    final game = _game;
    if (game == null) return;
    if (_settled && (roundSummary?.matchEnded ?? false)) {
      unawaited(_store.clear());
      return;
    }
    unawaited(
      _store.save({
        'version': 1,
        'mode': mode.name,
        'humanSpreads': _humanSpreads,
        'game': game.toJson(),
        'settled': _settled,
        'aiRaised': _aiRaisedThisRound.toList(),
        if (pendingRaise case final p?)
          'pendingRaise': {'raiserId': p.raiser.id, 'amount': p.amount},
      }),
    );
  }

  void _showSpeech(List<Speech>? lines) {
    if (lines == null) return;
    for (final line in lines) {
      speech[line.playerId] = line.text;
      _speechTimers[line.playerId]?.cancel();
      _speechTimers[line.playerId] = Timer(speechDuration, () {
        speech.remove(line.playerId);
        _speechTimers.remove(line.playerId);
        _notify();
      });
    }
  }

  void _clearSpeech() {
    for (final timer in _speechTimers.values) {
      timer.cancel();
    }
    _speechTimers.clear();
    speech.clear();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _dropPendingRaise();
    _clearSpeech();
    _events.close();
    super.dispose();
  }
}
