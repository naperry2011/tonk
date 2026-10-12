import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/app_services.dart';
import 'package:tonk/content/roster.dart';
import 'package:tonk/data/save_store.dart';
import 'package:tonk/data/settings_store.dart';
import 'package:tonk/main.dart';
import 'package:tonk/meta/profile.dart';
import 'package:tonk/meta/profile_controller.dart';
import 'package:tonk/state/game_controller.dart';
import 'package:tonk/ui/widgets/hand_view.dart';
import 'package:tonk/ui/widgets/playing_card.dart';

void main() {
  final roster = Roster.fromJsonString(
    File('assets/content/characters.json').readAsStringSync(),
  );

  AppServices services() => AppServices(
    roster: roster,
    match: GameController(
      store: MemorySaveStore(),
      aiStepDelay: Duration.zero,
      random: Random(11),
      roster: roster,
      talkRandom: Random(1),
    ),
    daily: GameController(
      store: MemorySaveStore(),
      aiStepDelay: Duration.zero,
      roster: roster,
    ),
    settings: SettingsController(persist: false),
    profile: ProfileController(
      persist: false,
      clock: () => DateTime(2026, 10, 11, 12),
    ),
  );

  Future<void> pumpApp(WidgetTester tester, AppServices s) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TonkApp(services: s));
    await tester.pump();
  }

  testWidgets('home shows level, bankroll, and pays the daily bonus', (
    tester,
  ) async {
    final s = services();
    await pumpApp(tester, s);

    expect(find.text('TONK'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(
      s.profile.bankroll,
      Profile.startingBankroll + ProfileController.dailyBonus,
    );
    expect(find.textContaining('Daily bonus'), findsOneWidget);
    expect(find.text('Daily challenge'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('dealing in takes the buy-in and seats unlocked characters', (
    tester,
  ) async {
    final s = services();
    await pumpApp(tester, s);
    final before = s.profile.bankroll;

    await tester.tap(find.textContaining('Deal me in'));
    await tester.pumpAndSettle();

    expect(s.profile.bankroll, before - ProfileController.buyInAmount);
    expect(find.text('Round 1'), findsOneWidget);
    expect(s.match.human.chips, lessThanOrEqualTo(1000));
    for (final p in s.match.opponents) {
      expect([
        'uncle_ray',
        'mr_earl',
        'keisha',
        'lil_tre',
      ], contains(s.match.characterFor(p)!.id));
    }

    final card = s.match.human.hand.first;
    await tester.tap(
      find.descendant(
        of: find.byType(HandView),
        matching: find.byWidgetPredicate(
          (w) => w is PlayingCard && w.card == card,
        ),
      ),
    );
    await tester.pump();
    expect(s.match.selected, isNotEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a broke player gets a refill button', (tester) async {
    final s = services();
    s.profile.profile
      ..bankroll = 0
      ..lastBonusDay = s.profile.today;
    await pumpApp(tester, s);

    await tester.tap(find.textContaining('spots you'));
    await tester.pump();
    expect(s.profile.bankroll, ProfileController.buyInAmount);
    expect(find.textContaining('Deal me in'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('settings lock themes until their level', (tester) async {
    final s = services();
    await pumpApp(tester, s);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rooftop'));
    await tester.pump();
    expect(s.settings.tableTheme, 'card_room', reason: 'Rooftop is locked');

    s.profile.profile.xp = 1500; // level 6
    s.profile.notifyListeners();
    await tester.pump();
    await tester.tap(find.text('Rooftop'));
    await tester.pump();
    expect(s.settings.tableTheme, 'rooftop');

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Zaire');
    expect(s.settings.nickname, 'Zaire');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('profile screen shows stats and achievements', (tester) async {
    final s = services();
    await pumpApp(tester, s);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your table record'), findsOneWidget);
    expect(find.text('Bankroll'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Achievements'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Achievements'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
