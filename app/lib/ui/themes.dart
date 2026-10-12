import 'package:flutter/material.dart';

/// Card back styles. Ported from the web version's styles/themes.css.
class DeckTheme {
  const DeckTheme({
    required this.id,
    required this.name,
    required this.top,
    required this.bottom,
    required this.border,
    required this.emblem,
  });

  final String id;
  final String name;
  final Color top;
  final Color bottom;
  final Color border;
  final Color emblem;

  static const rosegold = DeckTheme(
    id: 'rosegold',
    name: 'Rose Gold',
    top: Color(0xFF1A1E2E),
    bottom: Color(0xFF242937),
    border: Color(0xFFE8B4A8),
    emblem: Color(0xFFE8B4A8),
  );

  static const all = [
    rosegold,
    DeckTheme(
      id: 'midnight',
      name: 'Midnight Gold',
      top: Color(0xFF0A0C10),
      bottom: Color(0xFF141820),
      border: Color(0xFFD4A855),
      emblem: Color(0xFFD4A855),
    ),
    DeckTheme(
      id: 'royal',
      name: 'Royal Velvet',
      top: Color(0xFF1A1228),
      bottom: Color(0xFF2D1F4A),
      border: Color(0xFF7C5CBD),
      emblem: Color(0xFFD4A855),
    ),
    DeckTheme(
      id: 'emerald',
      name: 'Emerald Isle',
      top: Color(0xFF0A2118),
      bottom: Color(0xFF145238),
      border: Color(0xFF5A9A82),
      emblem: Color(0xFFA7C4BC),
    ),
    DeckTheme(
      id: 'crimson',
      name: 'Crimson Club',
      top: Color(0xFF2A0A0A),
      bottom: Color(0xFF5A1A1A),
      border: Color(0xFFCC4444),
      emblem: Color(0xFFCC4444),
    ),
    DeckTheme(
      id: 'ocean',
      name: 'Ocean Blue',
      top: Color(0xFF0C1929),
      bottom: Color(0xFF1A365D),
      border: Color(0xFF4A8FD4),
      emblem: Color(0xFF4A8FD4),
    ),
  ];

  static DeckTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => rosegold);
}

/// Table backgrounds.
class TableTheme {
  const TableTheme({
    required this.id,
    required this.name,
    required this.tagline,
    required this.center,
    required this.edge,
    required this.accent,
  });

  final String id;
  final String name;
  final String tagline;
  final Color center;
  final Color edge;

  /// Highlight color for buttons, pills, and titles on this table.
  final Color accent;

  BoxDecoration get decoration => BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0, -0.2),
      radius: 1.1,
      colors: [center, edge],
    ),
  );

  static const cardRoom = TableTheme(
    id: 'card_room',
    name: 'Card Room',
    tagline: 'Green felt, low lights, serious faces.',
    center: Color(0xFF0E5A3A),
    edge: Color(0xFF07331F),
    accent: Color(0xFFF2C14E),
  );

  static const all = [
    cardRoom,
    TableTheme(
      id: 'cookout',
      name: 'Backyard Cookout',
      tagline: 'Folding table, grill smoke, music up.',
      center: Color(0xFF8A5A2B),
      edge: Color(0xFF3E2512),
      accent: Color(0xFFFFB74D),
    ),
    TableTheme(
      id: 'rooftop',
      name: 'Rooftop',
      tagline: 'City lights and late-night hands.',
      center: Color(0xFF2B2D5C),
      edge: Color(0xFF0D0E24),
      accent: Color(0xFFFF80AB),
    ),
  ];

  static TableTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => cardRoom);
}
