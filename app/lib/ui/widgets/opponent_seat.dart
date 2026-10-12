import 'package:flutter/material.dart';

import '../../content/roster.dart';
import '../../engine/engine.dart';
import '../theme.dart';
import '../themes.dart';
import 'playing_card.dart';

/// An AI opponent: avatar, name, hidden hand, scores, and what they're
/// doing or saying.
class OpponentSeat extends StatelessWidget {
  const OpponentSeat({
    super.key,
    required this.player,
    required this.matchScore,
    required this.isActive,
    this.character,
    this.lastAction,
    this.speech,
    this.deckTheme,
  });

  final Player player;
  final Character? character;
  final int matchScore;
  final bool isActive;
  final String? lastAction;

  /// Table talk; shown as a bubble and takes priority over [lastAction].
  final String? speech;
  final DeckTheme? deckTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = character?.color ?? TonkColors.gold;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isActive ? 0.35 : 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(
                name: player.name,
                color: accent,
                emoji: character?.emoji,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    player.name,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            width: 24 + (player.cardCount - 1).clamp(0, 99) * 9.0,
            child: Stack(
              children: [
                for (var i = 0; i < player.cardCount; i++)
                  Positioned(
                    left: i * 9.0,
                    child: PlayingCard(width: 24, deckTheme: deckTheme),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$matchScore pts  ·  ${player.chips} chips',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 54,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              // Hide the outgoing line at once so two lines never overlap.
              switchOutCurve: const Threshold(1),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: speech != null
                  ? _Bubble(key: ValueKey('s$speech'), text: speech!)
                  : Center(
                      key: ValueKey('a${lastAction ?? isActive}'),
                      child: Text(
                        lastAction ?? (isActive ? 'Thinking...' : ''),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.color, this.emoji});

  final String name;
  final Color color;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final emoji = this.emoji;
    return SizedBox(
      width: 34,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color,
            child: Text(
              name.characters.first,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (emoji != null && emoji.isNotEmpty)
            Positioned(
              right: -2,
              bottom: -4,
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TonkColors.cardFace,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 3,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
    );
  }
}
