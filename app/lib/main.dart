import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_services.dart';
import 'content/roster.dart';
import 'data/save_store.dart';
import 'data/settings_store.dart';
import 'meta/profile_controller.dart';
import 'state/game_controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/table_feel.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final roster = Roster.fromJsonString(
    await rootBundle.loadString('assets/content/characters.json'),
  );
  final settings = SettingsController();
  final profile = ProfileController();
  await Future.wait([settings.load(), profile.load()]);

  // Load sounds in the background so the first frame isn't held up; a sound
  // requested before it loads is simply skipped. Sound is optional.
  final feel = TableFeel(settings);
  unawaited(
    feel.preload().catchError(
      (Object e) => debugPrint('Sound effects unavailable: $e'),
    ),
  );

  final services = AppServices(
    roster: roster,
    match: GameController(roster: roster),
    daily: GameController(
      roster: roster,
      store: SharedPrefsSaveStore(key: SaveStore.dailyStateKey),
    ),
    settings: settings,
    profile: profile,
    feel: feel,
  )..enforceUnlocks();
  runApp(TonkApp(services: services));
}

class TonkApp extends StatelessWidget {
  const TonkApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tonk',
      debugShowCheckedModeBanner: false,
      theme: buildTonkTheme(),
      home: HomeScreen(services: services),
    );
  }
}
