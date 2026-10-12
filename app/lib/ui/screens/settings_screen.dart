import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../meta/progression.dart';
import '../theme.dart';
import '../themes.dart';
import '../widgets/playing_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nickname = TextEditingController(
    text: widget.services.settings.nickname,
  );

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services.settings;
    final profile = widget.services.profile;
    int? lockLevel(UnlockKind kind, String id) =>
        profile.unlocked(kind, id) ? null : unlockLevel(kind, id);
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleMedium?.copyWith(
      color: TonkColors.gold,
      fontWeight: FontWeight.w800,
    );
    return ListenableBuilder(
      listenable: Listenable.merge([s, profile]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text('Table', style: heading),
            const SizedBox(height: 8),
            for (final t in TableTheme.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TableOption(
                  theme: t,
                  selected: s.tableTheme == t.id,
                  lockedUntil: lockLevel(UnlockKind.table, t.id),
                  onTap: () => s.update(tableTheme: t.id),
                ),
              ),
            const SizedBox(height: 16),
            Text('Card backs', style: heading),
            const SizedBox(height: 22),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                for (final d in DeckTheme.all)
                  _DeckOption(
                    deck: d,
                    selected: s.deckTheme == d.id,
                    lockedUntil: lockLevel(UnlockKind.deck, d.id),
                    onTap: () => s.update(deckTheme: d.id),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Feel', style: heading),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound effects'),
              value: s.sound,
              onChanged: (v) => s.update(sound: v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Haptics'),
              value: s.haptics,
              onChanged: (v) => s.update(haptics: v),
            ),
            const SizedBox(height: 16),
            Text('What the table calls you', style: heading),
            const SizedBox(height: 8),
            TextField(
              controller: _nickname,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'rookie',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => s.update(nickname: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableOption extends StatelessWidget {
  const _TableOption({
    required this.theme,
    required this.selected,
    required this.onTap,
    this.lockedUntil,
  });

  final TableTheme theme;
  final bool selected;
  final VoidCallback onTap;

  /// Level that unlocks this table, or null if it's available.
  final int? lockedUntil;

  @override
  Widget build(BuildContext context) {
    final locked = lockedUntil != null;
    return Semantics(
      button: !locked,
      selected: selected,
      label: locked ? '${theme.name}, unlocks at level $lockedUntil' : null,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Opacity(
          opacity: locked ? 0.55 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: theme.decoration.copyWith(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? theme.accent : Colors.white12,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme.tagline,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  _LockBadge(level: lockedUntil!)
                else if (selected)
                  Icon(Icons.check_circle, color: theme.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckOption extends StatelessWidget {
  const _DeckOption({
    required this.deck,
    required this.selected,
    required this.onTap,
    this.lockedUntil,
  });

  final DeckTheme deck;
  final bool selected;
  final VoidCallback onTap;
  final int? lockedUntil;

  @override
  Widget build(BuildContext context) {
    final locked = lockedUntil != null;
    return Semantics(
      button: !locked,
      selected: selected,
      label: locked
          ? '${deck.name} card backs, unlocks at level $lockedUntil'
          : '${deck.name} card backs',
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: locked ? 0.4 : 1,
                  child: PlayingCard(
                    width: 52,
                    deckTheme: deck,
                    selected: selected,
                  ),
                ),
                if (locked) _LockBadge(level: lockedUntil!),
              ],
            ),
            const SizedBox(height: 6),
            Text(deck.name, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 13, color: Colors.white70),
          const SizedBox(width: 3),
          Text(
            'Lv $level',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
