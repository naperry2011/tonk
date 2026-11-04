import 'package:flutter/material.dart';

import '../../meta/profile_controller.dart';
import '../theme.dart';

/// Corner chip: level in a progress ring, win streak, and bankroll.
class ProfileChip extends StatelessWidget {
  const ProfileChip({super.key, required this.profile, required this.onTap});

  final ProfileController profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final streak = profile.profile.stats.winStreak;
    const numbers = TextStyle(
      fontWeight: FontWeight.w700,
      color: TonkColors.text,
      fontSize: 15,
    );
    return Semantics(
      button: true,
      label: 'Profile, level ${profile.level}, ${profile.bankroll} chips',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Profile',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
            decoration: glassPanel(radius: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: profile.levelProgress),
                        duration: TonkMotion.slow,
                        curve: TonkMotion.curve,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 2.5,
                              backgroundColor: TonkColors.glassBorder,
                              color: accent,
                            ),
                      ),
                      Text(
                        '${profile.level}',
                        style: const TextStyle(
                          fontFamily: TonkFonts.display,
                          fontFeatures: [FontFeature.liningFigures()],
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: TonkColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (streak > 0) ...[
                  const Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: TonkColors.gold,
                  ),
                  Text('$streak', style: numbers),
                  const SizedBox(width: 10),
                ],
                Icon(Icons.toll, size: 16, color: accent),
                const SizedBox(width: 4),
                Text('${profile.bankroll}', style: numbers),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
