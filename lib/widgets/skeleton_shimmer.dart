import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 骨架屏闪烁效果 — 加载时显示灰色占位块
/// 使用 AnimationController + LinearGradient 实现闪烁
class SkeletonShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = PingTheme.radiusSm,
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(_ctrl.value * 2 - 1, 0),
                end: Alignment(_ctrl.value * 2 + 1, 0),
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 骨架卡片 — 模拟订阅列表加载时的占位
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(PingTheme.spaceLg, 0, PingTheme.spaceLg, PingTheme.spaceSm),
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceSm + 2),
      child: Row(
        children: [
          const SkeletonShimmer(width: 42, height: 42, borderRadius: PingTheme.radiusMd),
          const SizedBox(width: PingTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonShimmer(width: 120, height: 14),
                SizedBox(height: 6),
                SkeletonShimmer(width: 80, height: 10),
              ],
            ),
          ),
          const SkeletonShimmer(width: 40, height: 24, borderRadius: PingTheme.radiusSm),
        ],
      ),
    );
  }
}
