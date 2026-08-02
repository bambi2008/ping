import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 可截图分享的支出摘要卡 — PH 级别的 "screenshot moment"
/// 显示在 dashboard 顶部，可截图分享到社交媒体
class ShareableSummary extends StatelessWidget {
  final double monthlyTotal;
  final double yearlyTotal;
  final int activeCount;
  final String currencySymbol;
  final Map<String, double> categoryBreakdown;

  const ShareableSummary({
    super.key,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.activeCount,
    required this.currencySymbol,
    required this.categoryBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topCategories = (categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg),
      padding: const EdgeInsets.all(PingTheme.space2Xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)]
              : [const Color(0xFF6C5CE7), const Color(0xFF8B7CF6)],
        ),
        borderRadius: BorderRadius.circular(PingTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: PingTheme.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Ping',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: PingTheme.textSmall,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              Text('My subscriptions',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: PingTheme.textCaption,
                  )),
            ],
          ),

          const SizedBox(height: PingTheme.space2Xl),

          // Big number
          Text('I spend',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: PingTheme.textBody,
                fontWeight: FontWeight.w400,
              )),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${yearlyTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  height: 1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 6),
                child: Text('/year',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: PingTheme.textBody,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text('on $activeCount subscriptions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: PingTheme.textSmall,
              )),

          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: PingTheme.space2Xl),
            // Category bars
            ...topCategories.map((entry) {
              final pct = (entry.value / monthlyTotal * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: PingTheme.spaceSm),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                        child: LinearProgressIndicator(
                          value: entry.value / topCategories.first.value,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                        ),
                      ),
                    ),
                    const SizedBox(width: PingTheme.spaceSm),
                    SizedBox(
                      width: 80,
                      child: Text(entry.key,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: PingTheme.textCaption,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    Text('$currencySymbol${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: PingTheme.textCaption,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: PingTheme.spaceLg),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Track yours → ping.app',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: PingTheme.textCaption,
                    fontWeight: FontWeight.w500,
                  )),
              Icon(Icons.local_fire_department,
                  size: 14, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ],
      ),
    );
  }
}
