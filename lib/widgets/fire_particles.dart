import 'dart:math';
import 'package:flutter/material.dart';

/// 火焰粒子效果 — 高效 CustomPaint，30 个粒子
/// 必须用 RepaintBoundary 包裹以隔离重绘区域
class FireParticles extends StatefulWidget {
  final double intensity; // 0.0-1.0, 越高火焰越大
  final Color? baseColor;

  const FireParticles({
    super.key,
    this.intensity = 1.0,
    this.baseColor,
  });

  @override
  State<FireParticles> createState() => _FireParticlesState();
}

class _FireParticlesState extends State<FireParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary 隔离重绘 — 不影响周围 widget
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _FirePainter(
            animation: _ctrl,
            intensity: widget.intensity,
            baseColor: widget.baseColor ?? Colors.orange,
          ),
        ),
      ),
    );
  }
}

class _FirePainter extends CustomPainter {
  final Animation<double> animation;
  final double intensity;
  final Color baseColor;

  // 固定粒子池 — 不在 paint 里创建对象
  static final List<_Particle> _particles = List.generate(35, (i) => _Particle.random(i));

  _FirePainter({required this.animation, required this.intensity, required this.baseColor})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final cx = size.width / 2;
    final cy = size.height * 0.85;

    for (final p in _particles) {
      // 用数学公式而非随机数 — 稳定且高效
      final phase = (t + p.seed * 0.1) % 1.0;
      final lifeT = phase;

      // 上升 + 左右摆动
      final y = cy - lifeT * size.height * 0.7 * intensity;
      final wobble = sin(lifeT * pi * 3 + p.seed) * 15 * intensity;
      final x = cx + wobble + p.offsetX * intensity;

      // 大小递减
      final radius = (1 - lifeT) * p.size * intensity;

      // 透明度递减
      final alpha = (1 - lifeT) * 0.6;

      // 颜色渐变：底部橙红 → 顶部黄白
      final color = Color.lerp(
        baseColor,
        const Color(0xFFFFD700),
        lifeT,
      )!.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
    }

    // 底部发光层
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.3 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 60 * intensity));
    canvas.drawCircle(Offset(cx, cy), 60 * intensity, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FirePainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.baseColor != baseColor;
}

class _Particle {
  final double seed;
  final double offsetX;
  final double size;

  _Particle.random(int index)
      : seed = (index * 7 + 3) % 10 / 10.0,
        offsetX = ((index * 13) % 20 - 10) * 0.8,
        size = 3.0 + (index % 5) * 1.5;
}
