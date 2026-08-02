import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import '../services/widget_service.dart';
import '../widgets/brand_icon.dart';
import '../widgets/trend_chart.dart';
import 'subscription_list_screen.dart';
import 'add_subscription_screen.dart';
import 'settings_screen.dart';
import 'subscription_detail_screen.dart';
import 'calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SubscriptionProvider>();
      p.scheduleAllNotifications();
      _syncWidget(p);
    });
  }

  void _syncWidget(SubscriptionProvider p) {
    WidgetService.updateWidgetData(
      totalMonthly:
          '${CurrencyProvider.getSymbol(p.displayCurrency)}${p.totalMonthly.toStringAsFixed(0)}',
      currency: p.displayCurrency,
      activeCount: p.activeCount,
      upcoming: p.upcomingBills
          .take(4)
          .map((s) => {
                'name': s.name,
                'amount': '${s.currencySymbol}${s.amount.toStringAsFixed(0)}',
                'daysLeft': s.nextBillingDate
                    .difference(DateTime.now())
                    .inDays
                    .toString()
              })
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, p, _) {
        _syncWidget(p);
        return Scaffold(
          body: SafeArea(
            child: p.isLoading
                ? _buildSkeleton(context)
                : p.errorMessage != null
                    ? _buildErrorState(context, p)
                    : p.subscriptions.isEmpty
                    ? _buildEmptyState(context, p)
                    : RefreshIndicator(
                        onRefresh: () async {
                          HapticFeedback.mediumImpact();
                          await p.refresh();
                        },
                        child: CustomScrollView(
                          slivers: [
                            _buildHeader(context, p),
                            _buildTotalCard(context, p),
                            _buildQuickStats(context, p),
                            _buildTrendChart(context, p),
                            _buildCategoryBreakdown(context, p),
                            _buildUpcomingSection(context, p),
                            const SliverToBoxAdapter(child: SizedBox(height: 32)),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  // ── Skeleton ──
  Widget _buildSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).cardColor,
      highlightColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
      child: Padding(
          padding: const EdgeInsets.all(PingTheme.spaceLg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: PingTheme.space3Xl),
            Container(
                height: 180,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusLg))),
            const SizedBox(height: PingTheme.spaceLg),
            Row(children: List.generate(3, (i) => Expanded(
                child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 70,
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(PingTheme.radiusMd)))))),
            const SizedBox(height: PingTheme.spaceXl),
            Container(
                width: 100, height: 14,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusSm))),
            const SizedBox(height: PingTheme.spaceMd),
            Container(
                height: 180,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusLg))),
            const SizedBox(height: PingTheme.spaceXl),
            ...List.generate(3, (_) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 56,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(PingTheme.radiusMd)))),
          ])),
    );
  }

  // ── Error State ──
  Widget _buildErrorState(BuildContext context, SubscriptionProvider p) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(PingTheme.space4Xl),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: PingTheme.danger.withValues(alpha: 0.08)),
          child: const Icon(Icons.cloud_off_rounded, size: 40, color: PingTheme.danger),
        ),
        const SizedBox(height: PingTheme.space2Xl),
        Text('Something went wrong', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: PingTheme.spaceSm),
        Text(p.errorMessage ?? 'Unknown error',
            style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textBody, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () { p.clearAll(); p.init(); },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
        ),
      ]),
    ));
  }

  // ── Empty State ──
  Widget _buildEmptyState(BuildContext context, SubscriptionProvider p) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(PingTheme.space4Xl),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: PingTheme.primary.withValues(alpha: 0.08)),
          child: const Icon(Icons.subscriptions_rounded, size: 48, color: PingTheme.primary),
        ),
        const SizedBox(height: 28),
        Text('No subscriptions yet', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: PingTheme.spaceSm),
        Text('Add your first subscription to see upcoming renewals and monthly spending.',
            style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textBody, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 36),
        FilledButton.icon(
          onPressed: () async {
            HapticFeedback.lightImpact();
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Manually'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
        ),
      ]),
    ));
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context, SubscriptionProvider p) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: PingTheme.spaceXl, bottom: PingTheme.spaceSm),
        title: Text('Ping', style: Theme.of(context).textTheme.headlineMedium),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Calendar view',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  // ── Total Card ──
  Widget _buildTotalCard(BuildContext context, SubscriptionProvider p) {
    final sym = CurrencyProvider.getSymbol(p.displayCurrency);
    return SliverToBoxAdapter(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: p.totalMonthly),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Container(
          margin: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceSm),
          padding: const EdgeInsets.all(PingTheme.space2Xl),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [PingTheme.primary, PingTheme.primaryLight],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(PingTheme.radiusLg),
              boxShadow: [
                BoxShadow(color: PingTheme.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
              ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Monthly spend', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: PingTheme.textSmall, fontWeight: FontWeight.w500)),
              if (p.momAvailable)
                _MoMBadge(change: p.momChange, currencySymbol: sym)
              else
                Icon(Icons.lock_outline, size: 16, color: Colors.white.withValues(alpha: 0.5)),
            ]),
            const SizedBox(height: PingTheme.spaceSm),
            Text('$sym${value.toStringAsFixed(2)}', style: const TextStyle(
                color: Colors.white, fontSize: PingTheme.textHero, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.1)),
            const SizedBox(height: PingTheme.spaceXs),
            Text('$sym${p.totalYearly.toStringAsFixed(0)} / year  ·  ${p.activeCount} active subs',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: PingTheme.textSmall)),
            const SizedBox(height: PingTheme.spaceLg),
            Row(children: [
              _pillBtn('View All', Icons.list_alt, () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen()))),
              const SizedBox(width: PingTheme.spaceSm),
              _pillBtn('Calendar', Icons.calendar_today, () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _pillBtn(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: PingTheme.textSmall))
          ]))));
  }

  // ── Quick Stats ──
  Widget _buildQuickStats(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceSm),
        child: Row(children: [
          Expanded(child: _statCard('Active', '${p.activeCount}', PingTheme.success, Icons.check_circle_rounded)),
          const SizedBox(width: PingTheme.spaceSm),
          Expanded(child: _statCard('Paused', '${p.pausedCount}', PingTheme.warning, Icons.pause_circle_rounded)),
          const SizedBox(width: PingTheme.spaceSm),
          Expanded(child: _statCard('Due soon', '${p.dueSoonCount}', PingTheme.danger, Icons.schedule_rounded)),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PingTheme.radiusSm),
            color: color.withValues(alpha: 0.15)),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: PingTheme.textCaption, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Trend Chart (fl_chart) ──
  Widget _buildTrendChart(BuildContext context, SubscriptionProvider p) {
    final sym = CurrencyProvider.getSymbol(p.displayCurrency);
    final history = p.monthlyHistory;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceSm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Spending trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (history.length > 1)
              _MoMBadge(change: p.momChange, currencySymbol: sym),
          ]),
          const SizedBox(height: PingTheme.spaceMd),
          Container(
            padding: const EdgeInsets.only(left: 4, right: PingTheme.spaceMd, top: PingTheme.spaceMd),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(PingTheme.radiusLg),
              border: Border.all(color: PingTheme.hairlineBorder(context)),
            ),
            child: TrendChart(
              data: history,
              currencySymbol: sym,
              currentMonthTotal: p.totalMonthly,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Category Breakdown ──
  Widget _buildCategoryBreakdown(BuildContext context, SubscriptionProvider p) {
    final entries = p.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximum = entries.isEmpty ? 1.0 : entries.first.value;
    final sym = CurrencyProvider.getSymbol(p.displayCurrency);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceLg, vertical: PingTheme.spaceSm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Monthly breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: PingTheme.spaceMd),
          Container(
            padding: const EdgeInsets.all(PingTheme.spaceLg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(PingTheme.radiusLg),
              border: Border.all(color: PingTheme.hairlineBorder(context))),
            child: entries.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No data yet',
                        style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textSmall))))
                : Column(children: entries.map((entry) {
                    final color = SubscriptionTheme.categoryColors[entry.key] ?? PingTheme.primary;
                    final pct = (entry.value / maximum).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: PingTheme.spaceMd),
                      child: Column(children: [
                        Row(children: [
                          Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: PingTheme.spaceSm),
                          Expanded(child: Text(entry.key, style: const TextStyle(fontSize: PingTheme.textSmall, fontWeight: FontWeight.w500))),
                          Text('$sym${entry.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: PingTheme.textSmall)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                          child: LinearProgressIndicator(
                            value: pct, minHeight: 7,
                            borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                            color: color, backgroundColor: color.withValues(alpha: 0.10),
                          ),
                        ),
                      ]),
                    );
                  }).toList()),
          ),
        ]),
      ),
    );
  }

  // ── Upcoming Section ──
  Widget _buildUpcomingSection(BuildContext context, SubscriptionProvider p) {
    final bills = p.upcomingBills.take(6).toList();
    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(PingTheme.spaceLg, PingTheme.spaceLg, PingTheme.spaceLg, PingTheme.spaceSm),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Upcoming bills', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen())),
              child: const Text('See all')),
          ]),
        ),
      ),
      SliverList.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) => _AnimatedSubscriptionTile(
          key: ValueKey(bills[index].id),
          subscription: bills[index], index: index,
        ),
      ),
    ]);
  }
}

// ── MoM Badge ──
class _MoMBadge extends StatelessWidget {
  final double change;
  final String currencySymbol;
  const _MoMBadge({required this.change, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final isDecrease = change < 0;
    final absStr = change.abs().toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDecrease ? Colors.green.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(PingTheme.radiusSm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isDecrease ? Icons.arrow_downward : Icons.arrow_upward, size: 12,
            color: isDecrease ? PingTheme.success : Colors.redAccent),
        const SizedBox(width: 2),
        Text('${isDecrease ? '-' : '+'}$currencySymbol$absStr',
          style: TextStyle(color: isDecrease ? PingTheme.success : Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

// ── Animated Subscription Tile ──
class _AnimatedSubscriptionTile extends StatefulWidget {
  final Subscription subscription;
  final int index;
  const _AnimatedSubscriptionTile({super.key, required this.subscription, required this.index});
  @override
  State<_AnimatedSubscriptionTile> createState() => _AnimatedSubscriptionTileState();
}

class _AnimatedSubscriptionTileState extends State<_AnimatedSubscriptionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: (widget.index * 60).clamp(0, 300)),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscription;
    final daysLeft = s.nextBillingDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;
    final themeColor = s.themeColor ?? SubscriptionTheme.categoryColors[s.category] ?? PingTheme.primary;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(PingTheme.spaceLg, 0, PingTheme.spaceLg, PingTheme.spaceSm),
          padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceSm + 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            border: Border.all(color: PingTheme.hairlineBorder(context))),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailScreen(id: s.id)));
            },
            borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            child: Row(children: [
              BrandIcon(name: s.name, fallbackColor: themeColor, size: 42),
              const SizedBox(width: PingTheme.spaceMd),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: PingTheme.textBody)),
                  if (s.source == 'manual') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: PingTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(PingTheme.radiusXs)),
                      child: const Text('manual', style: TextStyle(fontSize: 9, color: PingTheme.primary, fontWeight: FontWeight.w600)))
                  ],
                ]),
                const SizedBox(height: 2),
                Text('${s.currencySymbol}${s.amount.toStringAsFixed(2)} / ${s.billingCycle}  ·  ${s.paymentMethod}',
                    style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textCaption)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceSm + 2, vertical: 5),
                decoration: BoxDecoration(
                  color: isUrgent ? PingTheme.danger.withValues(alpha: 0.12) : PingTheme.hairlineBorder(context),
                  borderRadius: BorderRadius.circular(PingTheme.radiusSm)),
                child: Text(isUrgent ? '${daysLeft}d!' : '$daysLeft',
                    style: TextStyle(
                      color: isUrgent ? PingTheme.danger : PingTheme.subtleText(context),
                      fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: PingTheme.spaceXs),
              Icon(Icons.chevron_right, size: 18, color: PingTheme.subtleText(context)),
            ]),
          ),
        ),
      ),
    );
  }
}
