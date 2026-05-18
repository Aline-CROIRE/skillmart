import 'package:flutter/material.dart';

class SCurvePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {

    // Paint object controls color and style
    final paint = Paint()
      ..color = Colors.green // Background curve color
      ..style = PaintingStyle.fill;

    // Path is used to draw custom shapes
    Path path = Path();

    // Starting point
    path.moveTo(0, size.height * 0.2);

    // Creates the S-like curve
    path.cubicTo(
      size.width * 0.5,  // control point 1 x
      size.height * 0.1, // control point 1 y

      size.width * 0.5,  // control point 2 x
      size.height * 0.4, // control point 2 y

      size.width,        // ending point x
      size.height * 0.3, // ending point y
    );

    // Complete the bottom shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    // Draw the shape on screen
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}