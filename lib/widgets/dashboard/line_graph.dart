// lib/widgets/dashboard/line_graph.dart
import 'package:flutter/material.dart';

class LineGraph extends StatelessWidget {
  final List<double> data;
  final List<String> months;
  final Color color;
  final Color fillColor;
  final double height;
  final bool showDots;

  const LineGraph({
    super.key,
    required this.data,
    required this.months,
    required this.color,
    required this.fillColor,
    this.height = 160,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Handle empty data
    if (data.isEmpty || months.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Calculate max and min values for Y-axis
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    
    // Add padding to max and min for better visualization
    final valuePadding = (maxValue - minValue) * 0.1;
    final effectiveMax = maxValue + valuePadding;
    final effectiveMin = minValue - valuePadding > 0 ? minValue - valuePadding : 0.0;

    // Show all months, but if more than 8, show every 2nd
    final displayMonths = months.asMap().entries
        .where((entry) => months.length > 8 ? entry.key % 2 == 0 : true)
        .toList();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          const padding = EdgeInsets.only(left: 40, right: 16, top: 16, bottom: 30);
          final chartWidth = width - padding.left - padding.right;
          final chartHeight = height - padding.top - padding.bottom;
          
          return Stack(
            children: [
              // Y-axis labels
              Positioned(
                left: 0,
                top: padding.top,
                bottom: padding.bottom,
                width: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      effectiveMax.toStringAsFixed(0),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ((effectiveMax + effectiveMin) / 2).toStringAsFixed(0),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      effectiveMin.toStringAsFixed(0),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Graph area
              Positioned(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
                child: CustomPaint(
                  painter: LineGraphPainter(
                    data: data,
                    color: color,
                    fillColor: fillColor,
                    maxValue: effectiveMax,
                    minValue: effectiveMin,
                    showDots: showDots,
                  ),
                  size: Size(chartWidth, chartHeight),
                ),
              ),
              // X-axis labels
              Positioned(
                left: padding.left,
                right: padding.right,
                bottom: 0,
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: displayMonths.map((entry) {
                    return Expanded(
                      child: Text(
                        entry.value,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom Painter for Line Graph
class LineGraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color fillColor;
  final double maxValue;
  final double minValue;
  final bool showDots;

  const LineGraphPainter({
    required this.data,
    required this.color,
    required this.fillColor,
    required this.maxValue,
    required this.minValue,
    this.showDots = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotStrokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final range = maxValue - minValue;
    if (range == 0) {
      // If all values are the same, draw a straight line
      final centerY = size.height / 2;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        paint,
      );
      return;
    }
    
    final stepX = size.width / (data.length - 1);
    final stepY = size.height / range;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] - minValue) * stepY;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (data[i - 1] - minValue) * stepY;
        final cp1x = prevX + (x - prevX) * 0.5;
        final cp2x = prevX + (x - prevX) * 0.5;
        path.cubicTo(cp1x, prevY, cp2x, y, x, y);
        fillPath.cubicTo(cp1x, prevY, cp2x, y, x, y);
      }
    }

    final lastX = (data.length - 1) * stepX;
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    // Draw filled area with gradient
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    if (showDots) {
      for (int i = 0; i < data.length; i++) {
        final x = i * stepX;
        final y = size.height - (data[i] - minValue) * stepY;
        canvas.drawCircle(Offset(x, y), 6, dotPaint);
        canvas.drawCircle(Offset(x, y), 3, dotStrokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}