import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../meta/match_setup.dart';
import '../../meta/profile_controller.dart';
import '../../state/game_controller.dart';
import '../themes.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'table_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _opponents = 2;
  bool _hasMatchSave = false;
  bool _hasDailySave = false;

  AppServices get s => widget.services;
  ProfileController get profile => s.profile;

  @override
  void initState() {
    super.initState();
    _refreshSaves();
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimBonus());
  }

  void _claimBonus() {
    final bonus = profile.claimDailyBonus();
    if (bonus > 0 && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Daily bonus: +$bonus chips')));
    }
  }

  Future<void> _refreshSaves() async {
    final results = await Future.wait([
      s.match.hasSavedMatch(),
      s.daily.hasSavedMatch(),
    ]);
    if (mounted) {
      setState(() {
        _hasMatchSave = results[0];
        _hasDailySave = results[1];
      });
    }
  }

  Future<void> _openTable(GameController controller) async {
    // Don't let a home snackbar sit on top of the player's hand.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableScreen(services: s, controller: controller),
      ),
    );
    s.enforceUnlocks();
    await _refreshSaves();
  }

  Future<void> _continueMatch() async {
    if (await s.match.resume()) {
      if (mounted) await _openTable(s.match);
    } else {
      await _refreshSaves();
    }
  }

  Future<void> _newMatch() async {
    if (_hasMatchSave) {
      final forfeit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Forfeit your match?'),
          content: const Text(
            'Starting a new match ends the one in progress. '
            'Chips on that table are lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Forfeit'),
            ),
          ],
        ),
      );
      if (!(forfeit ?? false)) return;
      await s.match.abandonMatch();
    }
    if (!mounted) return;
    if (startMatch(s.match, profile, _opponents)) await _openTable(s.match);
  }

  Future<void> _playDaily() async {
    if (_hasDailySave && await s.daily.resume()) {
      if (mounted) await _openTable(s.daily);
      return;
    }
    final day = profile.today;
    s.daily.newDaily(day, dailyOpponents(s.roster, day));
    await _openTable(s.daily);
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([s.settings, profile]),
      builder: (context, _) {
        final table = TableTheme.byId(s.settings.tableTheme);
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: table.accent),
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.person_outline),
                onPressed: () => _push(ProfileScreen(services: s)),
              ),
              actions: [
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _push(SettingsScreen(services: s)),
                ),
              ],
            ),
            body: DecoratedBox(
              decoration: table.decoration,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildBody(context, table),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TableTheme table) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'TONK',
          style: theme.textTheme.displayLarge?.copyWith(
            color: table.accent,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
        ),
        Text(
          'Knock, spread, talk your talk.',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        _PlayerStrip(profile: profile),
        const SizedBox(height: 16),
        _DailyCard(
          profile: profile,
          inProgress: _hasDailySave,
          onPlay: _playDaily,
        ),
        const SizedBox(height: 24),
        if (_hasMatchSave) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _continueMatch,
              child: const Text('Continue match'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Opponents', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
          ],
          selected: {_opponents},
          onSelectionChanged: (sel) => setState(() => _opponents = sel.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: profile.canBuyIn
              ? (_hasMatchSave
                    ? OutlinedButton(
                        onPressed: _newMatch,
                        child: const Text('New match  ·  1,000 buy-in'),
                      )
                    : FilledButton(
                        onPressed: _newMatch,
                        child: const Text('Deal me in  ·  1,000 buy-in'),
                      ))
              : FilledButton.tonal(
                  onPressed: profile.refill,
                  child: const Text('Out of chips? Uncle Ray spots you 1,000'),
                ),
        ),
      ],
    );
  }
}

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({required this.profile});

  final ProfileController profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final streak = profile.profile.stats.winStreak;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent,
                child: Text(
                  '${profile.level}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${profile.level}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${profile.xpToNextLevel} XP to level ${profile.level + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0) ...[
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.deepOrangeAccent,
                  size: 20,
                ),
                Text(
                  '$streak',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 12),
              ],
              Icon(Icons.toll, size: 18, color: accent),
              const SizedBox(width: 4),
              Text(
                '${profile.bankroll}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: profile.levelProgress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.profile,
    required this.inProgress,
    required this.onPlay,
  });

  final ProfileController profile;
  final bool inProgress;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final done = profile.dailyPlayedToday && !inProgress;
    final streak = profile.currentDailyStreak;
    final result = profile.profile.lastDailyWon ? 'You won' : 'Played';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: done ? 0.2 : 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.today, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily challenge',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  done
                      ? '$result today. Back tomorrow for a new deal.'
                      : 'Same deal for everyone. Win for +150 XP, +300 chips.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (streak > 0)
                  Text(
                    '$streak-day streak',
                    style: theme.textTheme.labelSmall?.copyWith(color: accent),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          done
              ? Icon(Icons.check_circle, color: accent)
              : FilledButton(
                  onPressed: onPlay,
                  child: Text(inProgress ? 'Resume' : 'Play'),
                ),
        ],
      ),
    );
  }
}
