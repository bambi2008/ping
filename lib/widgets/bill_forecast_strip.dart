import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'brand_icon.dart';
import '../models/subscription.dart';

/// 7 天账单预报条 — 横向滚动，每张卡片显示一个即将到期的订阅
/// 卡片颜色随紧急程度变化：蓝→橙→红
class BillForecastStrip extends StatefulWidget {
  final List<Subscription> upcoming;
  final String currencySymbol;
  final void Function(String id)? onTap;

  const BillForecastStrip({
    super.key,
    required this.upcoming,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  State<BillForecastStrip> createState() => _BillForecastStripState();
}

class _BillForecastStripState extends State<BillForecastStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.microtask(() => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.upcoming.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final next7 = widget.upcoming.where((s) {
      final days = s.nextBillingDate.difference(DateTime.now()).inDays;
      return days <= 7 && days >= 0;
    }).toList();

    if (next7.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PingTheme.spaceLg, PingTheme.spaceSm, 0, PingTheme.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: PingTheme.spaceLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, size: 16, color: PingTheme.warning),
                      const SizedBox(width: 6),
                      Text('Next 7 days',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: PingTheme.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                    ),
                    child: Text(
                      '${next7.length} ${next7.length == 1 ? 'bill' : 'bills'}',
                      style: const TextStyle(
                        color: PingTheme.danger,
                        fontSize: PingTheme.textCaption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PingTheme.spaceSm),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: next7.length,
                separatorBuilder: (_, __) => const SizedBox(width: PingTheme.spaceSm),
                itemBuilder: (context, i) {
                  final s = next7[i];
                  final days = s.nextBillingDate.difference(DateTime.now()).inDays;
                  final isUrgent = days <= 2;
                  final isSoon = days <= 5;
                  final color = isUrgent
                      ? PingTheme.danger
                      : isSoon
                          ? PingTheme.warning
                          : PingTheme.primary;
                  final themeColor = s.themeColor ??
                      SubscriptionTheme.categoryColors[s.category] ??
                      PingTheme.primary;

                  // Staggered entrance
                  final delay = i * 0.08;
                  final start = delay.clamp(0.0, 0.6);
                  final visible = _ctrl.value >= start;
                  final localT = ((_ctrl.value - start) / 0.3).clamp(0.0, 1.0);
                  final curve = Curves.easeOutCubic.transform(localT);

                  return RepaintBoundary(
                    child: Opacity(
                      opacity: visible ? curve : 0,
                      child: Transform.translate(
                        offset: Offset((1 - curve) * 30, 0),
                        child: PressScale(
                          onTap: () => widget.onTap?.call(s.id),
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(PingTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                              border: Border.all(
                                color: color.withValues(alpha: isUrgent ? 0.4 : 0.12),
                                width: isUrgent ? 1.5 : 1,
                              ),
                              boxShadow: isUrgent
                                  ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    BrandIcon(name: s.name, fallbackColor: themeColor, size: 28),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(PingTheme.radiusXs),
                                      ),
                                      child: Text(
                                        days == 0 ? 'TODAY' : '${days}d',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(s.name,
                                    style: const TextStyle(
                                      fontSize: PingTheme.textSmall,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currencySymbol}${s.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: PingTheme.textCaption,
                                    color: PingTheme.subtleText(context),
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
