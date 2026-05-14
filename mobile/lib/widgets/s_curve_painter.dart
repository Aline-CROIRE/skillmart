import 'package:flutter/material.dart';

class SCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha(30)
      ..style = PaintingStyle.fill;
    
    Path path = Path();
    path.moveTo(0, size.height * 0.2);
    path.cubicTo(size.width * 0.5, size.height * 0.1, size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}