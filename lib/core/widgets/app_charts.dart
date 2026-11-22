import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});
}

/// 1. Futuristic Telemetric Area Chart with glowing gradient fill & interactive hover
class TelemetricAreaChart extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<ChartDataPoint> data;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;
  final String unit;

  const TelemetricAreaChart({
    super.key,
    required this.title,
    this.subtitle,
    required this.data,
    this.primaryColor = AppColors.accentPrimary,
    this.secondaryColor = AppColors.accentSecondary,
    this.height = 200,
    this.unit = '',
  });

  @override
  State<TelemetricAreaChart> createState() => _TelemetricAreaChartState();
}

class _TelemetricAreaChartState extends State<TelemetricAreaChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final maxVal = widget.data.map((e) => e.value).reduce(math.max);
    final minVal = widget.data.map((e) => e.value).reduce(math.min);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (_hoveredIndex != null && _hoveredIndex! < widget.data.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.primaryColor.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      '${widget.data[_hoveredIndex!].label}: ${widget.data[_hoveredIndex!].value.toStringAsFixed(1)} ${widget.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    final boxWidth = constraints.maxWidth;
                    final step = boxWidth / (widget.data.length - 1);
                    final idx = (event.localPosition.dx / step).round().clamp(
                      0,
                      widget.data.length - 1,
                    );
                    setState(() => _hoveredIndex = idx);
                  },
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, widget.height),
                    painter: _AreaChartPainter(
                      data: widget.data,
                      maxVal: maxVal == minVal ? maxVal + 1 : maxVal,
                      minVal: minVal,
                      primaryColor: widget.primaryColor,
                      secondaryColor: widget.secondaryColor,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: widget.data.asMap().entries.map((entry) {
              final isHovered = entry.key == _hoveredIndex;
              return Expanded(
                child: Text(
                  entry.value.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                    color: isHovered
                        ? widget.primaryColor
                        : AppColors.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxVal;
  final double minVal;
  final Color primaryColor;
  final Color secondaryColor;
  final int? hoveredIndex;

  _AreaChartPainter({
    required this.data,
    required this.maxVal,
    required this.minVal,
    required this.primaryColor,
    required this.secondaryColor,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withAlpha(60)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final areaPath = Path();
    final stepX = size.width / (data.length - 1);
    final range = maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i].value - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 20) + 10);
      points.add(Offset(x, y));
    }

    // Build curved path
    path.moveTo(points[0].dx, points[0].dy);
    areaPath.moveTo(points[0].dx, size.height);
    areaPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      areaPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Fill gradient
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withAlpha(80),
        primaryColor.withAlpha(10),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Points & Hover point
    for (int i = 0; i < points.length; i++) {
      final isHovered = i == hoveredIndex;
      final pointPaint = Paint()
        ..color = isHovered ? Colors.white : primaryColor
        ..style = PaintingStyle.fill;

      if (isHovered) {
        // Glowing halo on hover
        final haloPaint = Paint()
          ..color = primaryColor.withAlpha(120)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i], 8, haloPaint);
        canvas.drawCircle(points[i], 4, pointPaint);
      } else {
        canvas.drawCircle(points[i], 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) => true;
}

/// 2. Futuristic Circular Capacity Gauge
class CircularCapacityGauge extends StatelessWidget {
  final String title;
  final double percentage; // 0.0 to 1.0
  final String centerLabel;
  final String centerSublabel;
  final Color activeColor;
  final double size;

  const CircularCapacityGauge({
    super.key,
    required this.title,
    required this.percentage,
    required this.centerLabel,
    required this.centerSublabel,
    this.activeColor = AppColors.accentPrimary,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadialGaugePainter(
                percentage: percentage.clamp(0.0, 1.0),
                activeColor: activeColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      centerSublabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double percentage;
  final Color activeColor;

  _RadialGaugePainter({required this.percentage, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    // Track Background Arc
    final bgPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Active Glowing Progress Arc
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 1.5 * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) => true;
}

/// 3. Comparative Telemetry Bar Chart
class TelemetryBarChart extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ChartDataPoint> data;
  final double? referenceThreshold;
  final String? thresholdLabel;

  const TelemetryBarChart({
    super.key,
    required this.title,
    this.subtitle,
    required this.data,
    this.referenceThreshold,
    this.thresholdLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.map((e) => e.value).reduce(math.max);
    final ceiling = math.max(maxVal, referenceThreshold ?? 0.0) * 1.15;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (thresholdLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(width: 12, height: 2, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          thresholdLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 172,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((item) {
                final heightFactor = ceiling > 0 ? (item.value / ceiling) : 0.0;
                final isUnderThreshold =
                    referenceThreshold != null &&
                    item.value < referenceThreshold!;

                final barColor = isUnderThreshold
                    ? AppColors.danger
                    : AppColors.accentPrimary;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          item.value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: math.max(112 * heightFactor, 4.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [barColor, barColor.withAlpha(120)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withAlpha(50),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
