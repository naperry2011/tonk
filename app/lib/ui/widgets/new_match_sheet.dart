import 'package:flutter/material.dart';

import '../theme.dart';

/// Bottom sheet for starting a fresh match. Returns the opponent count, or
/// null if dismissed.
Future<int?> showNewMatchSheet(
  BuildContext context, {
  required int initialOpponents,
  required bool replacesMatch,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: TonkColors.dusk,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _NewMatchSheet(
      initialOpponents: initialOpponents,
      replacesMatch: replacesMatch,
    ),
  );
}

class _NewMatchSheet extends StatefulWidget {
  const _NewMatchSheet({
    required this.initialOpponents,
    required this.replacesMatch,
  });

  final int initialOpponents;
  final bool replacesMatch;

  @override
  State<_NewMatchSheet> createState() => _NewMatchSheetState();
}

class _NewMatchSheetState extends State<_NewMatchSheet> {
  late int _opponents = widget.initialOpponents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New match', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '1,000 chip buy-in. First to 100 loses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: TonkColors.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'How many at the table?',
              style: theme.textTheme.titleSmall?.copyWith(
                color: TonkColors.textSoft,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {_opponents},
              showSelectedIcon: false,
              onSelectionChanged: (sel) =>
                  setState(() => _opponents = sel.first),
            ),
            if (widget.replacesMatch) ...[
              const SizedBox(height: 14),
              Text(
                'This ends your match in progress.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: TonkColors.rose,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _opponents),
                child: const Text('Deal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
