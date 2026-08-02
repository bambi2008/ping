import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'press_scale.dart';

/// 取消庆祝 — 当用户取消订阅时显示，彩纸 + "You just saved €X/year!"
class CancelCelebration extends StatefulWidget {
  final String subscriptionName;
  final double monthlyAmount;
  final String currencySymbol;
  final VoidCallback onDismiss;

  const CancelCelebration({
    super.key,
    required this.subscriptionName,
    required this.monthlyAmount,
    required this.currencySymbol,
    required this.onDismiss,
  });

  @override
  State<CancelCelebration> createState() => _CancelCelebrationState();
}

class _CancelCelebrationState extends State<CancelCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yearlySavings = widget.monthlyAmount * 12;

    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: SafeArea(
        child: Center(
          child: Stack(
            children: [
              // Confetti layer
              Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_ctrl))),

              // Dialog
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, _) => Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: PingTheme.space3Xl),
                    padding: const EdgeInsets.all(PingTheme.space3Xl),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(PingTheme.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: PingTheme.success.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [PingTheme.success, PingTheme.success.withValues(alpha: 0.7)],
                            ),
                            boxShadow: [
                              BoxShadow(color: PingTheme.success.withValues(alpha: 0.3), blurRadius: 20),
                            ],
                          ),
                          child: const Icon(Icons.emoji_events, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: PingTheme.space2Xl),

                        Text('Subscription cancelled!',
                            style: TextStyle(
                              fontSize: PingTheme.textHeadline,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            )),
                        const SizedBox(height: PingTheme.spaceSm),

                        Text('${widget.subscriptionName} is gone.',
                            style: TextStyle(
                              color: PingTheme.subtleText(context),
                              fontSize: PingTheme.textBody,
                            )),
                        const SizedBox(height: PingTheme.space2Xl),

                        // Savings
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: PingTheme.space2Xl, vertical: PingTheme.spaceLg),
                          decoration: BoxDecoration(
                            color: PingTheme.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(PingTheme.radiusLg),
                            border: Border.all(color: PingTheme.success.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            children: [
                              Text('You just saved',
                                  style: TextStyle(
                                    color: PingTheme.subtleText(context),
                                    fontSize: PingTheme.textSmall,
                                    fontWeight: FontWeight.w500,
                                  )),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: yearlySavings),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => Text(
                                  '${widget.currencySymbol}${value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: PingTheme.success,
                                    letterSpacing: -1,
                                    height: 1.0,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              Text('per year',
                                  style: TextStyle(
                                    color: PingTheme.success.withValues(alpha: 0.7),
                                    fontSize: PingTheme.textSmall,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),

                        const SizedBox(height: PingTheme.space2Xl),

                        PressScale(
                          onTap: widget.onDismiss,
                          child: Container(
                            width: double.infinity, height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [PingTheme.success, PingTheme.success.withValues(alpha: 0.85)]),
                              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                              boxShadow: [BoxShadow(color: PingTheme.success.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: const Center(
                              child: Text('Nice! 🎉',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: PingTheme.textBody, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 彩纸粒子效果
class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final Random _rng = Random(42); // 固定种子

  _ConfettiPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final centerX = size.width / 2;
    final centerY = size.height / 3;

    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * pi * 2;
      final speed = 200 + _rng.nextDouble() * 300;
      final dx = centerX + cos(angle) * speed * progress;
      final dy = centerY + sin(angle) * speed * progress + progress * 300; // gravity

      // Wrap around if off screen
      if (dy > size.height + 50) continue;

      final colors = [
        PingTheme.success,
        PingTheme.primary,
        PingTheme.secondary,
        PingTheme.warning,
        PingTheme.danger,
        const Color(0xFF6C5CE7),
      ];
      final color = colors[i % colors.length];
      final rotation = progress * pi * 4 + i;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);

      final paint = Paint()..color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 4), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
