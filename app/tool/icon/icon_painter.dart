// Shared icon artwork for the app icon and store assets.
import 'package:flutter/material.dart';

const _feltCenter = Color(0xFF1D4A37);
const _feltEdge = Color(0xFF0C0E14);
const _gold = Color(0xFFEFC2B6); // rose gold
const _goldDeep = Color(0xFFC08878);
const _cardBack = Color(0xFF4A2B3A);
const _cardDark = Color(0xFF1A1E2E);

/// Paints the icon into a [size] square. With [background] false, only the
/// cards are drawn (Android adaptive foreground), scaled into the safe zone.
void paintIcon(Canvas canvas, double size, {bool background = true}) {
  if (background) {
    final rect = Offset.zero & Size.square(size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.15),
          radius: 0.85,
          colors: [_feltCenter, _feltEdge],
        ).createShader(rect),
    );
  }

  // Adaptive icons are masked; keep the art inside the middle ~60%.
  final scale = background ? 1.0 : 0.62;
  canvas
    ..save()
    ..translate(size / 2, size / 2)
    ..scale(scale);

  final cardW = size * 0.46;
  final cardH = cardW * 1.42;
  final radius = Radius.circular(cardW * 0.11);
  RRect card() => RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
        radius,
      );
  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.018);

  // Back card, fanned left.
  canvas
    ..save()
    ..translate(-size * 0.07, size * 0.01)
    ..rotate(-0.26)
    ..drawRRect(card().shift(Offset(0, size * 0.015)), shadow)
    ..drawRRect(card(), Paint()..color = _cardBack)
    ..drawRRect(
      card().deflate(cardW * 0.07),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cardW * 0.025
        ..color = _gold.withValues(alpha: 0.55),
    )
    ..restore();

  // Front card with the gold T.
  canvas
    ..save()
    ..translate(size * 0.07, 0)
    ..rotate(0.12)
    ..drawRRect(card().shift(Offset(0, size * 0.02)), shadow)
    ..drawRRect(card(), Paint()..color = _cardDark)
    ..drawRRect(
      card(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cardW * 0.035
        ..color = _gold,
    )
    ..drawRRect(
      card().deflate(cardW * 0.1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cardW * 0.018
        ..color = _gold.withValues(alpha: 0.5),
    );

  final gold = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_gold, _goldDeep],
    ).createShader(
      Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
    );
  // A slim serif T, after Cormorant Garamond.
  final barW = cardW * 0.6;
  final barH = cardW * 0.1;
  final stemW = cardW * 0.12;
  final stemH = cardH * 0.5;
  final top = -cardH * 0.25;
  final r = Radius.circular(barH * 0.2);
  final serifW = barH * 0.7;
  final serifH = barH * 1.9;
  final footW = stemW * 2.6;
  final footH = barH * 0.6;
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barW / 2, top, barW, barH),
        r,
      ),
      gold,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-stemW / 2, top, stemW, stemH),
        r,
      ),
      gold,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barW / 2, top, serifW, serifH),
        r,
      ),
      gold,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barW / 2 - serifW, top, serifW, serifH),
        r,
      ),
      gold,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-footW / 2, top + stemH - footH, footW, footH),
        r,
      ),
      gold,
    )
    ..restore()
    ..restore();
}
