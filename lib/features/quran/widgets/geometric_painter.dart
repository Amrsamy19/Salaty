import 'dart:math';
import 'package:flutter/material.dart';

class GeometricPainter extends CustomPainter {
  final Color color;
  GeometricPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    for (var i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      final path = Path();
      
      final x1 = center.dx + radius * cos(angle);
      final y1 = center.dy + radius * sin(angle);
      
      final nextAngle = ((i + 1) * 45) * pi / 180;
      final x2 = center.dx + radius * cos(nextAngle);
      final y2 = center.dy + radius * sin(nextAngle);
      
      path.moveTo(center.dx, center.dy);
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
      path.close();
      
      canvas.drawPath(path, paint);
      
      // Decorative circles
      canvas.drawCircle(Offset(x1, y1), 4, paint..style = PaintingStyle.fill);
    }
    
    // Outer octagons
    for (var r = 1; r <= 3; r++) {
      _drawOctagon(canvas, center, radius + (r * 20), paint..style = PaintingStyle.stroke);
    }
  }

  void _drawOctagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
