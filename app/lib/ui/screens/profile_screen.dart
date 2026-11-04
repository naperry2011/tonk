import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../meta/progression.dart';
import '../theme.dart';
import '../themes.dart';
import '../widgets/lofi_backdrop.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final profile = services.profile;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final p = profile.profile;
        final s = p.stats;
        final theme = Theme.of(context);
        final heading = theme.textTheme.titleLarge?.copyWith(
          fontSize: 24,
          color: TonkColors.rose,
          fontWeight: FontWeight.w700,
        );
        final winRate = s.roundsPlayed == 0
            ? '-'
            : '${(100 * s.roundsWon / s.roundsPlayed).round()}%';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your table record'),
            backgroundColor: Colors.transparent,
          ),
          body: LofiBackdrop(
            table: TableTheme.byId(services.settings.tableTheme),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: TonkColors.rose,
                      child: Text(
                        '${profile.level}',
                        style: const TextStyle(
                          color: TonkColors.dusk,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${profile.level}  ·  ${p.xp} XP',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: profile.levelProgress,
                              minHeight: 8,
                              backgroundColor: TonkColors.glassBorder,
                              color: TonkColors.rose,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.xpToNextLevel} XP to level ${profile.level + 1}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 104,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Stat('Bankroll', '${p.bankroll}', Icons.toll),
                    _Stat(
                      'Win streak',
                      '${s.winStreak}',
                      Icons.local_fire_department,
                    ),
                    _Stat('Best streak', '${s.bestWinStreak}', Icons.whatshot),
                    _Stat(
                      'Daily streak',
                      '${profile.currentDailyStreak}',
                      Icons.today,
                    ),
                    _Stat(
                      'Rounds won',
                      '${s.roundsWon}/${s.roundsPlayed}',
                      Icons.style,
                    ),
                    _Stat('Win rate', winRate, Icons.percent),
                    _Stat(
                      'Matches won',
                      '${s.matchesWon}/${s.matchesPlayed}',
                      Icons.emoji_events,
                    ),
                    _Stat('Tonks', '${s.tonks}', Icons.celebration),
                    _Stat('Knock wins', '${s.knockWins}', Icons.front_hand),
                    _Stat('Caught knockers', '${s.catches}', Icons.visibility),
                    _Stat(
                      'Got caught',
                      '${s.timesCaught}',
                      Icons.sentiment_dissatisfied,
                    ),
                    _Stat('Spreads laid', '${s.spreadsLaid}', Icons.view_week),
                    _Stat('Biggest pot', '${s.biggestPot}', Icons.savings),
                    _Stat('Folds', '${s.folds}', Icons.do_not_disturb_on),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Achievements  ${p.achievements.length}/${achievements.length}',
                  style: heading,
                ),
                const SizedBox(height: 8),
                for (final a in achievements)
                  _Row(
                    icon: p.achievements.contains(a.id)
                        ? Icons.emoji_events
                        : Icons.lock_outline,
                    done: p.achievements.contains(a.id),
                    title: a.title,
                    subtitle: a.description,
                  ),
                const SizedBox(height: 24),
                Text('Unlock track', style: heading),
                const SizedBox(height: 8),
                for (final u in unlockTrack)
                  _Row(
                    icon: profile.level >= u.level
                        ? Icons.lock_open
                        : Icons.lock_outline,
                    done: profile.level >= u.level,
                    title: 'Level ${u.level}',
                    subtitle: u.label,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: TonkColors.rose),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: TonkColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.done,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final bool done;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: done ? 1 : 0.5,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(
          icon,
          color: done ? TonkColors.rose : TonkColors.textMuted,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
