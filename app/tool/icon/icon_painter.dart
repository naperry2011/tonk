// Shared icon artwork for the app icon and store assets.
import 'package:flutter/material.dart';

const _feltCenter = Color(0xFF15724A);
const _feltEdge = Color(0xFF062A19);
const _gold = Color(0xFFF2C14E);
const _goldDeep = Color(0xFFC8962A);
const _cardBack = Color(0xFF8E1B2E);
const _cardDark = Color(0xFF14171F);

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
        ..strokeWidth = cardW * 0.045
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
  final barW = cardW * 0.62;
  final barH = cardW * 0.17;
  final stemW = cardW * 0.18;
  final stemH = cardH * 0.52;
  final top = -cardH * 0.25;
  final r = Radius.circular(barH * 0.25);
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
    ..restore()
    ..restore();
}
