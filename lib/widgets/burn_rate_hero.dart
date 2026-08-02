import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'fire_particles.dart';

/// Burn Rate Hero — 替代普通数字卡，让用户"感受"烧钱速度
/// 显示: 月费大数字 + "€X.XX/hour" + 可视化烧钱速度条 + 年度总额
class BurnRateHero extends StatefulWidget {
  final double monthlyTotal;
  final double yearlyTotal;
  final int activeCount;
  final String currencySymbol;
  final double? momChange;
  final VoidCallback? onViewAll;
  final VoidCallback? onCalendar;

  const BurnRateHero({
    super.key,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.activeCount,
    required this.currencySymbol,
    this.momChange,
    this.onViewAll,
    this.onCalendar,
  });

  @override
  State<BurnRateHero> createState() => _BurnRateHeroState();
}

class _BurnRateHeroState extends State<BurnRateHero>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _countCtrl;
  late Animation<double> _countAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _countAnim = Tween<double>(begin: 0, end: widget.monthlyTotal).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
    );

    _pulseCtrl.repeat(reverse: true);
    _countCtrl.forward();
  }

  @override
  void didUpdateWidget(BurnRateHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monthlyTotal != widget.monthlyTotal) {
      _countAnim = Tween<double>(begin: oldWidget.monthlyTotal, end: widget.monthlyTotal).animate(
        CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
      );
      _countCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perHour = widget.monthlyTotal / 730; // 24h * ~30.4 days
    final perDay = widget.monthlyTotal / 30.4;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceSm),
      child: Stack(
        children: [
          // Main card
          Container(
            padding: const EdgeInsets.all(PingTheme.space2Xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF252540)]
                    : [PingTheme.primary, PingTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(PingTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: PingTheme.primary.withValues(alpha: isDark ? 0.3 : 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: "Monthly burn" + MoM badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Pulsing flame
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, _) => Opacity(
                            opacity: 0.6 + _pulseCtrl.value * 0.4,
                            child: const Text('🔥', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Monthly burn',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: PingTheme.textSmall,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                    if (widget.momChange != null)
                      _MoMBadge(change: widget.momChange!, symbol: widget.currencySymbol)
                    else
                      Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                  ],
                ),

                const SizedBox(height: PingTheme.spaceSm),

                // Big number
                AnimatedBuilder(
                  animation: _countAnim,
                  builder: (context, _) => Text(
                    '${widget.currencySymbol}${_countAnim.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                const SizedBox(height: PingTheme.spaceXs),

                // Burn rate per hour/day
                Row(
                  children: [
                    _rateChip('${widget.currencySymbol}${perHour.toStringAsFixed(2)}/hr', Icons.local_fire_department),
                    const SizedBox(width: PingTheme.spaceSm),
                    _rateChip('${widget.currencySymbol}${perDay.toStringAsFixed(2)}/day', Icons.today),
                  ],
                ),

                const SizedBox(height: PingTheme.spaceLg),

                // Yearly total bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceSm + 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Text('Yearly total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: PingTheme.textCaption,
                            fontWeight: FontWeight.w500,
                          )),
                      const Spacer(),
                      Text('${widget.currencySymbol}${widget.yearlyTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: PingTheme.textBody,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          )),
                      const SizedBox(width: PingTheme.spaceSm),
                      Text('· ${widget.activeCount} active',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: PingTheme.textCaption,
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: PingTheme.spaceMd),

                // Action pills
                Row(
                  children: [
                    _pillBtn('View All', Icons.list_alt, widget.onViewAll),
                    const SizedBox(width: PingTheme.spaceSm),
                    _pillBtn('Calendar', Icons.calendar_today, widget.onCalendar),
                  ],
                ),
              ],
            ),
          ),

          // Subtle fire glow behind number
          Positioned(
            top: 40, right: -10, left: -10, bottom: 40,
            child: RepaintBoundary(
              child: FireParticles(intensity: 0.15),
            ),
          ),
          // Glow overlay
          Positioned(
            top: -20, right: -20,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) => Container(
                width: 120 + _pulseCtrl.value * 20,
                height: 120 + _pulseCtrl.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PingTheme.danger.withValues(alpha: 0.15 * _pulseCtrl.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: PingTheme.textCaption,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }

  Widget _pillBtn(String label, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: PingTheme.textSmall)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoMBadge extends StatelessWidget {
  final double change;
  final String symbol;
  const _MoMBadge({required this.change, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final isDecrease = change < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDecrease
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(PingTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDecrease ? Icons.arrow_downward : Icons.arrow_upward, size: 12,
              color: isDecrease ? PingTheme.success : Colors.redAccent),
          const SizedBox(width: 2),
          Text('${isDecrease ? '-' : '+'}$symbol${change.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: isDecrease ? PingTheme.success : Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}
