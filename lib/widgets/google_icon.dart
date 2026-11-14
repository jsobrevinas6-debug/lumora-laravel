import 'package:flutter/material.dart';

/// Official Google "G" Multi-Color Vector Icon
/// Follows Google's exact brand geometry, cubic curves, and official color hexes:
/// - Blue:   #4285F4
/// - Green:  #34A853
/// - Yellow: #FBBC05
/// - Red:    #EA4335
class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _OfficialGoogleGLogoPainter(),
      ),
    );
  }
}

class _OfficialGoogleGLogoPainter extends CustomPainter {
  const _OfficialGoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue path (#4285F4)
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final bluePath = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.48, 23.675, 10.73, 23.55, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.82)
      ..lineTo(18.59, 14.82)
      ..cubicTo(18.3, 16.32, 17.43, 17.58, 16.14, 18.44)
      ..lineTo(16.14, 21.46)
      ..lineTo(20.11, 21.46)
      ..cubicTo(22.43, 19.32, 23.745, 16.19, 23.745, 12.27)
      ..close();
    canvas.drawPath(bluePath, paintBlue);

    // 2. Green path (#34A853)
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 20.11, 21.46)
      ..lineTo(16.14, 18.44)
      ..cubicTo(15.03, 19.18, 13.62, 19.64, 12.0, 19.64)
      ..cubicTo(8.87, 19.64, 6.22, 17.52, 5.27, 14.68)
      ..lineTo(1.17, 14.68)
      ..lineTo(1.17, 17.85)
      ..cubicTo(3.19, 21.87, 7.34, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, paintGreen);

    // 3. Yellow path (#FBBC05)
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final yellowPath = Path()
      ..moveTo(5.27, 14.68)
      ..cubicTo(5.02, 13.82, 4.88, 12.92, 4.88, 12.0)
      ..cubicTo(4.88, 11.08, 5.02, 10.18, 5.27, 9.32)
      ..lineTo(5.27, 6.15)
      ..lineTo(1.17, 6.15)
      ..cubicTo(0.42, 7.64, 0.0, 9.72, 0.0, 12.0)
      ..cubicTo(0.0, 14.28, 0.42, 16.36, 1.17, 17.85)
      ..lineTo(5.27, 14.68)
      ..close();
    canvas.drawPath(yellowPath, paintYellow);

    // 4. Red path (#EA4335)
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final redPath = Path()
      ..moveTo(12.0, 4.36)
      ..cubicTo(13.76, 4.36, 15.34, 4.97, 16.59, 6.16)
      ..lineTo(20.2, 2.55)
      ..cubicTo(17.95, 0.97, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.34, 0.0, 3.19, 2.13, 1.17, 6.15)
      ..lineTo(5.27, 9.32)
      ..cubicTo(6.22, 6.48, 8.87, 4.36, 12.0, 4.36)
      ..close();
    canvas.drawPath(redPath, paintRed);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
