import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../themes.dart';

/// Table background with a lamp glow, vignette, and film grain.
class LofiBackdrop extends StatelessWidget {
  const LofiBackdrop({super.key, required this.table, required this.child});

  final TableTheme table;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: table.decoration,
      child: CustomPaint(
        painter: _GrainPainter(glow: table.glow),
        child: child,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.glow});

  final Color glow;

  static ui.Image? _tile;

  /// A 160px tile of soft monochrome noise, built once per app run.
  static ui.Image _grainTile() {
    final cached = _tile;
    if (cached != null) return cached;
    const size = 160;
    final random = Random(42);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    for (var i = 0; i < 2600; i++) {
      final light = random.nextBool();
      paint.color = (light ? Colors.white : Colors.black).withValues(
        alpha: 0.25 + random.nextDouble() * 0.5,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size,
          random.nextDouble() * size,
          1,
          1,
        ),
        paint,
      );
    }
    return _tile = recorder.endRecording().toImageSync(size, size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Warm lamp glow from above the table.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.75),
          radius: 0.9,
          colors: [glow.withValues(alpha: 0.16), glow.withValues(alpha: 0)],
        ).createShader(rect),
    );

    // Vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );

    // Film grain.
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..shader = ImageShader(
          _grainTile(),
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        )
        ..blendMode = BlendMode.softLight,
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.glow != glow;
}
