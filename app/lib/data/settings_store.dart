import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences, stored under the web version's `tonk_settings` key.
class SettingsController extends ChangeNotifier {
  SettingsController({SharedPreferencesAsync? prefs, bool persist = true})
    : _prefs = persist ? (prefs ?? SharedPreferencesAsync()) : null;

  static const String key = 'tonk_settings';

  final SharedPreferencesAsync? _prefs;

  String deckTheme = 'rosegold';
  String tableTheme = 'card_room';
  bool sound = true;
  bool haptics = true;

  /// What the AI calls you in table talk.
  String nickname = 'rookie';

  Future<void> load() async {
    final raw = await _prefs?.getString(key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      deckTheme = json['deckTheme'] as String? ?? deckTheme;
      tableTheme = json['tableTheme'] as String? ?? tableTheme;
      sound = json['sound'] as bool? ?? sound;
      haptics = json['haptics'] as bool? ?? haptics;
      nickname = json['nickname'] as String? ?? nickname;
      notifyListeners();
    } on FormatException {
      // Corrupt settings fall back to defaults.
    }
  }

  void update({
    String? deckTheme,
    String? tableTheme,
    bool? sound,
    bool? haptics,
    String? nickname,
  }) {
    this.deckTheme = deckTheme ?? this.deckTheme;
    this.tableTheme = tableTheme ?? this.tableTheme;
    this.sound = sound ?? this.sound;
    this.haptics = haptics ?? this.haptics;
    final trimmed = nickname?.trim();
    if (trimmed != null && trimmed.isNotEmpty) this.nickname = trimmed;
    notifyListeners();
    _prefs?.setString(
      key,
      jsonEncode({
        'deckTheme': this.deckTheme,
        'tableTheme': this.tableTheme,
        'sound': this.sound,
        'haptics': this.haptics,
        'nickname': this.nickname,
      }),
    );
  }
}
