import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 动画甜甜圈图 — 自绘，进场时弧线从 0 度画到目标角度
/// 单一 AnimationController 驱动，RepaintBoundary 隔离
class AnimatedDonut extends StatefulWidget {
  final Map<String, double> data;
  final Map<String, Color>? colors;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final String? centerSubLabel;

  const AnimatedDonut({
    super.key,
    required this.data,
    this.colors,
    this.size = 160,
    this.strokeWidth = 18,
    this.centerLabel,
    this.centerSubLabel,
  });

  @override
  State<AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<AnimatedDonut>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.microtask(() => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DonutPainter(
                  data: widget.data,
                  colors: widget.colors ?? {},
                  progress: Curves.easeOutCubic.transform(_ctrl.value),
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            ),
            if (widget.centerLabel != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.centerLabel!,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  if (widget.centerSubLabel != null)
                    Text(widget.centerSubLabel!,
                        style: TextStyle(
                          fontSize: PingTheme.textCaption,
                          color: PingTheme.subtleText(context),
                          fontWeight: FontWeight.w500,
                        )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colors;
  final double progress;
  final double strokeWidth;

  _DonutPainter({
    required this.data,
    required this.colors,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - strokeWidth / 2 - 4;
    const startAngle = -pi / 2; // 从顶部开始

    // 背景圈
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.grey.withValues(alpha: 0.08),
    );

    // 各段弧
    double currentAngle = startAngle;
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final defaultColors = [
      PingTheme.primary,
      PingTheme.secondary,
      PingTheme.warning,
      PingTheme.danger,
      PingTheme.success,
      const Color(0xFF6C5CE7),
      const Color(0xFF00B894),
      const Color(0xFFE17055),
    ];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final sweep = (entry.value / total) * 2 * pi * progress;
      final color = colors[entry.key] ?? defaultColors[i % defaultColors.length];

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        currentAngle,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color
          ..strokeCap = StrokeCap.round,
      );

      currentAngle += (entry.value / total) * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.data != data;
}
