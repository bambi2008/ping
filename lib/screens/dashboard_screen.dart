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
import 'quick_add_screen.dart';
import 'email_scan_screen.dart';
import 'calendar_screen.dart';
import '../services/subscription_templates.dart';
import '../widgets/burn_rate_hero.dart';
import '../widgets/shareable_summary.dart';
import '../widgets/cancel_celebration.dart';
import '../widgets/fire_particles.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_transitions.dart';

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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(PingTheme.spaceLg, 0, PingTheme.spaceLg, PingTheme.spaceSm),
          child: RepaintBoundary(
            child: StaggeredEntrance(
              children: _buildInsights(context, p),
            ),
          ),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(
      padding: const EdgeInsets.all(PingTheme.space4Xl),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Animated logo
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [PingTheme.primary.withValues(alpha: 0.15), Colors.transparent],
                  ),
                ),
              ),
              // Logo
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [PingTheme.primary, PingTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PingTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('P', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PingTheme.space3Xl),
        Text('Let\'s find your money leaks',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: PingTheme.spaceSm),
        Text('Add subscriptions you pay for and Ping will track renewals, alert you before charges, and help you cancel.',
            style: TextStyle(color: PingTheme.subtleText(context), fontSize: PingTheme.textBody, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: PingTheme.space3Xl),
        // Two buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(context, SlideFadeRoute(page: const QuickAddScreen()));
              },
              icon: const Icon(Icons.bolt),
              label: const Text('Quick Add'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PingTheme.radiusMd)),
              ),
            ),
            const SizedBox(width: PingTheme.spaceMd),
            OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmailScanScreen()));
              },
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('Scan Email'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PingTheme.radiusMd)),
              ),
            ),
          ],
        ),
      ]),
    ));
  }


  // ── Smart Insight Cards ──
  List<Widget> _buildInsights(BuildContext context, SubscriptionProvider p) {
    if (p.subscriptions.isEmpty) return [];

    final insights = <Widget>[];
    final sym = CurrencyProvider.getSymbol(p.displayCurrency);

    // 1. Next bill countdown
    final upcoming = p.upcomingBills;
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      final daysLeft = DateTime(next.date.year, next.date.month, next.date.day)
          .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
      final isUrgent = daysLeft <= 3;
      final color = isUrgent ? PingTheme.danger : daysLeft <= 7 ? PingTheme.warning : PingTheme.primary;

      insights.add(_insightCard(
        context,
        icon: isUrgent ? Icons.warning_amber_rounded : Icons.schedule,
        color: color,
        title: isUrgent ? '⚠️ ${next.name} renews in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}' : '${next.name} renews in $daysLeft days',
        subtitle: '$sym${next.amount.toStringAsFixed(2)} on ${next.date.day}/${next.date.month}',
        trailing: '${next.date.day}/${next.date.month}',
      ));
    }

    // 2. Category breakdown — top spending category
    final categoryTotals = <String, double>{};
    for (final s in p.subscriptions.where((s) => s.isActive)) {
      final monthly = s.billingCycle == 'yearly' ? s.amount / 12 : s.amount;
      categoryTotals[s.category] = (categoryTotals[s.category] ?? 0) + monthly;
    }
    if (categoryTotals.isNotEmpty) {
      final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topCat = sorted.first;
      final pct = (topCat.value / p.totalMonthly * 100).round();

      insights.add(_insightCard(
        context,
        icon: Icons.pie_chart_outline,
        color: PingTheme.secondary,
        title: '$pct% of your spend is on ${topCat.key}',
        subtitle: '$sym${topCat.value.toStringAsFixed(2)}/mo · ${sorted.length} categor${sorted.length == 1 ? 'y' : 'ies'} total',
      ));
    }

    // 3. Potential savings — yearly vs monthly
    double potentialSavings = 0;
    int switchableCount = 0;
    for (final s in p.subscriptions.where((s) => s.isActive && s.billingCycle == 'monthly')) {
      // Assume ~2 months free on yearly = ~17% saving
      potentialSavings += s.amount * 2;
      switchableCount++;
    }
    if (switchableCount > 0) {
      insights.add(_insightCard(
        context,
        icon: Icons.savings_outlined,
        color: PingTheme.success,
        title: 'Save $sym${potentialSavings.toStringAsFixed(0)}/year',
        subtitle: 'Switch $switchableCount monthly plan${switchableCount == 1 ? '' : 's'} to yearly (est. 2 months free)',
        onTap: () {
          // Could show a detailed savings breakdown in the future
        },
      ));
    }

    // 4. Most expensive subscription
    final mostExpensive = p.subscriptions.where((s) => s.isActive).toList()
      ..sort((a, b) {
        final aM = a.billingCycle == 'yearly' ? a.amount / 12 : a.amount;
        final bM = b.billingCycle == 'yearly' ? b.amount / 12 : b.amount;
        return bM.compareTo(aM);
      });
    if (mostExpensive.isNotEmpty && p.subscriptions.where((s) => s.isActive).length > 1) {
      final s = mostExpensive.first;
      final monthly = s.billingCycle == 'yearly' ? s.amount / 12 : s.amount;
      final pctOfTotal = (monthly / p.totalMonthly * 100).round();
      if (pctOfTotal >= 20) {
        insights.add(_insightCard(
          context,
          icon: Icons.trending_up_rounded,
          color: PingTheme.warning,
          title: '${s.name} is $pctOfTotal% of your spend',
          subtitle: '$sym${monthly.toStringAsFixed(2)}/mo — consider if you still need it',
        ));
      }
    }

    return insights;
  }

  Widget _insightCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: PingTheme.spaceSm),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(PingTheme.spaceLg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: PingTheme.spaceMd),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        fontSize: PingTheme.textBody,
                        fontWeight: FontWeight.w700,
                      )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: TextStyle(
                        fontSize: PingTheme.textCaption,
                        color: PingTheme.subtleText(context),
                      )),
                  ],
                )),
                if (trailing != null)
                  Text(trailing,
                      style: TextStyle(
                        fontSize: PingTheme.textSmall,
                        fontWeight: FontWeight.w600,
                        color: color,
                      )),
              ],
            ),
          ),
        ),
      ),
    );
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
          onPressed: () => Navigator.push(context, SlideFadeRoute(page: const CalendarScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(context, SlideFadeRoute(page: const SettingsScreen())),
        ),
      ],
    );
  }

  // ── Burn Rate Hero ──
  Widget _buildTotalCard(BuildContext context, SubscriptionProvider p) {
    final sym = CurrencyProvider.getSymbol(p.displayCurrency);
    return SliverToBoxAdapter(
      child: Column(
        children: [
          BurnRateHero(
            monthlyTotal: p.totalMonthly,
            yearlyTotal: p.totalYearly,
            activeCount: p.activeCount,
            currencySymbol: sym,
            momChange: p.momAvailable ? p.momChange : null,
            onViewAll: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen())),
            onCalendar: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
          ),
          const SizedBox(height: PingTheme.spaceSm),
          // Shareable summary card
          ShareableSummary(
            monthlyTotal: p.totalMonthly,
            yearlyTotal: p.totalYearly,
            activeCount: p.activeCount,
            currencySymbol: sym,
            categoryBreakdown: p.categoryBreakdown,
          ),
        ],
      ),
    );
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
          RepaintBoundary(child: Container(
            padding: const EdgeInsets.only(left: 4, right: PingTheme.spaceMd, top: PingTheme.spaceMd),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(PingTheme.radiusLg),
              border: Border.all(color: PingTheme.hairlineBorder(context)),
            ),
            child: RepaintBoundary(child: TrendChart(
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
              onPressed: () => Navigator.push(context, SlideFadeRoute(page: const SubscriptionListScreen())),
              child: const Text('See all')),
          ]),
        ),
      ),
      SliverList.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) => RepaintBoundary(child: _AnimatedSubscriptionTile(
          key: ValueKey(bills[index].id),
          subscription: bills[index], index: index,
        )),
      ),
    ]);
  }
}

// MoM badge now lives in BurnRateHero

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
              Navigator.push(context, SlideFadeRoute(page: SubscriptionDetailScreen(id: s.id)));
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
