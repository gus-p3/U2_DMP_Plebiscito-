import 'dart:math';
import 'package:flutter/material.dart';

class ConfetiPainter extends CustomPainter {
  final double progreso;
  final List<Color> colores = const [
    Colors.amber,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.greenAccent,
    Colors.deepOrangeAccent,
    Colors.purpleAccent,
  ];

  ConfetiPainter({required this.progreso});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final random = Random(42);

    for (int i = 0; i < 70; i++) {
      final initialX = random.nextDouble() * size.width;
      final speedFactor = 0.6 + random.nextDouble() * 0.8;
      final y = ((progreso * size.height * speedFactor) +
              (random.nextDouble() * size.height * 0.5)) %
          size.height;
      final xOffset = sin((progreso * 2 * pi) + i) * 20;
      final x = (initialX + xOffset).clamp(0.0, size.width);

      final rotacion = (progreso * 4 * pi) + (i * 0.2);
      final ancho = 6.0 + (random.nextDouble() * 6.0);
      final alto = 10.0 + (random.nextDouble() * 8.0);

      final paint = Paint()
        ..color = colores[i % colores.length]
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotacion);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: ancho, height: alto),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfetiPainter oldDelegate) =>
      oldDelegate.progreso != progreso;
}

class ConfetiAnimado extends StatefulWidget {
  final Widget child;
  const ConfetiAnimado({super.key, required this.child});

  @override
  State<ConfetiAnimado> createState() => _ConfetiAnimadoState();
}

class _ConfetiAnimadoState extends State<ConfetiAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: ConfetiPainter(progreso: _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
