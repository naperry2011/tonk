import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Color;

import '../engine/engine.dart';

/// Moments a character can react to. Keys match characters.json.
enum TalkKey {
  greet,
  knockWin,
  knockCaught,
  catchKnocker,
  tonk,
  sufferTonk,
  spread,
  hitYou,
  gotHit,
  callRaise,
  passRaise,
  raise,
  matchWin,
  matchLose,
}

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.tagline,
    required this.color,
    required this.emoji,
    required this.style,
    required this.lines,
  });

  final String id;
  final String name;
  final String tagline;
  final Color color;
  final String emoji;
  final AiStyle style;
  final Map<TalkKey, List<String>> lines;

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    name: json['name'] as String,
    tagline: json['tagline'] as String? ?? '',
    color: _parseColor(json['color'] as String? ?? '#F2C14E'),
    emoji: json['emoji'] as String? ?? '',
    style: AiStyle.fromJson(json['style'] as Map<String, dynamic>? ?? const {}),
    lines: _parseLines(json['lines'] as Map<String, dynamic>? ?? const {}),
  );

  static Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
}

class Roster {
  const Roster({required this.characters, required this.shared});

  final List<Character> characters;

  /// Fallback lines any character can say.
  final Map<TalkKey, List<String>> shared;

  factory Roster.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return Roster(
      characters: [
        for (final c in json['characters'] as List)
          Character.fromJson(c as Map<String, dynamic>),
      ],
      shared: _parseLines(json['shared'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Character? byId(String? id) {
    for (final c in characters) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// [count] distinct characters in random order.
  List<Character> pick(int count, Random random) =>
      (List.of(characters)..shuffle(random)).take(count).toList();

  /// A line for [character], preferring their own voice over shared lines.
  String? line(Character? character, TalkKey key, Random random) {
    final own = character?.lines[key] ?? const [];
    final fallback = shared[key] ?? const [];
    final pool =
        own.isNotEmpty && (fallback.isEmpty || random.nextDouble() < 0.8)
        ? own
        : fallback;
    if (pool.isEmpty) return null;
    return pool[random.nextInt(pool.length)];
  }
}

Map<TalkKey, List<String>> _parseLines(Map<String, dynamic> json) => {
  for (final key in TalkKey.values)
    if (json[key.name] is List)
      key: [for (final l in json[key.name] as List) l as String],
};
