import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the in-progress match. Same key as the web version's storage.js.
abstract class SaveStore {
  static const String gameStateKey = 'tonk_game_state';
  static const String dailyStateKey = 'tonk_daily_state';

  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> state);
  Future<void> clear();
}

class SharedPrefsSaveStore implements SaveStore {
  SharedPrefsSaveStore({this.key = SaveStore.gameStateKey});

  /// Storage key; the daily challenge uses its own slot.
  final String key;

  @override
  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(state));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// For tests.
class MemorySaveStore implements SaveStore {
  String? _raw;

  @override
  Future<Map<String, dynamic>?> load() async =>
      _raw == null ? null : jsonDecode(_raw!) as Map<String, dynamic>;

  @override
  Future<void> save(Map<String, dynamic> state) async =>
      _raw = jsonEncode(state);

  @override
  Future<void> clear() async => _raw = null;
}
