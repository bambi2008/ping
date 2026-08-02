import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import '../services/widget_service.dart';
import 'subscription_list_screen.dart';
import 'add_subscription_screen.dart';
import 'settings_screen.dart';
import 'subscription_detail_screen.dart';

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
          floatingActionButton: p.subscriptions.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddSubscriptionScreen()));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                )
              : null,
          body: SafeArea(
            child: p.isLoading
                ? _buildSkeleton(context)
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
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            Container(
                height: 180,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 16),
            Row(
                children: List.generate(
                    3,
                    (i) => Expanded(
                        child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 70,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14)))))),
            const SizedBox(height: 20),
            Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 20),
            ...List.generate(
                3,
                (_) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 56,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)))),
          ])),
    );
  }

  Widget _buildEmptyState(BuildContext context, SubscriptionProvider p) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(40),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PingTheme.primary.withValues(alpha: 0.08)),
                child: const Icon(Icons.subscriptions_rounded,
                    size: 48, color: PingTheme.primary),
              ),
              const SizedBox(height: 28),
              const Text('No subscriptions yet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  'Add your first subscription to see upcoming renewals and monthly spending.',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 15, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),
              FilledButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddSubscriptionScreen()));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Manually'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14))),
            ])));
  }

  Widget _buildHeader(BuildContext context, SubscriptionProvider p) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 8),
        title: Text('Ping',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [PingTheme.primary, Color(0xFFA29BFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Monthly spend',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            if (p.momAvailable)
              Builder(builder: (_) {
                final change = p.momChange;
                final sym = CurrencyProvider.getSymbol(p.displayCurrency);
                final isDecrease = change < 0;
                final absStr = change.abs().toStringAsFixed(2);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDecrease
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isDecrease ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 12,
                      color: isDecrease ? const Color(0xFF2ED573) : Colors.redAccent),
                    const SizedBox(width: 2),
                    Text(
                      '${isDecrease ? '-' : '+'}$sym$absStr',
                      style: TextStyle(
                        color: isDecrease ? const Color(0xFF2ED573) : Colors.redAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                  ]),
                );
              })
            else
              const Icon(Icons.lock_outline, size: 16, color: Colors.white70),
          ]),
          const SizedBox(height: 8),
          Text(
              '${CurrencyProvider.getSymbol(p.displayCurrency)}${p.totalMonthly.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(
              '${CurrencyProvider.getSymbol(p.displayCurrency)}${p.totalYearly.toStringAsFixed(0)} / year  ·  ${p.activeCount} active subs',
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            _pillBtn(
                'View All',
                Icons.list_alt,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionListScreen()))),
          ]),
        ]),
      ),
    );
  }

  Widget _pillBtn(String label, IconData icon, VoidCallback onTap) {
    return Material(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13))
                ]))));
  }

  Widget _buildQuickStats(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(
                child: _statCard('Active', '${p.activeCount}',
                    const Color(0xFF2ED573), Icons.check_circle_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: _statCard('Paused', '${p.pausedCount}',
                    const Color(0xFFFECA57), Icons.pause_circle_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: _statCard('Due soon', '${p.dueSoonCount}',
                    const Color(0xFFFF6B6B), Icons.schedule_rounded)),
          ])),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withValues(alpha: 0.15)),
              child: Icon(icon, size: 18, color: color)),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500)),
        ]));
  }

  Widget _buildTrendChart(BuildContext context, SubscriptionProvider p) {
    final entries = p.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximum = entries.isEmpty ? 1.0 : entries.first.value;
    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Monthly breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: entries.map((entry) {
                  final color = SubscriptionTheme.categoryColors[entry.key] ??
                      PingTheme.primary;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: Text(entry.key)),
                        Text(
                          '${CurrencyProvider.getSymbol(p.displayCurrency)}${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: entry.value / maximum,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ])),
    );
  }

  Widget _buildUpcomingSection(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Upcoming bills',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscriptionListScreen())),
                  child: const Text('See all')),
            ]),
            const SizedBox(height: 8),
            ...p.upcomingBills
                .take(6)
                .map((s) => _subscriptionTile(context, s)),
          ])),
    );
  }

  Widget _subscriptionTile(BuildContext context, Subscription s) {
    final daysLeft = s.nextBillingDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;
    final themeColor = s.themeColor ??
        SubscriptionTheme.categoryColors[s.category] ??
        PingTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SubscriptionDetailScreen(id: s.id)));
        },
        borderRadius: BorderRadius.circular(14),
        child: Row(children: [
          // Branded icon instead of letter
          _buildServiceIcon(s.name, themeColor),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  if (s.source == 'manual') ...[
                    const SizedBox(width: 6),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: PingTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('manual',
                            style: TextStyle(
                                fontSize: 9,
                                color: PingTheme.primary,
                                fontWeight: FontWeight.w600)))
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                    '${s.currencySymbol}${s.amount.toStringAsFixed(2)} / ${s.billingCycle}  ·  ${s.paymentMethod}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: isUrgent
                    ? PingTheme.danger.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Text(isUrgent ? '${daysLeft}d!' : '$daysLeft',
                style: TextStyle(
                    color: isUrgent ? PingTheme.danger : Colors.grey[600],
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildServiceIcon(String name, Color color) {
    // Map known service names to Material Icons
    final icon =
        _serviceIcons[name.toLowerCase()] ?? Icons.subscriptions_rounded;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.15)),
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
