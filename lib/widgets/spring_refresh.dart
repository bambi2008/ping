import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../app/theme.dart';

/// 自定义弹簧 Pull-to-Refresh
/// - 拖动时显示一个弹性缩放的 Ping logo
/// - 释放后用 SpringSimulation 回弹
/// - 刷新中旋转动画
/// 完全用 CustomPaint + RepaintBoundary，GPU 友好
class SpringRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerDistance;

  const SpringRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 90,
  });

  @override
  State<SpringRefresh> createState() => _SpringRefreshState();
}

class _SpringRefreshState extends State<SpringRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _dragOffset = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    _ctrl.repeat();
    HapticFeedback.mediumImpact();
    await widget.onRefresh();
    if (mounted) {
      _ctrl.stop();
      setState(() => _isRefreshing = false);
      _springBack();
    }
  }

  void _springBack() {
    final spring = SpringDescription(
      mass: 30,
      stiffness: 1000,
      damping: 0.8,
    );
    final simulation = SpringSimulation(spring, _dragOffset, 0, 0);
    _ctrl.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isRefreshing) return false;

        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < 0) {
            setState(() => _dragOffset = -notification.metrics.pixels * 0.5);
          } else if (_dragOffset > 0) {
            setState(() => _dragOffset = 0);
          }
        } else if (notification is OverscrollNotification) {
          setState(() => _dragOffset = (_dragOffset + notification.overscroll * 0.4)
              .clamp(0.0, widget.triggerDistance * 1.5));
        } else if (notification is ScrollEndNotification) {
          if (_dragOffset >= widget.triggerDistance && !_isRefreshing) {
            _handleRefresh();
          } else if (_dragOffset > 0) {
            _springBack();
          }
        }
        return false;
      },
      child: Stack(
        children: [
          // Main content
          Transform.translate(
            offset: Offset(0, _isRefreshing ? 60 : _dragOffset),
            child: widget.child,
          ),
          // Refresh indicator
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _isRefreshing ? 60 : _dragOffset,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _RefreshPainter(
                    progress: (_dragOffset / widget.triggerDistance).clamp(0.0, 1.0),
                    isRefreshing: _isRefreshing,
                    rotation: _ctrl.value * 3.14159 * 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RefreshPainter extends CustomPainter {
  final double progress;
  final bool isRefreshing;
  final double rotation;

  _RefreshPainter({
    required this.progress,
    required this.isRefreshing,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final scale = (isRefreshing ? 1.0 : 0.3 + progress * 0.7).clamp(0.0, 1.0);
    final radius = 18.0 * scale;

    if (radius < 2) return;

    // Ping logo circle
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    // Background circle with gradient
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [PingTheme.primary, PingTheme.primaryLight],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, paint);

    // "P" text — 用 drawRect 模拟 (避免文字渲染开销)
    final pPaint = Paint()..color = Colors.white;
    final pWidth = radius * 0.5;
    final pHeight = radius * 0.7;
    // P 的竖线
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-radius * 0.15, 0), width: pWidth * 0.4, height: pHeight),
        const Radius.circular(2),
      ),
      pPaint,
    );
    // P 的上半圆
    canvas.drawArc(
      Rect.fromCenter(center: Offset(radius * 0.05, -radius * 0.25), width: pWidth * 0.8, height: pHeight * 0.5),
      0,
      3.14159,
      false,
      pPaint..style = PaintingStyle.fill,
    );

    canvas.restore();

    // 进度弧（非刷新时）
    if (!isRefreshing && progress > 0.1) {
      final arcPaint = Paint()
        ..color = PingTheme.primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius + 6),
        -1.5708, // 从顶部开始
        3.14159 * 2 * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RefreshPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isRefreshing != isRefreshing ||
      oldDelegate.rotation != rotation;
}
