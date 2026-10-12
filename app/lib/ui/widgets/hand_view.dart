import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';
import 'playing_card.dart';

/// The human's hand. Tap to select; long-press and drag to reorder.
class HandView extends StatelessWidget {
  const HandView({
    super.key,
    required this.cards,
    required this.selected,
    required this.onTap,
    required this.onReorder,
  });

  final List<Card> cards;
  final List<Card> selected;
  final ValueChanged<Card> onTap;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit up to 6 cards across before scrolling.
        final width = ((constraints.maxWidth - 32) / 6 - 6).clamp(48.0, 72.0);
        final cardHeight = width * 1.42;
        return SizedBox(
          height: cardHeight + 24,
          child: ReorderableListView(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            proxyDecorator: (child, _, _) =>
                Material(color: Colors.transparent, child: child),
            onReorderItem: onReorder,
            children: [
              for (var i = 0; i < cards.length; i++)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(cards[i].id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: DealIn(
                      key: ValueKey('deal-${cards[i].id}'),
                      child: PlayingCard(
                        card: cards[i],
                        width: width,
                        selected: selected.contains(cards[i]),
                        onTap: () => onTap(cards[i]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
