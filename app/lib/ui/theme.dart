import 'package:flutter/material.dart';

/// Late-night lofi palette, matched to the web game's styles/main.css.
abstract final class TonkColors {
  // Backgrounds (web --bg-deep .. --bg-surface).
  static const ink = Color(0xFF0C0E14);
  static const night = Color(0xFF12151E);
  static const dusk = Color(0xFF1A1E2E);
  static const elevated = Color(0xFF242937);
  static const surface = Color(0xFF2D3344);

  // Felt glow (web --felt-*), muted.
  static const felt = Color(0xFF163A2C);
  static const feltDark = Color(0xFF0C0E14);

  // Accents (web --accent-primary rose gold, --gold-primary).
  static const rose = Color(0xFFE8B4A8);
  static const roseDeep = Color(0xFFC08878);

  /// Chip and coin gold; also the default highlight for titles.
  static const gold = Color(0xFFD4A855);
  static const goldSoft = Color(0xFFF0D78C);

  // Text (web --text-*).
  static const text = Color(0xFFF8FAFC);
  static const textSoft = Color(0xFFCBD5E1);
  static const textMuted = Color(0xFF8A93A6);

  // Cards: warm cream faces, slightly faded suits.
  static const cardFace = Color(0xFFFBF5EA);
  static const cardRed = Color(0xFFB54A43);
  static const cardBlack = Color(0xFF26303F);
  static const cardBack = Color(0xFF4A2B3A);

  /// Playable targets (hittable spreads, drawable piles): dusty blue.
  static const highlight = Color(0xFF9DB7D5);

  // Frosted glass panels (web --glass-*).
  static const glass = Color(0x0DFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
}

abstract final class TonkFonts {
  static const display = 'Cormorant Garamond';
  static const body = 'DM Sans';
}

/// Slower, softer motion for the lofi feel.
abstract final class TonkMotion {
  static const quick = Duration(milliseconds: 240);
  static const standard = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 560);
  static const curve = Curves.easeInOutCubic;
}

ThemeData buildTonkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TonkColors.dusk,
    brightness: Brightness.dark,
    primary: TonkColors.rose,
    onPrimary: TonkColors.dusk,
    secondary: TonkColors.gold,
    surface: TonkColors.night,
    onSurface: TonkColors.text,
  );

  final base = ThemeData(
    brightness: Brightness.dark,
    fontFamily: TonkFonts.body,
  ).textTheme;
  TextStyle? display(TextStyle? s, {FontWeight weight = FontWeight.w600}) =>
      s?.copyWith(
        fontFamily: TonkFonts.display,
        fontWeight: weight,
        fontFeatures: const [FontFeature.liningFigures()],
      );

  final textTheme = base
      .copyWith(
        displayLarge: display(base.displayLarge),
        displayMedium: display(base.displayMedium),
        displaySmall: display(base.displaySmall),
        headlineLarge: display(base.headlineLarge),
        headlineMedium: display(base.headlineMedium, weight: FontWeight.w700),
        headlineSmall: display(base.headlineSmall, weight: FontWeight.w700),
        titleLarge: display(base.titleLarge, weight: FontWeight.w700),
      )
      .apply(bodyColor: TonkColors.text, displayColor: TonkColors.text);

  const shape = StadiumBorder();
  const buttonText = TextStyle(
    fontFamily: TonkFonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0.8,
  );

  return ThemeData(
    colorScheme: scheme,
    fontFamily: TonkFonts.body,
    textTheme: textTheme,
    scaffoldBackgroundColor: TonkColors.ink,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 26),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: TonkColors.glassBorder),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: const BorderSide(color: TonkColors.glassBorder),
        selectedBackgroundColor: TonkColors.elevated,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TonkColors.dusk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TonkColors.elevated,
      contentTextStyle: const TextStyle(
        fontFamily: TonkFonts.body,
        color: TonkColors.text,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: TonkColors.dusk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Frosted panel used for seats, cards of info, and sheets.
BoxDecoration glassPanel({
  Color? border,
  double radius = 18,
  double fill = 0.05,
}) => BoxDecoration(
  color: Colors.white.withValues(alpha: fill),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border ?? TonkColors.glassBorder),
);
