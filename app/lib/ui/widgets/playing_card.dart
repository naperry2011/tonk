import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';
import '../theme.dart';
import '../themes.dart';

/// A face-up card, or a face-down back when [card] is null.
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    this.card,
    this.width = 60,
    this.selected = false,
    this.highlighted = false,
    this.hinted = false,
    this.deckTheme,
    this.onTap,
  });

  final Card? card;
  final double width;
  final bool selected;

  /// Outline used for playable targets (e.g. a hittable spread).
  final bool highlighted;

  /// Soft gold glow: this card is part of a spread you could lay.
  final bool hinted;

  /// Card back style; defaults to Rose Gold.
  final DeckTheme? deckTheme;
  final VoidCallback? onTap;

  double get height => width * 1.42;

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    final back = deckTheme ?? DeckTheme.rosegold;
    final radius = BorderRadius.circular(width * 0.14);
    final borderColor = selected
        ? TonkColors.rose
        : highlighted
        ? TonkColors.highlight
        : hinted
        ? TonkColors.gold
        : card == null
        ? back.border
        : Colors.black12;

    final face = AnimatedContainer(
      duration: TonkMotion.quick,
      curve: TonkMotion.curve,
      width: width,
      height: height,
      transform: Matrix4.translationValues(0, selected ? -12 : 0, 0),
      decoration: BoxDecoration(
        color: card == null ? null : TonkColors.cardFace,
        gradient: card == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [back.top, back.bottom],
              )
            : null,
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: selected || highlighted || hinted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? TonkColors.rose.withValues(alpha: 0.35)
                : hinted
                ? TonkColors.gold.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: selected || hinted ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: card == null
          ? _Back(width: width, theme: back)
          : _Face(card: card, width: width),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: card == null ? 'Face-down card' : _spokenName(card),
      child: GestureDetector(onTap: onTap, child: face),
    );
  }

  static String _spokenName(Card card) {
    const names = {'A': 'Ace', 'J': 'Jack', 'Q': 'Queen', 'K': 'King'};
    return '${names[card.rank] ?? card.rank} of ${card.suit.name}';
  }
}

/// Plays a short slide-and-fade the first time a keyed child appears.
class DealIn extends StatelessWidget {
  const DealIn({
    super.key,
    required this.child,
    this.from = const Offset(0, -0.6),
    this.duration = TonkMotion.standard,
  });

  final Widget child;

  /// Starting offset as a fraction of the child's size.
  final Offset from;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutQuart,
      builder: (context, t, child) => FractionalTranslation(
        translation: Offset.lerp(from, Offset.zero, t)!,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: child,
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.card, required this.width});

  final Card card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? TonkColors.cardRed : TonkColors.cardBlack;
    final corner = TextStyle(
      fontFamily: TonkFonts.display,
      fontFeatures: const [FontFeature.liningFigures()],
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: width * 0.3,
      height: 1,
    );
    return Padding(
      padding: EdgeInsets.all(width * 0.07),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.rank, style: corner),
              Text(
                card.suit.symbol,
                style: corner.copyWith(
                  fontFamily: TonkFonts.body,
                  fontSize: width * 0.2,
                ),
              ),
            ],
          ),
          Align(
            alignment: const Alignment(0.35, 0.45),
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: width * 0.48,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.width, required this.theme});

  final double width;
  final DeckTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(width * 0.08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.08),
        border: Border.all(color: theme.emblem.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          'T',
          style: TextStyle(
            fontFamily: TonkFonts.display,
            fontFeatures: const [FontFeature.liningFigures()],
            color: theme.emblem.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: width * 0.42,
          ),
        ),
      ),
    );
  }
}
