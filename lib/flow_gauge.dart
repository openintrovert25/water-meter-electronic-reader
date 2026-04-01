import 'dart:math';
import 'package:flutter/material.dart';

/// Animated circular gauge showing real-time flow rate derived from
/// TCRT5000 IR optical pulses counted by the ESP32-CAM.
///
/// Each pulse = 1 liter (configurable via Settings).
/// Flow rate = (pulses_in_window / liters_per_pulse) / elapsed_minutes
class FlowGauge extends StatefulWidget {
  final double flowRate;    // L/min — derived from TCRT5000 pulse count
  final double maxFlowRate; // max expected L/min for residential use

  const FlowGauge({
    super.key,
    required this.flowRate,
    this.maxFlowRate = 15.0,
  });

  @override
  State<FlowGauge> createState() => _FlowGaugeState();
}

class _FlowGaugeState extends State<FlowGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.flowRate).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FlowGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flowRate != widget.flowRate) {
      _previousValue = oldWidget.flowRate;
      _animation =
          Tween<double>(begin: _previousValue, end: widget.flowRate).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sensors, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Live Flow Rate — TCRT5000 IR',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: _animation.value,
                      max: widget.maxFlowRate,
                      primaryColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            _animation.value.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            'L/min',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _FlowStatusChip(flowRate: _animation.value),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Status chip thresholds tuned for TCRT5000 sensitivity:
///   - No flow   : 0 L/min
///   - Possible leak : 0.02 – 0.5 L/min (drip/slow leak detectable by IR)
///   - Normal    : 0.5 – 10 L/min
///   - High usage: > 10 L/min
class _FlowStatusChip extends StatelessWidget {
  final double flowRate;
  const _FlowStatusChip({required this.flowRate});

  @override
  Widget build(BuildContext context) {
    final (label, color) = flowRate <= 0
        ? ('No Flow', Colors.grey)
        : flowRate < 0.5
            ? ('Possible Leak', Colors.orange)
            : flowRate < 10
                ? ('Normal', Colors.green)
                : ('High Usage', Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double max;
  final Color primaryColor;
  final Color backgroundColor;

  _GaugePainter({
    required this.value,
    required this.max,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = size.width * 0.42;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final progress = (value / max).clamp(0.0, 1.0);
    final fgPaint = Paint()
      ..color = _getColor(progress)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        fgPaint,
      );
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 2;
    for (int i = 0; i <= 6; i++) {
      final angle = startAngle + (sweepAngle / 6) * i;
      final inner = Offset(
        center.dx + (radius - 22) * cos(angle),
        center.dy + (radius - 22) * sin(angle),
      );
      final outer = Offset(
        center.dx + (radius + 4) * cos(angle),
        center.dy + (radius + 4) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  Color _getColor(double progress) {
    if (progress < 0.5) {
      return Color.lerp(Colors.blue, Colors.green, progress * 2)!;
    }
    if (progress < 0.8) {
      return Color.lerp(Colors.green, Colors.orange, (progress - 0.5) / 0.3)!;
    }
    return Color.lerp(Colors.orange, Colors.red, (progress - 0.8) / 0.2)!;
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.max != max;
}