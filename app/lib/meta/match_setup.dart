import 'dart:math';

import '../content/roster.dart';
import '../state/game_controller.dart';
import 'profile.dart';
import 'profile_controller.dart';
import 'progression.dart';

/// Characters the player has unlocked (falls back to the full roster if the
/// unlock table would leave too few).
List<Character> unlockedCharacters(Roster roster, ProfileController profile) {
  final open = [
    for (final c in roster.characters)
      if (profile.unlocked(UnlockKind.character, c.id)) c,
  ];
  return open.length >= 3 ? open : roster.characters;
}

/// Takes the buy-in and deals a new match. Returns false if the player
/// can't cover the buy-in.
bool startMatch(
  GameController controller,
  ProfileController profile,
  int opponents,
) {
  if (!profile.buyIn()) return false;
  final roster = controller.roster;
  controller.newMatch(
    opponents,
    startingChips: ProfileController.buyInAmount,
    pool: roster == null ? null : unlockedCharacters(roster, profile),
  );
  return true;
}

/// The day's three opponents, drawn from the full roster (locked characters
/// can make a guest appearance).
List<Character> dailyOpponents(Roster roster, String day) =>
    roster.pick(3, Random(dailySeed(day) * 31 + 7));

/// Routes finished rounds and matches from a table into the profile.
void connectProfile(GameController controller, ProfileController profile) {
  controller
    ..onRoundSettled = profile.applyRound
    ..onMatchEnded = profile.cashOut;
}
