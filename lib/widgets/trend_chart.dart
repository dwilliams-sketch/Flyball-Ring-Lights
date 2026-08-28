import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/performance_report.dart';
import '../theme/app_theme.dart';

class TrendChart extends StatelessWidget {
  final List<TrendPoint> points;

  const TrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final timed = points.where((p) => p.averageTime != null).toList();
    if (timed.length < 2) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Record at least two competitions with team times to show a speed trend.')),
      );
    }

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(timed),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendPoint> points;

  _TrendPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.averageTime!).toList();
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if ((maxV - minV).abs() < .05) {
      minV -= .05;
      maxV += .05;
    }

    const left = 44.0;
    const right = 12.0;
    const top = 16.0;
    const bottom = 34.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    final grid = Paint()..color = Colors.white12..strokeWidth = 1;
    final line = Paint()
      ..color = AppTheme.gold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = AppTheme.gold;
    final textStyle = const TextStyle(color: Colors.white54, fontSize: 9);

    for (var i = 0; i <= 3; i++) {
      final y = top + h * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      final value = maxV - (maxV - minV) * i / 3;
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(2), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = left + (points.length == 1 ? w / 2 : w * i / (points.length - 1));
      final normalized = (points[i].averageTime! - minV) / (maxV - minV);
      final y = top + h * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dot);

      if (i == 0 || i == points.length - 1 || points.length <= 5) {
        var label = points[i].label;
        if (label.length > 12) label = '${label.substring(0, 11)}…';
        final tp = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: 80);
        tp.paint(canvas, Offset(x - tp.width / 2, top + h + 8));
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.points != points;
}
