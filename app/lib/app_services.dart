import 'content/roster.dart';
import 'data/settings_store.dart';
import 'meta/match_setup.dart';
import 'meta/profile_controller.dart';
import 'meta/progression.dart';
import 'state/game_controller.dart';
import 'ui/table_feel.dart';
import 'ui/themes.dart';

/// The app's long-lived objects, passed to screens together.
class AppServices {
  AppServices({
    required this.roster,
    required this.match,
    required this.daily,
    required this.settings,
    required this.profile,
    this.feel,
  }) {
    connectProfile(match, profile);
    connectProfile(daily, profile);
  }

  final Roster roster;

  /// The regular match table (save slot `tonk_game_state`).
  final GameController match;

  /// The daily challenge table (save slot `tonk_daily_state`).
  final GameController daily;
  final SettingsController settings;
  final ProfileController profile;

  /// Sound and haptics; null in tests.
  final TableFeel? feel;

  /// Falls back to default themes if the saved choice is locked (e.g. a
  /// fresh profile with settings from an older build).
  void enforceUnlocks() {
    if (!profile.unlocked(UnlockKind.table, settings.tableTheme)) {
      settings.update(tableTheme: TableTheme.cardRoom.id);
    }
    if (!profile.unlocked(UnlockKind.deck, settings.deckTheme)) {
      settings.update(deckTheme: DeckTheme.rosegold.id);
    }
  }
}
