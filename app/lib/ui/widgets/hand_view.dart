import 'dart:math';

import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';
import '../theme.dart';
import 'playing_card.dart';

/// The human's hand as a fanned arc. Tap a card to select it; long-press and
/// drag to reorder.
class HandView extends StatefulWidget {
  const HandView({
    super.key,
    required this.cards,
    required this.selected,
    required this.onTap,
    required this.onReorder,
    this.hinted = const {},
    this.cardKeys,
  });

  final List<Card> cards;
  final List<Card> selected;
  final ValueChanged<Card> onTap;

  /// Cards that could form a spread (soft gold glow).
  final Set<Card> hinted;

  /// Key per card id, so the table can find where a card is on screen
  /// (for spread animations).
  final Map<String, GlobalKey>? cardKeys;

  /// Moves the card at oldIndex so it ends up at newIndex.
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<HandView> createState() => _HandViewState();
}

/// Card positions for one layout pass.
class _Fan {
  _Fan(double width, this.count) : cardW = (width * 0.22).clamp(68.0, 90.0) {
    cardH = cardW * 1.42;
    final room = width - 32 - cardW;
    step = count <= 1 ? 0 : min(cardW * 0.62, room / (count - 1));
    left = (width - (cardW + step * (count - 1))) / 2;
  }

  final int count;
  final double cardW;
  late final double cardH;
  late final double step;
  late final double left;

  static const double lift = 22;
  static const double top = lift + 6;

  double get height => top + cardH + 8;

  double x(int slot) => left + step * slot;

  /// -1 at the left end of the fan, 1 at the right.
  double _t(int slot) => count <= 1 ? 0 : slot / (count - 1) * 2 - 1;

  double angle(int slot) => _t(slot) * 0.11 * min(1, count / 5);

  double drop(int slot) => _t(slot) * _t(slot) * 9;

  /// Topmost card under [dx] (later cards sit on top of earlier ones).
  int? hit(double dx) {
    for (var i = count - 1; i >= 0; i--) {
      if (dx >= x(i) && dx <= x(i) + cardW) return i;
    }
    return null;
  }

  int slotFor(double centerX) {
    if (count <= 1 || step == 0) return 0;
    return ((centerX - left - cardW / 2) / step).round().clamp(0, count - 1);
  }
}

class _HandViewState extends State<HandView> {
  int? _dragFrom;
  int? _dragTo;
  double _dragX = 0;

  void _tapAt(_Fan fan, Offset p) {
    final i = fan.hit(p.dx);
    if (i != null) widget.onTap(widget.cards[i]);
  }

  void _startDrag(_Fan fan, Offset p) {
    final i = fan.hit(p.dx);
    if (i == null) return;
    setState(() {
      _dragFrom = i;
      _dragTo = i;
      _dragX = p.dx;
    });
  }

  void _moveDrag(_Fan fan, Offset p) {
    if (_dragFrom == null) return;
    setState(() {
      _dragX = p.dx;
      _dragTo = fan.slotFor(p.dx);
    });
  }

  void _endDrag() {
    final from = _dragFrom;
    final to = _dragTo;
    setState(() {
      _dragFrom = null;
      _dragTo = null;
    });
    if (from != null && to != null && from != to) widget.onReorder(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = widget.cards;
        final fan = _Fan(constraints.maxWidth, cards.length);
        final dragFrom = _dragFrom;

        // Order the fan as it will look after the drop.
        final order = List<int>.generate(cards.length, (i) => i);
        if (dragFrom != null) {
          order
            ..remove(dragFrom)
            ..insert(_dragTo!, dragFrom);
        }

        Widget placed(int index, int slot) {
          final card = cards[index];
          final dragging = index == dragFrom;
          final isSelected = widget.selected.contains(card);
          final lifted = isSelected || dragging;
          return AnimatedPositioned(
            key: ValueKey(card.id),
            duration: dragging ? Duration.zero : TonkMotion.quick,
            curve: TonkMotion.curve,
            left: dragging ? _dragX - fan.cardW / 2 : fan.x(slot),
            top: _Fan.top + fan.drop(slot) - (lifted ? _Fan.lift : 0),
            width: fan.cardW,
            height: fan.cardH,
            child: AnimatedRotation(
              duration: TonkMotion.quick,
              turns: lifted ? 0 : fan.angle(slot) / (2 * pi),
              child: Semantics(
                button: true,
                onTap: () => widget.onTap(card),
                child: DealIn(
                  key: ValueKey('deal-${card.id}'),
                  child: PlayingCard(
                    key: widget.cardKeys?[card.id],
                    card: card,
                    width: fan.cardW,
                    selected: isSelected,
                    hinted: !isSelected && widget.hinted.contains(card),
                  ),
                ),
              ),
            ),
          );
        }

        final children = <Widget>[
          for (var slot = 0; slot < order.length; slot++)
            if (order[slot] != dragFrom) placed(order[slot], slot),
          // The dragged card is drawn last, on top of the fan.
          if (dragFrom != null) placed(dragFrom, order.indexOf(dragFrom)),
        ];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _tapAt(fan, d.localPosition),
          onLongPressStart: (d) => _startDrag(fan, d.localPosition),
          onLongPressMoveUpdate: (d) => _moveDrag(fan, d.localPosition),
          onLongPressEnd: (_) => _endDrag(),
          onLongPressCancel: _endDrag,
          child: SizedBox(
            height: fan.height,
            width: constraints.maxWidth,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        );
      },
    );
  }
}
