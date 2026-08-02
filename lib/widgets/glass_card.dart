import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 毛玻璃卡片 — BackdropFilter + RepaintBoundary 隔离
/// 用法: GlassCard(child: ...)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? radius;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius ?? BorderRadius.circular(PingTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(PingTheme.spaceLg),
            decoration: BoxDecoration(
              color: tint ?? (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.65)),
              borderRadius: radius ?? BorderRadius.circular(PingTheme.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 渐变发光按钮 — 带呼吸光效，用 RepaintBoundary 隔离
class GlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? glowColor;
  final bool isLoading;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.glowColor,
    this.isLoading = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    if (widget.onPressed != null) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GlowButton old) {
    super.didUpdateWidget(old);
    if (widget.onPressed != null && !old.onPressed.toString().contains('null')) {
      _ctrl.repeat(reverse: true);
    } else if (widget.onPressed == null) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.glowColor ?? PingTheme.primary;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12 + (_ctrl.value * 8),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: PingTheme.textBody,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 滑动揭示 — 向左滑显示操作按钮，物理回弹
class SwipeToReveal extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final double revealWidth;

  const SwipeToReveal({
    super.key,
    required this.child,
    required this.actions,
    this.revealWidth = 80,
  });

  @override
  State<SwipeToReveal> createState() => _SwipeToRevealState();
}

class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _SwipeToRevealState extends State<SwipeToReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _dragExtent = 0;

  bool _hintShown = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.value = 0;

    // Subtle swipe hint — nudge left 20px then back, once, after 800ms delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_hintShown) {
        setState(() => _hintShown = true);
        _dragExtent = -25;
        _ctrl.animateTo(0.15).then((_) {
          if (mounted) {
            _ctrl.animateTo(0);
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _dragExtent = 0);
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() > widget.revealWidth * 0.5) {
      // 揭示
      _ctrl.animateTo(_dragExtent < 0 ? 1.0 : 0.0);
    } else {
      // 回弹
      _ctrl.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() => _dragExtent += d.delta.dx);
        _dragExtent = _dragExtent.clamp(-widget.revealWidth * widget.actions.length.toDouble(), 0);
      },
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // 背景 actions
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.actions.map((a) => _buildAction(a)).toList(),
                ),
              ),
            ),
          ),
          // 前景
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Transform.translate(
              offset: Offset(_dragExtent + (_ctrl.value * -widget.revealWidth * widget.actions.length - _dragExtent), 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(SwipeAction a) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _ctrl.animateTo(0);
        a.onTap();
      },
      child: Container(
        width: widget.revealWidth,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: a.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(a.icon, size: 22, color: a.color),
            const SizedBox(height: 4),
            Text(a.label, style: TextStyle(fontSize: 10, color: a.color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
