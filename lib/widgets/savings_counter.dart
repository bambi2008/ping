import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 累计省钱计数器 — 显示在 dashboard / settings
/// "You've saved €X this year by cancelling Y subscriptions"
class SavingsCounter extends StatefulWidget {
  final double totalSaved;
  final int cancelledCount;
  final String currencySymbol;

  const SavingsCounter({
    super.key,
    required this.totalSaved,
    required this.cancelledCount,
    required this.currencySymbol,
  });

  @override
  State<SavingsCounter> createState() => _SavingsCounterState();
}

class _SavingsCounterState extends State<SavingsCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _count;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _count = Tween<double>(begin: 0, end: widget.totalSaved).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.microtask(() => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.totalSaved <= 0 || widget.cancelledCount == 0) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceSm),
        padding: const EdgeInsets.all(PingTheme.space2Xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [PingTheme.success.withValues(alpha: 0.15), PingTheme.success.withValues(alpha: 0.05)]
                : [PingTheme.success, PingTheme.success.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(PingTheme.radiusLg),
          border: Border.all(
            color: PingTheme.success.withValues(alpha: isDark ? 0.2 : 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.savings_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: PingTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'ve saved',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: PingTheme.textCaption,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _count,
                    builder: (context, _) => Text(
                      '${widget.currencySymbol}${_count.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'this year',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: PingTheme.textCaption,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.cancelledCount} ${widget.cancelledCount == 1 ? 'sub' : 'subs'} cancelled',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: PingTheme.textCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
