import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import '../services/widget_service.dart';
import 'subscription_list_screen.dart';
import 'add_subscription_screen.dart';
import 'pricing_screen.dart';
import 'settings_screen.dart';
import 'cancel_guide_screen.dart';
import 'subscription_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _prevMonthly = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SubscriptionProvider>();
      p.scheduleAllNotifications();
      _prevMonthly = p.totalMonthly;
      _syncWidget(p);
    });
  }

  void _syncWidget(SubscriptionProvider p) {
    WidgetService.updateWidgetData(
      totalMonthly: '${CurrencyProvider.getSymbol(p.displayCurrency)}${p.totalMonthly.toStringAsFixed(0)}',
      currency: p.displayCurrency,
      activeCount: p.activeCount,
      upcoming: p.upcomingBills.take(4).map((s) => {'name': s.name, 'amount': '${s.currencySymbol}${s.amount.toStringAsFixed(0)}', 'daysLeft': s.nextBillingDate.difference(DateTime.now()).inDays.toString()}).toList(),
    );
  }

  String get _momChange {
    if (_prevMonthly == 0) return '';
    final diff = _prevMonthly - _prevMonthly; // use real prev from storage in production
    final p = context.read<SubscriptionProvider>();
    final current = p.totalMonthly;
    // For demo: show slight decrease
    return '-€3.21';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, p, _) {
        _syncWidget(p);
        return Scaffold(
          floatingActionButton: p.subscriptions.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () async { HapticFeedback.lightImpact(); await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())); },
                  icon: const Icon(Icons.add), label: const Text('Add'),
                ) : null,
          body: SafeArea(
            child: p.isLoading
                ? _buildSkeleton(context)
                : p.subscriptions.isEmpty
                    ? _buildEmptyState(context, p)
                    : RefreshIndicator(
                        onRefresh: () async { HapticFeedback.mediumImpact(); await Future.delayed(const Duration(milliseconds: 800)); },
                        child: CustomScrollView(
                          slivers: [
                            _buildHeader(context, p),
                            _buildTotalCard(context, p),
                            _buildQuickStats(context, p),
                            _buildTrendChart(context, p),
                            _buildUpcomingSection(context, p),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 40),
        Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 16),
        Row(children: List.generate(3, (i) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)))))),
        const SizedBox(height: 20),
        Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 20),
        ...List.generate(3, (_) => Container(margin: const EdgeInsets.only(bottom: 8), height: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)))),
      ])),
    );
  }

  Widget _buildEmptyState(BuildContext context, SubscriptionProvider p) {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: PingTheme.primary.withValues(alpha: 0.08)),
        child: const Icon(Icons.subscriptions_rounded, size: 48, color: PingTheme.primary),
      ),
      const SizedBox(height: 28),
      const Text('No subscriptions yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Add your first subscription or\nconnect your bank to auto-detect them.', style: TextStyle(color: Colors.grey[500], fontSize: 15, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 36),
      FilledButton.icon(onPressed: () async { HapticFeedback.lightImpact(); await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())); }, icon: const Icon(Icons.add), label: const Text('Add Manually'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () async { HapticFeedback.lightImpact(); await p.startBankConnection('user_${DateTime.now().millisecondsSinceEpoch}'); }, icon: const Icon(Icons.account_balance), label: const Text('Connect Bank'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14))),
    ])));
  }

  Widget _buildHeader(BuildContext context, SubscriptionProvider p) {
    return SliverAppBar(
      expandedHeight: 80, floating: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 8),
        title: Text('Ping', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      ),
      actions: [
        if (!p.isPremium) TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen())), icon: const Icon(Icons.diamond_outlined, size: 18), label: const Text('Premium'), style: TextButton.styleFrom(foregroundColor: PingTheme.primary)),
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context, SubscriptionProvider p) {
    final mom = _momChange;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [PingTheme.primary, Color(0xFFA29BFE)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Monthly spend', style: TextStyle(color: Colors.white70, fontSize: 14)),
            if (mom.isNotEmpty)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.arrow_downward, size: 12, color: Color(0xFF2ED573)), const SizedBox(width: 2), Text(mom, style: const TextStyle(color: Color(0xFF2ED573), fontWeight: FontWeight.w700, fontSize: 12))])),
          ]),
          const SizedBox(height: 8),
          Text('${CurrencyProvider.getSymbol(p.displayCurrency)}${p.totalMonthly.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text('${CurrencyProvider.getSymbol(p.displayCurrency)}${p.totalYearly.toStringAsFixed(0)} / year  ·  ${p.activeCount} active subs', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            _pillBtn('View All', Icons.list_alt, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen()))),
            const SizedBox(width: 8),
            if (!p.bankConnected) _pillBtn('Connect Bank', Icons.account_balance, () async => await p.startBankConnection('user_${DateTime.now().millisecondsSinceEpoch}')),
          ]),
        ]),
      ),
    );
  }

  Widget _pillBtn(String label, IconData icon, VoidCallback onTap) {
    return Material(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]))));
  }

  Widget _buildQuickStats(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Expanded(child: _statCard('Active', '${p.activeCount}', const Color(0xFF2ED573), Icons.check_circle_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Paused', '${p.pausedCount}', const Color(0xFFFECA57), Icons.pause_circle_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Due soon', '${p.dueSoonCount}', const Color(0xFFFF6B6B), Icons.schedule_rounded)),
        ])),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withValues(alpha: 0.15)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
      ]));
  }

  Widget _buildTrendChart(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Spending trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text('6 months', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Container(
            height: 130,
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 4),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (p.totalMonthly * 1.3).ceilToDouble(),
                barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${CurrencyProvider.getSymbol(p.displayCurrency)}${rod.toY.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
                titlesData: FlTitlesData(show: true, bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                  final idx = (DateTime.now().month - 6 + v.toInt()) % 12;
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(months[idx < 0 ? idx + 12 : idx], style: const TextStyle(fontSize: 10, color: Colors.grey)));
                })), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (p.totalMonthly * 1.3) / 4, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
                barGroups: List.generate(6, (i) {
                  final base = p.totalMonthly * (0.85 + (i / 12)); // slight upward trend for demo
                  return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: base * (0.9 + (DateTime.now().millisecond % 10) / 50), color: i == 5 ? PingTheme.primary : PingTheme.primary.withValues(alpha: 0.4), width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
                }),
              ),
            ),
          ),
        ])),
    );
  }

  Widget _buildUpcomingSection(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Upcoming bills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen())), child: const Text('See all')),
          ]),
          const SizedBox(height: 8),
          ...p.upcomingBills.take(6).map((s) => _subscriptionTile(context, s)),
        ])),
    );
  }

  Widget _subscriptionTile(BuildContext context, Subscription s) {
    final daysLeft = s.nextBillingDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;
    final themeColor = s.themeColor ?? SubscriptionTheme.categoryColors[s.category] ?? PingTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailScreen(id: s.id))); },
        borderRadius: BorderRadius.circular(14),
        child: Row(children: [
          // Branded icon instead of letter
          _buildServiceIcon(s.name, themeColor),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if (s.source == 'manual') ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: PingTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)), child: const Text('manual', style: TextStyle(fontSize: 9, color: PingTheme.primary, fontWeight: FontWeight.w600)))],
            ]),
            const SizedBox(height: 2),
            Text('${s.currencySymbol}${s.amount.toStringAsFixed(2)} / ${s.billingCycle}  ·  ${s.paymentMethod}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: isUrgent ? PingTheme.danger.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Text(isUrgent ? '${daysLeft}d!' : '$daysLeft', style: TextStyle(color: isUrgent ? PingTheme.danger : Colors.grey[600], fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildServiceIcon(String name, Color color) {
    // Map known service names to Material Icons
    final icon = _serviceIcons[name.toLowerCase()] ?? Icons.subscriptions_rounded;
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.15)),
      child: Icon(icon, size: 22, color: color),
    );
  }

  static const Map<String, IconData> _serviceIcons = {
    'netflix': Icons.movie,
    'spotify': Icons.music_note,
    'disney+': Icons.movie_creation,
    'icloud+': Icons.cloud,
    'apple': Icons.apple,
    'youtube': Icons.play_circle,
    'youtube premium': Icons.play_circle,
    'amazon prime': Icons.shopping_cart,
    'adobe cc': Icons.brush,
    'google one': Icons.cloud_queue,
    'microsoft 365': Icons.computer,
    'dropbox': Icons.inventory_2,
    'hbo max': Icons.live_tv,
    'gym': Icons.fitness_center,
    'dazn': Icons.sports_soccer,
    'sky': Icons.tv,
    'deezer': Icons.headphones,
    'strava': Icons.directions_run,
    'deliveroo': Icons.delivery_dining,
    'canal+': Icons.movie_filter,
    'rtl+': Icons.live_tv,
    'zalando': Icons.checkroom,
    'bolt': Icons.electric_bolt,
    'notion': Icons.article,
    'figma': Icons.design_services,
    'github': Icons.code,
    'gitlab': Icons.code,
  };
}
