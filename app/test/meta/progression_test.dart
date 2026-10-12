import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/content/roster.dart';
import 'package:tonk/data/save_store.dart';
import 'package:tonk/engine/engine.dart';
import 'package:tonk/meta/match_setup.dart';
import 'package:tonk/meta/profile.dart';
import 'package:tonk/meta/profile_controller.dart';
import 'package:tonk/meta/progression.dart';
import 'package:tonk/state/game_controller.dart';
import 'package:tonk/ui/themes.dart';

final _roster = Roster.fromJsonString(
  File('assets/content/characters.json').readAsStringSync(),
);

ProfileController _profile([DateTime? now]) {
  var time = now ?? DateTime(2026, 10, 11, 12);
  return ProfileController(persist: false, clock: () => time);
}

void main() {
  group('levels', () {
    test('follow the 0 / 100 / 300 / 600 / 1000 curve', () {
      expect(
        [for (var l = 1; l <= 5; l++) xpForLevel(l)],
        [0, 100, 300, 600, 1000],
      );
      expect(levelForXp(0), 1);
      expect(levelForXp(99), 1);
      expect(levelForXp(100), 2);
      expect(levelForXp(999), 4);
      expect(levelForXp(1000), 5);
    });
  });

  group('XP', () {
    test('rewards the way you won', () {
      expect(
        xpFor(const RoundFacts(won: false, condition: WinCondition.knock)),
        10,
      );
      expect(
        xpFor(const RoundFacts(won: true, condition: WinCondition.tonk)),
        100,
      );
      expect(
        xpFor(
          const RoundFacts(
            won: true,
            condition: WinCondition.knock,
            humanKnocked: true,
          ),
        ),
        75,
      );
      expect(
        xpFor(
          const RoundFacts(
            won: true,
            condition: WinCondition.knock,
            matchEnded: true,
            matchWon: true,
          ),
        ),
        300,
      );
      expect(
        xpFor(
          const RoundFacts(
            won: false,
            condition: WinCondition.knock,
            humanFolded: true,
          ),
        ),
        5,
      );
    });
  });

  group('unlock track', () {
    test('only names real themes and characters', () {
      final characterIds = _roster.characters.map((c) => c.id).toSet();
      for (final u in unlockTrack) {
        switch (u.kind) {
          case UnlockKind.character:
            expect(characterIds, contains(u.id));
          case UnlockKind.table:
            expect(TableTheme.all.map((t) => t.id), contains(u.id));
          case UnlockKind.deck:
            expect(DeckTheme.all.map((t) => t.id), contains(u.id));
        }
      }
    });

    test('a new player can fill a 4-player table', () {
      final p = _profile();
      expect(unlockedCharacters(_roster, p).length, greaterThanOrEqualTo(3));
      expect(p.unlocked(UnlockKind.table, 'card_room'), isTrue);
      expect(p.unlocked(UnlockKind.table, 'rooftop'), isFalse);
    });
  });

  group('ProfileController', () {
    test('buy-in, cash out, and refill when broke', () {
      final p = _profile();
      expect(p.bankroll, Profile.startingBankroll);
      expect(p.buyIn(), isTrue);
      expect(
        p.bankroll,
        Profile.startingBankroll - ProfileController.buyInAmount,
      );
      p.cashOut(1400);
      expect(p.bankroll, Profile.startingBankroll + 400);

      p.profile.bankroll = 200;
      expect(p.buyIn(), isFalse);
      p.refill();
      expect(p.bankroll, ProfileController.buyInAmount);
      expect(p.profile.refills, 1);
    });

    test('daily bonus pays once per day', () {
      var now = DateTime(2026, 10, 11, 9);
      final p = ProfileController(persist: false, clock: () => now);
      final start = p.bankroll;
      expect(p.claimDailyBonus(), ProfileController.dailyBonus);
      expect(p.claimDailyBonus(), 0);
      now = DateTime(2026, 10, 12, 8);
      expect(p.claimDailyBonus(), ProfileController.dailyBonus);
      expect(p.bankroll, start + 2 * ProfileController.dailyBonus);
    });

    test('rounds update stats, streaks, XP, unlocks, and achievements', () {
      final p = _profile();
      final first = p.applyRound(
        const RoundFacts(
          won: true,
          condition: WinCondition.tonk,
          spreadsLaid: 2,
        ),
      );
      expect(first.xp, 100);
      expect(first.leveledUp, isTrue);
      expect(first.unlocks.map((u) => u.id), contains('emerald'));
      expect(
        first.achievements.map((a) => a.id),
        containsAll(['first_win', 'tonk']),
      );
      expect(p.profile.stats.tonks, 1);
      expect(p.profile.stats.spreadsLaid, 2);

      p.applyRound(
        const RoundFacts(
          won: true,
          condition: WinCondition.knock,
          humanKnocked: true,
        ),
      );
      final third = p.applyRound(
        const RoundFacts(won: true, condition: WinCondition.caught),
      );
      expect(p.profile.stats.bestWinStreak, 3);
      expect(
        third.achievements.map((a) => a.id),
        containsAll(['hot_hand', 'gotcha']),
      );

      p.applyRound(
        const RoundFacts(
          won: false,
          condition: WinCondition.caught,
          humanKnocked: true,
        ),
      );
      expect(p.profile.stats.winStreak, 0);
      expect(p.profile.stats.timesCaught, 1);
      // Earned achievements are only reported once.
      expect(
        p
            .applyRound(
              const RoundFacts(won: true, condition: WinCondition.tonk),
            )
            .achievements,
        isEmpty,
      );
    });

    test('daily streak counts consecutive days and resets after a gap', () {
      var now = DateTime(2026, 10, 11, 20);
      final p = ProfileController(persist: false, clock: () => now);
      const daily = RoundFacts(
        won: true,
        condition: WinCondition.knock,
        isDaily: true,
      );

      final rewards = p.applyRound(daily);
      expect(rewards.bonusChips, ProfileController.dailyWinChips);
      expect(p.dailyPlayedToday, isTrue);
      now = DateTime(2026, 10, 12, 7);
      expect(p.dailyPlayedToday, isFalse);
      p.applyRound(daily);
      now = DateTime(2026, 10, 13, 7);
      p.applyRound(daily);
      expect(p.currentDailyStreak, 3);
      expect(p.profile.achievements, contains('daily_grind'));

      now = DateTime(2026, 10, 16, 7);
      expect(p.currentDailyStreak, 0);
      p.applyRound(daily);
      expect(p.currentDailyStreak, 1);
    });

    test('profile survives JSON', () {
      final p = _profile()
        ..applyRound(const RoundFacts(won: true, condition: WinCondition.tonk));
      final restored = Profile.fromJson(p.profile.toJson());
      expect(restored.xp, p.profile.xp);
      expect(restored.stats.tonks, 1);
      expect(restored.achievements, p.profile.achievements);
    });
  });

  group('wired to a table', () {
    test(
      'a match takes the buy-in, pays rewards each round, and cashes out',
      () async {
        final profile = _profile();
        final c = GameController(
          store: MemorySaveStore(),
          aiStepDelay: Duration.zero,
          random: Random(9),
          roster: _roster,
          speechDuration: const Duration(milliseconds: 1),
        );
        connectProfile(c, profile);

        expect(startMatch(c, profile, 2), isTrue);
        final bankrollDuringMatch = profile.bankroll;
        for (final p in c.opponents) {
          expect(
            unlockedCharacters(_roster, profile),
            contains(c.characterFor(p)),
          );
          expect(p.chips, lessThanOrEqualTo(ProfileController.buyInAmount));
        }

        var rounds = 0;
        while (true) {
          for (var i = 0; i < 20000; i++) {
            if (c.pendingRaise != null) c.answerRaise(call: true);
            if (!c.aiThinking && c.pendingRaise == null) break;
            await Future<void>.delayed(Duration.zero);
          }
          final summary = c.roundSummary;
          if (summary != null) {
            rounds++;
            expect(summary.rewards, isNotNull);
            if (summary.matchEnded) break;
            c.startNextRound();
            continue;
          }
          c.drawFromDeck();
          c.selected
            ..clear()
            ..add(c.human.getCardsSortedByValue().first);
          c.discardSelected();
        }

        expect(profile.profile.stats.roundsPlayed, rounds);
        expect(profile.profile.stats.matchesPlayed, 1);
        expect(profile.bankroll, bankrollDuringMatch + c.human.chips);
      },
    );

    test('the daily deal is the same for everyone on a given day', () {
      String firstHand(int controllerSeed) {
        final c = GameController(
          store: MemorySaveStore(),
          aiStepDelay: const Duration(hours: 1),
          random: Random(controllerSeed),
          roster: _roster,
        )..newDaily('2026-10-11', dailyOpponents(_roster, '2026-10-11'));
        final hand = c.human.hand.map((card) => card.id).join(',');
        c.dispose();
        return hand;
      }

      expect(firstHand(1), firstHand(2));
      expect(
        dailyOpponents(_roster, '2026-10-11').map((c) => c.id),
        dailyOpponents(_roster, '2026-10-11').map((c) => c.id),
      );
    });
  });
}
