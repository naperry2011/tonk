import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Confetti burst with a big title. Ignores touches; plays once per key.
class Celebration extends StatefulWidget {
  const Celebration({
    super.key,
    required this.title,
    this.color = TonkColors.gold,
    this.duration = const Duration(milliseconds: 2200),
  });

  final String title;
  final Color color;
  final Duration duration;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final List<_Piece> _pieces = _makePieces(widget.color);

  static List<_Piece> _makePieces(Color accent) {
    final random = Random(7);
    const palette = [
      TonkColors.gold,
      TonkColors.cardRed,
      TonkColors.highlight,
      Colors.white,
    ];
    return [
      for (var i = 0; i < 90; i++)
        _Piece(
          angle: -pi / 2 + (random.nextDouble() - 0.5) * pi * 0.9,
          speed: 0.6 + random.nextDouble() * 0.9,
          spin: (random.nextDouble() - 0.5) * 14,
          size: 5 + random.nextDouble() * 7,
          color: i % 5 == 0 ? accent : palette[i % palette.length],
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final titleIn = Curves.elasticOut.transform((t * 2.2).clamp(0, 1));
          final fadeOut = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
          return Opacity(
            opacity: fadeOut.clamp(0, 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _ConfettiPainter(_pieces, t)),
                Center(
                  child: Transform.scale(
                    scale: 0.3 + 0.7 * titleIn,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: widget.color,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 18),
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final reach = size.height * 0.9;
    final paint = Paint();
    for (final p in pieces) {
      final d = p.speed * reach * t;
      final gravity = size.height * 0.9 * t * t;
      final pos = origin + Offset(cos(p.angle) * d, sin(p.angle) * d + gravity);
      paint.color = p.color;
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * t)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
