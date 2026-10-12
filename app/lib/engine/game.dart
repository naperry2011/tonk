import 'dart:math';

import 'ai_style.dart';
import 'card.dart';
import 'computer_player.dart';
import 'deck.dart';
import 'game_event.dart';
import 'player.dart';
import 'rules.dart';
import 'spread.dart';

const List<String> aiNamePool = [
  'Alex', 'Jordan', 'Sam', 'Casey', 'Riley', 'Morgan', //
  'Taylor', 'Avery', 'Quinn', 'Blake', 'Parker', 'Reese',
  'Charlie', 'Frankie', 'Jamie', 'Skyler', 'Drew', 'Sage',
  'Max', 'Jessie', 'Robin', 'Dana', 'Chris', 'Pat',
];

typedef GameListener = void Function(GameEvent event);

typedef RoundLoss = ({Player player, int pointsAdded, int newTotal});

typedef RoundSettlement = ({
  int potWinnings,
  List<RoundLoss> losers,
  bool matchEnded,
});

/// Thrown when an action is attempted in the wrong phase or with bad input.
class GameRuleException implements Exception {
  const GameRuleException(this.message);
  final String message;

  @override
  String toString() => 'GameRuleException: $message';
}

/// Game state machine. Pure Dart: no Flutter imports.
class Game {
  Game({Random? random, Deck Function(Random random)? deckFactory})
    : random = random ?? Random(),
      _deckFactory = deckFactory ?? Deck.new;

  /// Shared by the deck shuffle, AI name picks, and AI betting.
  final Random random;

  /// Builds each round's deck. Overridable so tests can stack the deck.
  final Deck Function(Random random) _deckFactory;

  Deck? _deck;
  List<Player> players = [];
  int currentPlayerIndex = 0;
  Phase phase = Phase.preGame;
  List<Spread> spreadsOnTable = [];
  Player? winner;
  WinCondition? winCondition;
  bool hasDrawnThisTurn = false;

  Map<String, int> matchScores = {};
  int pointLimit = matchPointLimit;
  Player? matchWinner;
  int roundNumber = 0;

  int pot = 0;
  int highestBet = 0;

  final List<GameListener> _listeners = [];

  Deck get deck => _deck ?? (throw StateError('Game not initialized'));
  set deck(Deck value) => _deck = value;

  // ---------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------

  /// Starts a match: one human plus (playerCount - 1) AI opponents.
  void initialize(
    int playerCount, {
    String humanName = 'You',
    List<String>? aiNames,
  }) {
    if (playerCount < minPlayers || playerCount > maxPlayers) {
      throw ArgumentError.value(playerCount, 'playerCount');
    }
    final names = aiNames ?? (List.of(aiNamePool)..shuffle(random));
    initializeWithPlayers([
      Player(humanName, isHuman: true),
      for (var i = 0; i < playerCount - 1; i++)
        ComputerPlayer(names[i], random: random),
    ]);
  }

  /// Starts a match with a prebuilt seat list (e.g. AI characters, or all-AI
  /// simulations).
  void initializeWithPlayers(
    List<Player> seats, {
    int startingChips = Betting.startingChips,
  }) {
    players = List.of(seats);
    currentPlayerIndex = 0;
    roundNumber = 1;
    matchWinner = null;
    matchScores = {for (final p in players) p.id: 0};
    for (final p in players) {
      p.reset();
      p.chips = startingChips;
      p.currentBet = 0;
      p.isEliminated = false;
    }
    _resetRoundState();
    _deck = _deckFactory(random);
    _collectAntesAndDeal();
    _emit(GameInitialized(players));
  }

  void startNextRound() {
    roundNumber++;
    for (final p in players) {
      p.reset();
      p.resetBet();
    }
    _resetRoundState();
    _deck = _deckFactory(random);
    _emit(RoundStart(roundNumber));
    _collectAntesAndDeal();
  }

  void _resetRoundState() {
    phase = Phase.preGame;
    spreadsOnTable = [];
    winner = null;
    winCondition = null;
    hasDrawnThisTurn = false;
    pot = 0;
    highestBet = 0;
  }

  /// Antes are collected once per round; an initial-tonk redeal keeps the pot.
  /// (The JS version re-collected antes on redeal and dropped the first pot.)
  void _collectAntesAndDeal() {
    collectAntes();
    while (true) {
      deal();
      phase = Phase.initialTonkCheck;
      final withTonk = checkInitialTonk();

      if (withTonk.length > 1) {
        _emit(InitialTonkDraw(withTonk));
        for (final p in players) {
          p.reset();
        }
        _deck = _deckFactory(random);
        continue;
      }

      if (withTonk.length == 1) {
        _endRound(withTonk.single, WinCondition.initialTonk);
      } else {
        phase = Phase.startOfTurn;
        _emit(TurnStart(currentPlayer));
      }
      return;
    }
  }

  void deal() {
    final count = getCardsPerPlayer(players.length);
    for (var i = 0; i < count; i++) {
      for (final p in players) {
        final card = deck.draw();
        if (card != null) p.addCard(card);
      }
    }
    final firstDiscard = deck.draw();
    if (firstDiscard != null) deck.discard(firstDiscard);
    _emit(CardsDealt(count));
  }

  List<Player> checkInitialTonk() => [
    for (final p in players)
      if (hasInitialTonk(p.calculatePoints())) p,
  ];

  // ---------------------------------------------------------------------
  // Turn actions
  // ---------------------------------------------------------------------

  Player get currentPlayer => players[currentPlayerIndex];

  bool get isHumanTurn => currentPlayer.isHuman;

  /// Draws from the stock. An empty stock ends the round (lowest points wins)
  /// and returns null.
  Card? drawFromDeck() {
    _requirePhase({Phase.draw}, 'Cannot draw - not in draw phase');
    final card = deck.draw();
    if (card == null) {
      endGameStockEmpty();
      return null;
    }
    _afterDraw(card, DrawSource.deck);
    return card;
  }

  Card? drawFromDiscard() {
    _requirePhase({Phase.draw}, 'Cannot draw - not in draw phase');
    final card = deck.drawFromDiscard();
    if (card != null) _afterDraw(card, DrawSource.discard);
    return card;
  }

  void _afterDraw(Card card, DrawSource source) {
    currentPlayer.addCard(card);
    hasDrawnThisTurn = true;
    phase = Phase.action;
    _emit(CardDrawn(currentPlayer, source, card));
  }

  /// Players still in the round (not folded).
  List<Player> get activePlayers => players.where((p) => p.isActive).toList();

  /// Lowest points among players still in the round wins.
  void endGameStockEmpty() {
    final active = activePlayers;
    var lowest = active.first;
    for (final p in active) {
      if (p.calculatePoints() < lowest.calculatePoints()) lowest = p;
    }
    _endRound(lowest, WinCondition.stockEmpty);
  }

  /// [player] passed on a raise: they sit out the rest of the round and can't
  /// win it. If only one player is left in, that player wins.
  void fold(Player player) {
    if (isGameOver) throw const GameRuleException('The round is over');
    if (player.hasFolded) return;
    player.hasFolded = true;
    _emit(Folded(player));

    final active = activePlayers;
    if (active.length == 1) {
      _endRound(active.single, WinCondition.allFolded);
    } else if (identical(player, currentPlayer)) {
      endTurn();
    }
  }

  /// Allowed at start of turn (before drawing) and in the action phase.
  Spread laySpread(List<Card> cards) {
    _requirePhase({
      Phase.action,
      Phase.startOfTurn,
    }, 'Cannot lay spread - not in valid phase');
    final validation = Spread.validate(cards);
    if (!validation.valid) throw const GameRuleException('Invalid spread');

    final player = currentPlayer;
    if (!cards.every(player.hasCard)) {
      throw const GameRuleException('Card not in player hand');
    }
    player.removeCards(cards);
    final spread = Spread(cards, validation.type!, player);
    spreadsOnTable.add(spread);
    player.addSpread(spread);
    _emit(SpreadLaid(player, spread));

    _checkTonk(player);
    return spread;
  }

  void proceedToDraw() {
    _requirePhase({
      Phase.startOfTurn,
    }, 'Can only proceed to draw from start of turn');
    phase = Phase.draw;
    _emit(const PhaseChanged(Phase.draw));
  }

  void hitSpread(Card card, Spread spread) {
    _requirePhase({
      Phase.action,
      Phase.startOfTurn,
    }, 'Cannot hit spread - not in valid phase');
    if (!spread.canAddCard(card)) {
      throw const GameRuleException('Cannot add this card to the spread');
    }
    final player = currentPlayer;
    if (player.removeCard(card) == null) {
      throw const GameRuleException('Card not in player hand');
    }
    spread.addCard(card);
    _emit(SpreadHit(player, card, spread));

    _checkTonk(player);
  }

  /// Discards and ends the turn.
  void discard(Card card) {
    _requirePhase({Phase.action}, 'Cannot discard - not in action phase');
    final player = currentPlayer;
    final removed = player.removeCard(card);
    if (removed == null) {
      throw const GameRuleException('Card not in player hand');
    }
    deck.discard(removed);
    _emit(CardDiscarded(player, removed));

    if (_checkTonk(player)) return;
    endTurn();
  }

  /// Knock/drop at start of turn. The knocker wins only with strictly the
  /// lowest points; otherwise the lowest other player catches them.
  void knock() {
    _requirePhase({
      Phase.startOfTurn,
    }, 'Can only knock at the start of your turn');
    final knocker = currentPlayer;
    final knockerPoints = knocker.calculatePoints();

    Player? lowestOther;
    var lowestOtherPoints = 1 << 30;
    for (final p in players) {
      if (identical(p, knocker) || p.hasFolded) continue;
      final points = p.calculatePoints();
      if (points < lowestOtherPoints) {
        lowestOtherPoints = points;
        lowestOther = p;
      }
    }

    final knockerWins = knockerPoints < lowestOtherPoints;
    final roundWinner = knockerWins ? knocker : lowestOther!;
    winner = roundWinner;
    winCondition = knockerWins ? WinCondition.knock : WinCondition.caught;
    phase = Phase.gameOver;
    _emit(Knocked(knocker, roundWinner));
    _emit(GameOver(roundWinner, winCondition!, knocker: knocker));
  }

  /// Passes play to the next player still in the round.
  void endTurn() {
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    } while (currentPlayer.hasFolded);
    hasDrawnThisTurn = false;
    phase = Phase.startOfTurn;
    _emit(TurnEnd(currentPlayer));
    _emit(TurnStart(currentPlayer));
  }

  bool _checkTonk(Player player) {
    if (!player.hasEmptyHand()) return false;
    _endRound(player, WinCondition.tonk);
    return true;
  }

  void _endRound(Player roundWinner, WinCondition condition) {
    winner = roundWinner;
    winCondition = condition;
    phase = Phase.gameOver;
    _emit(GameOver(roundWinner, condition));
  }

  void _requirePhase(Set<Phase> allowed, String message) {
    if (!allowed.contains(phase)) throw GameRuleException(message);
  }

  bool get isGameOver => phase == Phase.gameOver;

  Card? get topDiscard => deck.topDiscard;

  int get deckCount => deck.cardsRemaining;

  bool get isStockEmpty => deck.isEmpty;

  // ---------------------------------------------------------------------
  // Scoring
  // ---------------------------------------------------------------------

  List<({Player player, int points, int cardCount, int matchScore})>
  getScores() => [
    for (final p in players)
      (
        player: p,
        points: p.calculatePoints(),
        cardCount: p.cardCount,
        matchScore: matchScores[p.id] ?? 0,
      ),
  ];

  List<({Player player, int score})> getMatchScores() => [
    for (final p in players) (player: p, score: matchScores[p.id] ?? 0),
  ];

  /// Adds each loser's hand points to their match score.
  List<RoundLoss> applyRoundScoring() {
    final losers = <RoundLoss>[];
    for (final p in players) {
      if (identical(p, winner)) continue;
      final points = p.calculatePoints();
      final total = (matchScores[p.id] ?? 0) + points;
      matchScores[p.id] = total;
      losers.add((player: p, pointsAdded: points, newTotal: total));
    }
    return losers;
  }

  /// When anyone reaches the limit, the lowest match score wins the match.
  bool checkMatchEnd() {
    if (!players.any((p) => (matchScores[p.id] ?? 0) >= pointLimit)) {
      return false;
    }
    var best = players.first;
    for (final p in players) {
      if ((matchScores[p.id] ?? 0) < (matchScores[best.id] ?? 0)) best = p;
    }
    matchWinner = best;
    return true;
  }

  /// Round-end bookkeeping in the order the JS UI runs it: award the pot,
  /// score losers, then check for match end.
  RoundSettlement settleRound() {
    final w = winner;
    if (w == null || !isGameOver) {
      throw const GameRuleException('Round is not over');
    }
    final potWinnings = awardPot(w);
    final losers = applyRoundScoring();
    return (
      potWinnings: potWinnings,
      losers: losers,
      matchEnded: checkMatchEnd(),
    );
  }

  // ---------------------------------------------------------------------
  // Betting
  // ---------------------------------------------------------------------

  void collectAntes() {
    pot = 0;
    highestBet = Betting.anteAmount;
    for (final p in players) {
      if (p.isEliminated) continue;
      p.resetBet();
      pot += p.bet(Betting.anteAmount);
    }
    _emit(AntesCollected(pot: pot, ante: Betting.anteAmount));
  }

  int placeBet(Player player, int amount) {
    if (player.isEliminated || player.hasFolded) {
      throw const GameRuleException('This player is out and cannot bet');
    }
    final actual = player.bet(amount);
    pot += actual;
    if (player.currentBet > highestBet) highestBet = player.currentBet;
    _emit(BetPlaced(player, actual, pot));
    return actual;
  }

  int awardPot(Player roundWinner) {
    final winnings = pot;
    roundWinner.receiveChips(winnings);
    pot = 0;
    _emit(PotAwarded(roundWinner, winnings));
    return winnings;
  }

  void resetBetting() {
    pot = 0;
    highestBet = 0;
    for (final p in players) {
      p.resetBet();
    }
  }

  bool canPlayerRaise(int amount) =>
      players.where((p) => p.isHuman).any((p) => p.canAfford(amount));

  // ---------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------

  void addListener(GameListener listener) => _listeners.add(listener);

  void removeListener(GameListener listener) => _listeners.remove(listener);

  void _emit(GameEvent event) {
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }

  // ---------------------------------------------------------------------
  // Persistence (tonk_game_state)
  // ---------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'version': 1,
    'deck': deck.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.value,
    'spreadsOnTable': spreadsOnTable.map((s) => s.toJson()).toList(),
    'winner': winner?.id,
    'winCondition': winCondition?.value,
    'hasDrawnThisTurn': hasDrawnThisTurn,
    'matchScores': matchScores,
    'pointLimit': pointLimit,
    'matchWinner': matchWinner?.id,
    'roundNumber': roundNumber,
    'pot': pot,
    'highestBet': highestBet,
  };

  /// Restores a saved game. Listeners are not restored.
  factory Game.fromJson(Map<String, dynamic> json, {Random? random}) {
    final game = Game(random: random);

    game.players = [
      for (final raw in json['players'] as List)
        _playerFromJson(raw as Map<String, dynamic>, game.random),
    ];
    final byId = {for (final p in game.players) p.id: p};
    Player? lookup(String? id) => id == null ? null : byId[id];

    game.spreadsOnTable = [
      for (final raw in json['spreadsOnTable'] as List)
        Spread.fromJson(raw as Map<String, dynamic>, lookup),
    ];
    final spreadsById = {for (final s in game.spreadsOnTable) s.id: s};
    for (final raw in json['players'] as List) {
      final map = raw as Map<String, dynamic>;
      byId[map['id']]!.spreads = [
        for (final id in map['spreadIds'] as List) ?spreadsById[id],
      ];
    }

    final winCondition = json['winCondition'] as String?;
    game
      .._deck = Deck.fromJson(json['deck'] as Map<String, dynamic>, game.random)
      ..currentPlayerIndex = json['currentPlayerIndex'] as int
      ..phase = Phase.fromValue(json['phase'] as String)
      ..winner = lookup(json['winner'] as String?)
      ..winCondition = winCondition == null
          ? null
          : WinCondition.fromValue(winCondition)
      ..hasDrawnThisTurn = json['hasDrawnThisTurn'] as bool
      ..matchScores = (json['matchScores'] as Map).map(
        (k, v) => MapEntry(k as String, v as int),
      )
      ..pointLimit = json['pointLimit'] as int
      ..matchWinner = lookup(json['matchWinner'] as String?)
      ..roundNumber = json['roundNumber'] as int
      ..pot = json['pot'] as int
      ..highestBet = json['highestBet'] as int;
    return game;
  }

  static Player _playerFromJson(Map<String, dynamic> json, Random random) {
    final name = json['name'] as String;
    final id = json['id'] as String;
    final player = json['isComputer'] == true
        ? ComputerPlayer(
            name,
            id: id,
            style: json['style'] == null
                ? const AiStyle()
                : AiStyle.fromJson(json['style'] as Map<String, dynamic>),
            characterId: json['characterId'] as String?,
            random: random,
          )
        : Player(name, id: id, isHuman: json['isHuman'] as bool);
    return player..restoreFromJson(json);
  }
}
