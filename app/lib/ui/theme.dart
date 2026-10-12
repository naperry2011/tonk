import 'package:flutter/material.dart';

abstract final class TonkColors {
  static const felt = Color(0xFF0E5A3A);
  static const feltDark = Color(0xFF07331F);
  static const gold = Color(0xFFF2C14E);
  static const cardFace = Color(0xFFFFFBF2);
  static const cardRed = Color(0xFFC62828);
  static const cardBlack = Color(0xFF1B1B1B);
  static const cardBack = Color(0xFF8E1B2E);
  static const highlight = Color(0xFF4FC3F7);
}

ThemeData buildTonkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TonkColors.felt,
    brightness: Brightness.dark,
    primary: TonkColors.gold,
    onPrimary: Colors.black,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: TonkColors.feltDark,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
  );
}

/// Radial felt background used behind the table and home screen.
const BoxDecoration feltDecoration = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(0, -0.2),
    radius: 1.1,
    colors: [TonkColors.felt, TonkColors.feltDark],
  ),
);
