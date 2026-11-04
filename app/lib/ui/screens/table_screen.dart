import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Card;

import '../../app_services.dart';
import '../../data/settings_store.dart';
import '../../engine/engine.dart';
import '../../meta/match_setup.dart';
import '../../state/game_controller.dart';
import '../table_feel.dart';
import '../theme.dart';
import '../themes.dart';
import '../widgets/celebration.dart';
import '../widgets/hand_view.dart';
import '../widgets/lofi_backdrop.dart';
import '../widgets/opponent_seat.dart';
import '../widgets/playing_card.dart';
import '../widgets/round_end_panel.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({
    super.key,
    required this.services,
    required this.controller,
  });

  final AppServices services;

  /// The match or daily table being played.
  final GameController controller;

  SettingsController get settings => services.settings;
  TableFeel? get feel => services.feel;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  GameController get c => widget.controller;

  // Where things are on screen, for the spread slide animations.
  final GlobalKey _layerKey = GlobalKey();
  final Map<String, GlobalKey> _handKeys = {};
  final Map<String, GlobalKey> _trayKeys = {};
  final Map<String, GlobalKey> _seatKeys = {};

  final List<_Flight> _flights = [];

  /// Card ids still flying into a spread (hidden in the tray until they land).
  final Set<String> _inFlight = {};
  StreamSubscription<GameEvent>? _events;
  int _nextFlight = 0;

  GlobalKey _trayKey(String spreadId, String cardId) =>
      _trayKeys.putIfAbsent('$spreadId-$cardId', GlobalKey.new);

  Rect? _rectOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    final layer = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || layer == null || !box.attached || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero, ancestor: layer) & box.size;
  }

  /// A small card-sized rect at an opponent's avatar.
  Rect? _seatRect(Player player) {
    final seat = _rectOf(_seatKeys[player.id]);
    if (seat == null) return null;
    return Rect.fromCenter(
      center: seat.topCenter + const Offset(0, 24),
      width: 30,
      height: 30 * 1.42,
    );
  }

  void _onGameEvent(GameEvent event) {
    final (Player? player, List<Card> cards, Spread? spread) = switch (event) {
      SpreadLaid(:final player, :final spread) => (
        player,
        List.of(spread.cards),
        spread,
      ),
      SpreadHit(:final player, :final card, :final spread) => (
        player,
        [card],
        spread,
      ),
      _ => (null, const [], null),
    };
    if (player == null || spread == null || !mounted) return;

    // The hand hasn't rebuilt yet, so the cards are still where they were.
    final starts = <String, Rect>{
      for (final card in cards)
        card.id: ?(player.isHuman
            ? _rectOf(_handKeys[card.id])
            : _seatRect(player)),
    };
    if (starts.isEmpty) return;
    setState(() => _inFlight.addAll(starts.keys));

    // Targets exist once the tray has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final flights = <_Flight>[];
      var delay = 0;
      for (final card in cards) {
        final from = starts[card.id];
        final to = _rectOf(_trayKeys['${spread.id}-${card.id}']);
        if (from == null || to == null) {
          _inFlight.remove(card.id);
          continue;
        }
        flights.add(
          _Flight(
            id: _nextFlight++,
            card: card,
            from: from,
            to: to,
            delay: Duration(milliseconds: delay),
          ),
        );
        delay += 70;
      }
      setState(() => _flights.addAll(flights));
    });
  }

  void _landed(_Flight flight) {
    if (!mounted) return;
    setState(() {
      _flights.remove(flight);
      _inFlight.remove(flight.card.id);
    });
  }

  void _nextRound(RoundSummary summary) {
    if (summary.isDaily) {
      Navigator.pop(context);
    } else if (!summary.matchEnded) {
      c.startNextRound();
    } else if (!startMatch(c, widget.services.profile, c.opponents.length)) {
      // Can't cover another buy-in: back home for a refill.
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
    widget.feel?.attach(c.events);
    _events = c.events.listen(_onGameEvent);
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    _events?.cancel();
    super.dispose();
  }

  void _onChange() {
    final error = c.error;
    if (error != null && mounted) {
      c.clearError();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 2)),
        );
    }
  }

  void _tapCard(Card card) {
    widget.feel?.tap();
    c.toggleSelect(card);
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the table?'),
        content: const Text(
          'Your match is saved. You can continue it from home.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if ((quit ?? false) && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([c, widget.settings]),
      builder: (context, _) {
        final settings = widget.settings;
        final table = TableTheme.byId(settings.tableTheme);
        final deck = DeckTheme.byId(settings.deckTheme);
        c.nickname = settings.nickname;
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(primary: table.accent),
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _confirmQuit();
            },
            child: Scaffold(
              body: LofiBackdrop(
                table: table,
                child: SafeArea(
                  child: c.hasGame
                      ? _buildTable(context, deck)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, DeckTheme deck) {
    final summary = c.roundSummary;
    final suggestion = c.suggestedSpread;
    return Stack(
      key: _layerKey,
      children: [
        Column(
          children: [
            _TopBar(controller: c, onQuit: _confirmQuit),
            _OpponentsRow(controller: c, seatKeys: _seatKeys),
            Expanded(
              child: _Center(
                controller: c,
                deck: deck,
                trayKey: _trayKey,
                inFlight: _inFlight,
              ),
            ),
            _StatusLine(controller: c),
            if (c.pendingRaise case final raise?)
              _RaisePrompt(controller: c, raise: raise)
            else if (c.human.hasFolded && !c.game.isGameOver)
              const _FoldedBar()
            else
              _ActionBar(controller: c),
            AnimatedOpacity(
              duration: TonkMotion.standard,
              opacity: c.human.hasFolded ? 0.4 : 1,
              child: HandView(
                cards: c.human.hand,
                selected: c.selected,
                onTap: _tapCard,
                onReorder: c.reorderHand,
                hinted: c.canLaySelected ? const {} : {...?suggestion?.cards},
                cardKeys: {
                  for (final card in c.human.hand)
                    card.id: _handKeys.putIfAbsent(card.id, GlobalKey.new),
                },
              ),
            ),
          ],
        ),
        // Table talk floats over the felt, under each speaker's seat.
        Positioned(
          top: _TopBar.height + OpponentSeat.height - 8,
          left: 8,
          right: 8,
          child: IgnorePointer(child: _SpeechRow(controller: c)),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                for (final flight in _flights)
                  _FlyingCard(
                    key: ValueKey(flight.id),
                    flight: flight,
                    onLanded: _landed,
                  ),
              ],
            ),
          ),
        ),
        if (summary != null)
          Positioned.fill(
            child: DealIn(
              key: ValueKey('panel-${c.game.roundNumber}'),
              from: const Offset(0, 0.08),
              duration: TonkMotion.slow,
              child: RoundEndPanel(
                controller: c,
                summary: summary,
                onNextRound: () => _nextRound(summary),
                onExit: () async {
                  final navigator = Navigator.of(context);
                  if (summary.matchEnded) await c.abandonMatch();
                  navigator.pop();
                },
              ),
            ),
          ),
        if (summary != null) ?_celebrationFor(summary),
      ],
    );
  }

  Widget? _celebrationFor(RoundSummary summary) {
    final key = ValueKey('party-${c.game.roundNumber}-${summary.matchEnded}');
    final tonk =
        summary.condition == WinCondition.tonk ||
        summary.condition == WinCondition.initialTonk;
    if (summary.isDaily && summary.winner.isHuman) {
      return Positioned.fill(
        child: Celebration(key: key, title: 'DAILY W'),
      );
    }
    if (summary.matchEnded && summary.matchWinner?.isHuman == true) {
      return Positioned.fill(
        child: Celebration(key: key, title: 'CHAMP'),
      );
    }
    if (tonk) {
      final color = c.characterFor(summary.winner)?.color ?? TonkColors.rose;
      return Positioned.fill(
        child: Celebration(key: key, title: 'TONK!', color: color),
      );
    }
    final rewards = summary.rewards;
    if (rewards != null && rewards.leveledUp) {
      return Positioned.fill(
        child: Celebration(key: key, title: 'LEVEL ${rewards.newLevel}'),
      );
    }
    return null;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onQuit});

  static const double height = 56;

  final GameController controller;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final human = c.human;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontFamily: TonkFonts.display,
      fontFeatures: const [FontFeature.liningFigures()],
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      fontSize: 21,
    );
    final score = c.mode == MatchMode.match
        ? '  ·  ${game.matchScores[human.id] ?? 0}/${game.pointLimit}'
        : '';
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Leave table',
              onPressed: onQuit,
              icon: const Icon(Icons.close),
            ),
            Text(
              c.mode == MatchMode.daily ? 'Daily' : 'Round ${game.roundNumber}',
              style: style,
            ),
            const SizedBox(width: 8),
            // Scales down on narrow phones instead of overflowing.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    _Pill(icon: Icons.savings_outlined, label: '${game.pot}'),
                    const SizedBox(width: 6),
                    _RaiseChip(controller: c),
                    const SizedBox(width: 6),
                    _Pill(icon: Icons.toll, label: '${human.chips}$score'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaiseChip extends StatelessWidget {
  const _RaiseChip({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final accent = Theme.of(context).colorScheme.primary;
    final enabled = Betting.raiseOptions.any(c.canRaise);
    return PopupMenuButton<int>(
      tooltip: 'Raise',
      enabled: enabled,
      onSelected: c.raise,
      itemBuilder: (context) => [
        for (final amount in Betting.raiseOptions)
          PopupMenuItem(
            value: amount,
            enabled: c.canRaise(amount),
            child: Text('Raise $amount'),
          ),
      ],
      child: AnimatedContainer(
        duration: TonkMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: glassPanel(
          radius: 20,
          border: enabled ? accent.withValues(alpha: 0.7) : null,
        ),
        child: Text(
          'Raise',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: enabled ? accent : TonkColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: glassPanel(radius: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: TonkMotion.standard,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              label,
              key: ValueKey(label),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: TonkColors.textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentsRow extends StatelessWidget {
  const _OpponentsRow({required this.controller, required this.seatKeys});

  final GameController controller;
  final Map<String, GlobalKey> seatKeys;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final p in controller.opponents)
            Expanded(
              child: AnimatedOpacity(
                duration: TonkMotion.standard,
                opacity: p.hasFolded && !game.isGameOver ? 0.4 : 1,
                child: OpponentSeat(
                  key: seatKeys.putIfAbsent(p.id, GlobalKey.new),
                  player: p,
                  character: controller.characterFor(p),
                  matchScore: game.matchScores[p.id] ?? 0,
                  isActive:
                      !game.isGameOver && identical(game.currentPlayer, p),
                  lastAction: controller.lastAction[p.id],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpeechRow extends StatelessWidget {
  const _SpeechRow({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in controller.opponents)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: TonkMotion.standard,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (controller.speech[p.id]) {
                  final text? => SpeechBubble(key: ValueKey(text), text: text),
                  null => const SizedBox.shrink(),
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Center extends StatelessWidget {
  const _Center({
    required this.controller,
    required this.deck,
    required this.trayKey,
    required this.inFlight,
  });

  final GameController controller;
  final DeckTheme deck;
  final GlobalKey Function(String spreadId, String cardId) trayKey;
  final Set<String> inFlight;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final canDraw = controller.canDraw;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: TonkColors.textMuted,
      letterSpacing: 1.2,
    );
    final top = game.topDiscard;
    final piles = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            game.deckCount > 0
                ? PlayingCard(
                    width: 66,
                    deckTheme: deck,
                    highlighted: canDraw,
                    onTap: canDraw ? controller.drawFromDeck : null,
                  )
                : const _EmptyPile(),
            const SizedBox(height: 6),
            Text('Stock ${game.deckCount}', style: labelStyle),
          ],
        ),
        const SizedBox(width: 26),
        Column(
          children: [
            SizedBox(
              width: 66,
              height: 66 * 1.42,
              child: AnimatedSwitcher(
                duration: TonkMotion.standard,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween(begin: 1.15, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: top == null
                    ? const _EmptyPile(key: ValueKey('empty'))
                    : PlayingCard(
                        key: ValueKey(
                          '${top.id}-${game.deck.discardPile.length}',
                        ),
                        card: top,
                        width: 66,
                        highlighted: canDraw,
                        onTap: canDraw ? controller.drawFromDiscard : null,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Discard', style: labelStyle),
          ],
        ),
      ],
    );

    return Column(
      children: [
        // Piles sit in the middle of the felt, away from the seats.
        const Spacer(),
        piles,
        const SizedBox(height: 18),
        Expanded(
          flex: 2,
          child: game.spreadsOnTable.isEmpty
              ? Align(
                  alignment: const Alignment(0, -0.5),
                  child: Text(
                    'No spreads yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: TonkFonts.display,
                      fontFeatures: const [FontFeature.liningFigures()],
                      fontStyle: FontStyle.italic,
                      color: TonkColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final spread in game.spreadsOnTable)
                        _SpreadView(
                          key: ValueKey(spread.id),
                          controller: controller,
                          spread: spread,
                          trayKey: trayKey,
                          inFlight: inFlight,
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyPile extends StatelessWidget {
  const _EmptyPile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62 * 1.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TonkColors.glassBorder, width: 1.5),
      ),
    );
  }
}

class _SpreadView extends StatelessWidget {
  const _SpreadView({
    super.key,
    required this.controller,
    required this.spread,
    required this.trayKey,
    required this.inFlight,
  });

  final GameController controller;
  final Spread spread;
  final GlobalKey Function(String spreadId, String cardId) trayKey;
  final Set<String> inFlight;

  @override
  Widget build(BuildContext context) {
    final canHit = controller.canHit(spread);
    final owner = spread.owner;
    final ownerColor = owner == null
        ? null
        : controller.characterFor(owner)?.color;
    return Semantics(
      button: canHit,
      label: 'Spread ${spread.description}${canHit ? ', tap to hit' : ''}',
      child: GestureDetector(
        onTap: canHit ? () => controller.hit(spread) : null,
        child: AnimatedContainer(
          duration: TonkMotion.quick,
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
          decoration: glassPanel(
            radius: 14,
            border: canHit ? TonkColors.highlight : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                owner == null || owner.isHuman ? 'Yours' : owner.name,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: ownerColor),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final card in spread.cards)
                    Align(
                      widthFactor: 0.62,
                      child: Opacity(
                        opacity: inFlight.contains(card.id) ? 0 : 1,
                        child: PlayingCard(
                          key: trayKey(spread.id, card.id),
                          card: card,
                          width: 38,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: TonkMotion.quick,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                controller.status ?? '',
                key: ValueKey(controller.status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: TonkColors.textSoft),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: glassPanel(radius: 14),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'hand ',
                    style: TextStyle(fontSize: 12, color: TonkColors.textMuted),
                  ),
                  TextSpan(
                    text: '${controller.human.calculatePoints()}',
                    style: TextStyle(
                      fontFamily: TonkFonts.display,
                      fontFeatures: const [FontFeature.liningFigures()],
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows only the moves that make sense right now.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final children = <Widget>[];

    Widget hint(String text) => Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: TonkFonts.display,
          fontFeatures: const [FontFeature.liningFigures()],
          fontStyle: FontStyle.italic,
          color: TonkColors.textMuted,
        ),
      ),
    );

    if (!c.isHumanTurn) {
      // Nothing to do while the table plays.
    } else if (c.game.phase == Phase.startOfTurn) {
      children.add(
        FilledButton(
          onPressed: c.knock,
          style: FilledButton.styleFrom(
            backgroundColor: TonkColors.cardRed,
            foregroundColor: TonkColors.cardFace,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            textStyle: const TextStyle(
              fontFamily: TonkFonts.body,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          child: const Text('KNOCK'),
        ),
      );
      if (c.canLaySelected) {
        children.addAll([const SizedBox(width: 10), _spreadButton(c)]);
      } else if (c.suggestedSpread case final spread?) {
        children.addAll([
          const SizedBox(width: 10),
          Expanded(child: _suggestButton(c, spread)),
        ]);
      } else {
        children.add(hint('or tap a pile to draw'));
      }
    } else {
      if (c.canLaySelected) {
        children.add(Expanded(child: _spreadButton(c)));
      } else if (c.suggestedSpread case final spread?) {
        children.add(Expanded(child: _suggestButton(c, spread)));
      }
      if (c.canDiscard) {
        if (children.isNotEmpty) children.add(const SizedBox(width: 10));
        children.add(
          Expanded(
            child: FilledButton(
              onPressed: c.discardSelected,
              child: Text('Discard ${c.selected.single}'),
            ),
          ),
        );
      }
      if (children.isEmpty) {
        children.add(
          hint(
            c.selected.length > 1
                ? 'Not a spread yet'
                : 'Pick a card to discard',
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 50,
        child: AnimatedSwitcher(
          duration: TonkMotion.quick,
          child: Row(
            key: ValueKey(
              '${c.game.phase}-${c.selected.length}-${c.canLaySelected}-${c.isHumanTurn}',
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  /// One tap to lay the best spread in hand, e.g. "Spread 7s" or "Spread 4-6♥".
  static Widget _suggestButton(GameController c, SpreadCandidate spread) {
    final cards = spread.cards;
    final label = spread.type == SpreadType.book
        ? '${cards.first.rank}s'
        : '${cards.first.rank}-${cards.last.rank}${cards.first.suit.symbol}';
    return FilledButton.icon(
      onPressed: c.laySuggested,
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: Text('Spread $label', overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: TonkColors.gold,
        foregroundColor: TonkColors.dusk,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  static Widget _spreadButton(GameController c) => FilledButton.tonal(
    onPressed: c.laySelected,
    style: FilledButton.styleFrom(
      backgroundColor: TonkColors.elevated,
      foregroundColor: TonkColors.text,
    ),
    child: const Text('Spread'),
  );
}

class _RaisePrompt extends StatelessWidget {
  const _RaisePrompt({required this.controller, required this.raise});

  final GameController controller;
  final PendingRaise raise;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final allIn = raise.toCall < raise.amount;
    return DealIn(
      key: ValueKey('raise-${raise.raiser.id}-${raise.amount}'),
      from: const Offset(0, 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.answerRaise(call: false),
                  child: const Text('Fold'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => controller.answerRaise(call: true),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: Text(
                    allIn ? 'All in (${raise.toCall})' : 'Call ${raise.toCall}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoldedBar extends StatelessWidget {
  const _FoldedBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
        child: Text(
          "You're out this round",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: TonkFonts.display,
            fontFeatures: const [FontFeature.liningFigures()],
            fontStyle: FontStyle.italic,
            color: TonkColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// One card sliding from a hand or seat into a spread tray.
class _Flight {
  _Flight({
    required this.id,
    required this.card,
    required this.from,
    required this.to,
    required this.delay,
  });

  final int id;
  final Card card;
  final Rect from;
  final Rect to;
  final Duration delay;
}

class _FlyingCard extends StatelessWidget {
  const _FlyingCard({super.key, required this.flight, required this.onLanded});

  static const _travel = Duration(milliseconds: 520);

  final _Flight flight;
  final void Function(_Flight) onLanded;

  @override
  Widget build(BuildContext context) {
    final total = flight.delay + _travel;
    final start = flight.delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeInOutCubic),
      onEnd: () => onLanded(flight),
      builder: (context, t, _) {
        final rect = Rect.lerp(flight.from, flight.to, t)!;
        // A gentle arc up and over the felt.
        final lift = sin(pi * t) * 36;
        return Positioned(
          left: rect.left,
          top: rect.top - lift,
          width: rect.width,
          height: rect.height,
          child: Transform.rotate(
            angle: sin(pi * t) * 0.08,
            child: PlayingCard(card: flight.card, width: rect.width),
          ),
        );
      },
    );
  }
}
