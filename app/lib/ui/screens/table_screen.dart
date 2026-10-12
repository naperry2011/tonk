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
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
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
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: table.decoration,
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
    return Stack(
      children: [
        Column(
          children: [
            _TopBar(controller: c, onQuit: _confirmQuit),
            _OpponentsRow(controller: c, deck: deck),
            Expanded(
              child: _Center(controller: c, deck: deck),
            ),
            _StatusLine(controller: c),
            if (c.pendingRaise case final raise?)
              _RaisePrompt(controller: c, raise: raise)
            else if (c.human.hasFolded && !c.game.isGameOver)
              const _FoldedBar()
            else
              _ActionBar(controller: c),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: c.human.hasFolded ? 0.4 : 1,
              child: HandView(
                cards: c.human.hand,
                selected: c.selected,
                onTap: _tapCard,
                onReorder: c.reorderHand,
              ),
            ),
          ],
        ),
        if (summary != null)
          Positioned.fill(
            child: DealIn(
              key: ValueKey('panel-${c.game.roundNumber}'),
              from: const Offset(0, 0.12),
              duration: const Duration(milliseconds: 380),
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
      final color = c.characterFor(summary.winner)?.color ?? TonkColors.gold;
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

  final GameController controller;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final human = controller.human;
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave table',
            onPressed: onQuit,
            icon: const Icon(Icons.close),
          ),
          Text(
            controller.mode == MatchMode.daily
                ? 'Daily'
                : 'Round ${game.roundNumber}',
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
                  _Pill(icon: Icons.savings_outlined, label: 'Pot ${game.pot}'),
                  const SizedBox(width: 8),
                  _Pill(icon: Icons.toll, label: '${human.chips}'),
                  if (controller.mode == MatchMode.match) ...[
                    const SizedBox(width: 8),
                    _Pill(
                      icon: Icons.scoreboard_outlined,
                      label:
                          '${game.matchScores[human.id] ?? 0}/${game.pointLimit}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              label,
              key: ValueKey(label),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentsRow extends StatelessWidget {
  const _OpponentsRow({required this.controller, required this.deck});

  final GameController controller;
  final DeckTheme deck;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in controller.opponents)
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: p.hasFolded && !game.isGameOver ? 0.45 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: OpponentSeat(
                    player: p,
                    character: controller.characterFor(p),
                    matchScore: game.matchScores[p.id] ?? 0,
                    isActive:
                        !game.isGameOver && identical(game.currentPlayer, p),
                    lastAction: controller.lastAction[p.id],
                    speech: controller.speech[p.id],
                    deckTheme: deck,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Center extends StatelessWidget {
  const _Center({required this.controller, required this.deck});

  final GameController controller;
  final DeckTheme deck;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final canDraw = controller.canDraw;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final top = game.topDiscard;
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                game.deckCount > 0
                    ? PlayingCard(
                        width: 62,
                        deckTheme: deck,
                        highlighted: canDraw,
                        onTap: canDraw ? controller.drawFromDeck : null,
                      )
                    : const _EmptyPile(),
                const SizedBox(height: 4),
                Text('Stock ${game.deckCount}', style: labelStyle),
              ],
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                SizedBox(
                  width: 62,
                  height: 62 * 1.42,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween(begin: 1.35, end: 1.0).animate(
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
                            width: 62,
                            highlighted: canDraw,
                            onTap: canDraw ? controller.drawFromDiscard : null,
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Discard', style: labelStyle),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: game.spreadsOnTable.isEmpty
              ? Center(
                  child: Text(
                    'No spreads yet',
                    style: labelStyle?.copyWith(color: Colors.white38),
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
                        DealIn(
                          key: ValueKey(spread.id),
                          from: const Offset(0, 0.4),
                          child: _SpreadView(
                            controller: controller,
                            spread: spread,
                          ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 2),
      ),
    );
  }
}

class _SpreadView extends StatelessWidget {
  const _SpreadView({required this.controller, required this.spread});

  final GameController controller;
  final Spread spread;

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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: canHit ? TonkColors.highlight : Colors.transparent,
              width: 2,
            ),
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
                      child: PlayingCard(card: card, width: 38),
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
    final human = controller.human;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.status ?? '',
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            'Hand ${human.calculatePoints()}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final accent = Theme.of(context).colorScheme.primary;
    final canRaiseAny = Betting.raiseOptions.any(c.canRaise);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (c.canKnock) ...[
              Expanded(
                child: FilledButton(
                  onPressed: c.knock,
                  style: FilledButton.styleFrom(
                    backgroundColor: TonkColors.cardRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('KNOCK'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton.tonal(
                onPressed: c.canLaySelected ? c.laySelected : null,
                child: const Text('Spread'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: c.canDiscard ? c.discardSelected : null,
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<int>(
              tooltip: 'Raise',
              enabled: canRaiseAny,
              onSelected: c.raise,
              itemBuilder: (context) => [
                for (final amount in Betting.raiseOptions)
                  PopupMenuItem(
                    value: amount,
                    enabled: c.canRaise(amount),
                    child: Text('Raise $amount'),
                  ),
              ],
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: canRaiseAny ? accent : Colors.white24,
                  ),
                ),
                child: Text(
                  'Raise',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: canRaiseAny ? accent : Colors.white38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.white60),
        ),
      ),
    );
  }
}
