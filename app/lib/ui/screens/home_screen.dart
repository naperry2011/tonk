import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../meta/match_setup.dart';
import '../../meta/profile_controller.dart';
import '../../state/game_controller.dart';
import '../theme.dart';
import '../themes.dart';
import '../widgets/lofi_backdrop.dart';
import '../widgets/new_match_sheet.dart';
import '../widgets/profile_chip.dart';
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

  /// The one big button: continue, deal, or refill.
  Future<void> _play() async {
    if (_hasMatchSave) {
      if (await s.match.resume()) {
        if (mounted) await _openTable(s.match);
      } else {
        await _refreshSaves();
      }
      return;
    }
    if (!profile.canBuyIn) {
      profile.refill();
      return;
    }
    await _deal(s.settings.opponents);
  }

  Future<void> _newMatch() async {
    final opponents = await showNewMatchSheet(
      context,
      initialOpponents: s.settings.opponents,
      replacesMatch: _hasMatchSave,
    );
    if (opponents == null || !mounted) return;
    s.settings.update(opponents: opponents);
    if (_hasMatchSave) await s.match.abandonMatch();
    if (!profile.canBuyIn) profile.refill();
    await _deal(opponents);
  }

  Future<void> _deal(int opponents) async {
    if (startMatch(s.match, profile, opponents)) await _openTable(s.match);
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
            body: LofiBackdrop(
              table: table,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(child: _buildBody(table)),
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

  Widget _buildBody(TableTheme table) {
    final theme = Theme.of(context);
    final playLabel = _hasMatchSave
        ? 'Continue'
        : profile.canBuyIn
        ? 'Play'
        : 'Get a refill';
    final playHint = _hasMatchSave
        ? 'Pick up your match'
        : profile.canBuyIn
        ? '${s.settings.opponents} '
              '${s.settings.opponents == 1 ? 'opponent' : 'opponents'}'
              '  ·  1,000 buy-in'
        : 'Uncle Ray spots you 1,000';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 20),
      child: Column(
        children: [
          Row(
            children: [
              ProfileChip(
                profile: profile,
                onTap: () => _push(ProfileScreen(services: s)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _push(SettingsScreen(services: s)),
              ),
            ],
          ),
          const Spacer(flex: 3),
          Text(
            'TONK',
            style: theme.textTheme.displayLarge?.copyWith(
              color: table.accent,
              fontWeight: FontWeight.w500,
              fontSize: 68,
              letterSpacing: 18,
              shadows: [
                Shadow(
                  color: table.accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                ),
              ],
            ),
          ),
          Text(
            'Knock, spread, talk your talk.',
            style: theme.textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: TonkColors.textSoft,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 140,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  table.accent.withValues(alpha: 0),
                  table.accent.withValues(alpha: 0.6),
                  table.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const Spacer(flex: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: _play,
                  child: Text(
                    playLabel,
                    style: const TextStyle(fontSize: 19, letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            playHint,
            style: theme.textTheme.labelMedium?.copyWith(
              color: TonkColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          TextButton(onPressed: _newMatch, child: const Text('New match')),
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _DailyStrip(
              profile: profile,
              inProgress: _hasDailySave,
              onPlay: _playDaily,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim daily challenge row.
class _DailyStrip extends StatelessWidget {
  const _DailyStrip({
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
    final detail = done
        ? (profile.profile.lastDailyWon ? 'Won today' : 'Played today')
        : 'Same deal for everyone';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: done ? null : onPlay,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: glassPanel(
            border: done ? null : accent.withValues(alpha: 0.45),
          ),
          child: Row(
            children: [
              Icon(Icons.today, size: 20, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily challenge',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      streak > 0 ? '$detail  ·  $streak-day streak' : detail,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: TonkColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (done)
                Icon(Icons.check_circle, color: accent)
              else
                Text(
                  inProgress ? 'Resume ›' : 'Play ›',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
