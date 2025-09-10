import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingAnimationWidget extends StatefulWidget {
  const CustomLoadingAnimationWidget({super.key});

  @override
  State<CustomLoadingAnimationWidget> createState() =>
      _CustomLoadingAnimationWidgetState();
}

class _CustomLoadingAnimationWidgetState
    extends State<CustomLoadingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(painter: _LoaderPainter(_controller.value));
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  _LoaderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    final center = size.center(Offset.zero);
    final radius = size.width * 0.35;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi / 8);
      final opacity = ((i / 8 + progress) % 1.0);
      paint.color = Colors.deepOrange.withOpacity(opacity);

      final start = Offset(
        center.dx + radius * math.sin(angle),
        center.dy + radius * math.cos(angle),
      );

      final end = Offset(
        center.dx + (radius + 10) * math.sin(angle),
        center.dy + (radius + 10) * math.cos(angle),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) => true;
}
