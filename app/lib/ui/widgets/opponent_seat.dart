import 'package:flutter/material.dart';

import '../../content/roster.dart';
import '../../engine/engine.dart';
import '../theme.dart';

/// Compact AI opponent: avatar with a card-count badge, name, score, and
/// their last move. Speech bubbles are drawn separately ([SpeechBubble]) so
/// they can float over the table without reserving space here.
class OpponentSeat extends StatelessWidget {
  const OpponentSeat({
    super.key,
    required this.player,
    required this.matchScore,
    required this.isActive,
    this.character,
    this.lastAction,
  });

  static const double height = 104;

  final Player player;
  final Character? character;
  final int matchScore;
  final bool isActive;
  final String? lastAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = character?.color ?? TonkColors.rose;
    final caption = lastAction ?? (isActive ? 'Thinking...' : '');
    return SizedBox(
      height: height,
      child: Column(
        children: [
          _Avatar(
            name: player.name,
            color: accent,
            emoji: character?.emoji,
            cards: player.cardCount,
            active: isActive,
          ),
          const SizedBox(height: 5),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: TonkFonts.display,
              fontFeatures: const [FontFeature.liningFigures()],
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.1,
            ),
          ),
          Text(
            '$matchScore pts',
            style: theme.textTheme.labelSmall?.copyWith(
              color: TonkColors.textMuted,
              height: 1.2,
            ),
          ),
          AnimatedSwitcher(
            duration: TonkMotion.standard,
            switchOutCurve: const Threshold(1),
            child: Text(
              caption,
              key: ValueKey(caption),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.color,
    required this.cards,
    required this.active,
    this.emoji,
  });

  final String name;
  final Color color;
  final String? emoji;
  final int cards;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final emoji = this.emoji;
    return SizedBox(
      width: 76,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: TonkMotion.standard,
            curve: TonkMotion.curve,
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? color : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (active)
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 18,
                  ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: color,
              child: Text(
                name.characters.first,
                style: const TextStyle(
                  fontFamily: TonkFonts.display,
                  fontFeatures: [FontFeature.liningFigures()],
                  color: TonkColors.dusk,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          if (emoji != null && emoji.isNotEmpty)
            Positioned(
              left: 6,
              bottom: -2,
              child: Text(emoji, style: const TextStyle(fontSize: 15)),
            ),
          Positioned(
            right: 0,
            top: -2,
            child: Semantics(
              label: '$cards cards',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TonkColors.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TonkColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.style,
                      size: 11,
                      color: TonkColors.textSoft,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$cards',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TonkColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Table talk, drawn in an overlay just under the speaker's seat.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final fill = TonkColors.cardFace.withValues(alpha: 0.95);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(14, 7), painter: _TailPainter(fill)),
        Container(
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TonkColors.dusk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
