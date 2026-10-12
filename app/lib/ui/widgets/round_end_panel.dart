import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';
import '../../meta/profile_controller.dart';
import '../../state/game_controller.dart';
import 'playing_card.dart';

/// Shown over the table when a round ends.
class RoundEndPanel extends StatelessWidget {
  const RoundEndPanel({
    super.key,
    required this.controller,
    required this.summary,
    required this.onNextRound,
    required this.onExit,
  });

  final GameController controller;
  final RoundSummary summary;
  final VoidCallback onNextRound;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final humanWon = summary.winner.isHuman;
    final matchWinner = summary.matchWinner;

    final title = summary.isDaily
        ? (humanWon ? 'DAILY WON' : 'DAILY DONE')
        : summary.matchEnded
        ? (matchWinner!.isHuman ? 'MATCH WON' : 'MATCH LOST')
        : summary.condition == WinCondition.tonk && humanWon
        ? 'TONK!'
        : humanWon
        ? 'YOU WIN THE ROUND'
        : '${summary.winner.name.toUpperCase()} TAKES IT';

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Material(
        color: const Color(0xF0121212),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent, width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _describe(summary),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (summary.potWinnings > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_name(summary.winner)} won the ${summary.potWinnings}-chip pot',
                    style: theme.textTheme.bodyMedium?.copyWith(color: accent),
                  ),
                ],
                const SizedBox(height: 16),
                for (final p in game.players)
                  _PlayerRow(
                    player: p,
                    isWinner: identical(p, summary.winner),
                    handPoints: summary.handPoints[p.id] ?? 0,
                    added: summary.pointsAdded[p.id] ?? 0,
                    matchScore: game.matchScores[p.id] ?? 0,
                  ),
                if (summary.rewards case final rewards?) ...[
                  const SizedBox(height: 12),
                  _RewardsView(rewards: rewards),
                ],
                const SizedBox(height: 16),
                if (summary.matchEnded && !summary.isDaily)
                  Text(
                    '${_name(matchWinner!)} ${matchWinner.isHuman ? 'win' : 'wins'} the match '
                    'with the lowest score.',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!summary.isDaily) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onExit,
                          child: Text(summary.matchEnded ? 'Home' : 'Quit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: summary.isDaily ? onExit : onNextRound,
                        child: Text(
                          summary.isDaily
                              ? 'Back home'
                              : summary.matchEnded
                              ? 'Run it back'
                              : 'Next round',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _name(Player p) => p.isHuman ? 'You' : p.name;

  static String _describe(RoundSummary s) {
    final winner = _name(s.winner);
    final knocker = s.knocker == null ? 'Someone' : _name(s.knocker!);
    return switch (s.condition) {
      WinCondition.tonk => '$winner went out with an empty hand.',
      WinCondition.initialTonk => '$winner got dealt 49-50. Initial Tonk!',
      WinCondition.knock => '$knocker knocked with the lowest hand.',
      WinCondition.caught => '$knocker knocked and got caught by $winner.',
      WinCondition.stockEmpty =>
        'The stock ran out. $winner had the lowest hand.',
      WinCondition.allFolded =>
        'Everyone else folded. $winner ${s.winner.isHuman ? 'take' : 'takes'} the pot.',
      WinCondition.initialTonkDraw => 'Redeal.',
    };
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.isWinner,
    required this.handPoints,
    required this.added,
    required this.matchScore,
  });

  final Player player;
  final bool isWinner;
  final int handPoints;
  final int added;
  final int matchScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.isHuman ? 'You' : player.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isWinner ? accent : null,
                  ),
                ),
                Text('$handPoints in hand', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final card in player.hand)
                  PlayingCard(card: card, width: 26),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              isWinner ? '$matchScore total' : '+$added  ($matchScore)',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP earned this round, plus level-ups, unlocks, and achievements.
class _RewardsView extends StatelessWidget {
  const _RewardsView({required this.rewards});

  final RoundRewards rewards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final small = theme.textTheme.labelMedium;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '+${rewards.xp} XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rewards.breakdown
                      .map((e) => '${e.label} ${e.xp}')
                      .join('  ·  '),
                  style: small?.copyWith(color: Colors.white60),
                ),
              ),
            ],
          ),
          if (rewards.bonusChips > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${rewards.bonusChips} chips to your bankroll',
                style: small,
              ),
            ),
          if (rewards.leveledUp)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'LEVEL ${rewards.newLevel}!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          for (final u in rewards.unlocks)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.lock_open, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Unlocked: ${u.label}', style: small)),
                ],
              ),
            ),
          for (final a in rewards.achievements)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Achievement: ${a.title}. ${a.description}',
                      style: small,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
