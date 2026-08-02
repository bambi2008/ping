import 'package:flutter/material.dart';

/// 自定义页面转场 — spring 滑入 + 淡入，GPU 友好
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset slideOffset;

  SlideFadeRoute({
    required this.page,
    this.slideOffset = const Offset(0, 0.08),
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return RepaintBoundary(
              child: FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: slideOffset,
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// 弹性缩放路由 — 用于对话框/卡片
class ScaleFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadeRoute({required this.page, super.settings})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
            return RepaintBoundary(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// 交错进场 — 用单一 AnimationController 驱动多个子 widget
/// 每个子 widget 按延迟顺序淡入 + 上移
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  final double itemDelay; // 秒
  final Duration duration;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.itemDelay = 0.08,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    Future.microtask(() => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (i) {
        final start = (i * widget.itemDelay).clamp(0.0, 0.8);
        final end = (start + 0.2).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = _ctrl.value;
            final visible = t >= start;
            final localT = ((t - start) / (end - start)).clamp(0.0, 1.0);
            final curve = Curves.easeOutCubic.transform(localT);
            return RepaintBoundary(
              child: Opacity(
                opacity: visible ? curve : 0.0,
                child: Transform.translate(
                  offset: Offset(0, (1 - curve) * 20),
                  child: child,
                ),
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}

/// 弹性出现 — 单个 widget 的弹性缩放进场
class ElasticAppear extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const ElasticAppear({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<ElasticAppear> createState() => _ElasticAppearState();
}

class _ElasticAppearState extends State<ElasticAppear>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(widget.delay, () => mounted ? _ctrl.forward() : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
          child: widget.child,
        ),
      ),
    );
  }
}
