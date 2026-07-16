import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../app/theme.dart';
import 'subscription_list_screen.dart';
import 'add_subscription_screen.dart';

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
      context.read<SubscriptionProvider>().scheduleAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          floatingActionButton: provider.subscriptions.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                )
              : null,
          body: SafeArea(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.subscriptions.isEmpty
                    ? _buildEmptyState(context, provider)
                    : CustomScrollView(
                        slivers: [
                          _buildHeader(context, provider),
                          _buildTotalCard(context, provider),
                          _buildQuickStats(context, provider),
                          _buildUpcomingSection(context, provider),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, SubscriptionProvider p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.subscriptions_outlined, size: 80, color: PingTheme.primary),
            const SizedBox(height: 24),
            const Text('No subscriptions yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Add your first subscription or connect your bank to auto-detect them.',
              style: TextStyle(color: Colors.grey[500], fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Manually'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await p.startBankConnection('user_${DateTime.now().millisecondsSinceEpoch}');
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Connect Bank'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SubscriptionProvider p) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 8),
        title: Text('Ping', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
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
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly spend', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(p.bankConnected ? '${p.activeCount} active' : 'Manual mode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('€${p.totalMonthly.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('€${p.totalYearly.toStringAsFixed(0)} / year', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPillBtn('Manage', Icons.tune, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen()));
                  }),
                  const SizedBox(width: 8),
                  if (!p.bankConnected)
                    _buildPillBtn('Connect Bank', Icons.account_balance, () async {
                      await p.startBankConnection('user_${DateTime.now().millisecondsSinceEpoch}');
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillBtn(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: _buildStatCard('Active', '${p.activeCount}', PingTheme.success, Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Paused', '${p.pausedCount}', PingTheme.warning, Icons.pause_circle_outline)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Due soon', '${p.upcomingBills.where((s) => s.nextBillingDate.difference(DateTime.now()).inDays <= 3).length}', PingTheme.danger, Icons.schedule)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context, SubscriptionProvider p) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming bills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen())),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...p.upcomingBills.take(5).map((s) => _buildSubscriptionTile(context, s)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(BuildContext context, Subscription s) {
    final daysLeft = s.nextBillingDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: PingTheme.primary.withValues(alpha: 0.1)),
            child: Center(child: Text(s.name[0], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: PingTheme.primary))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('${s.currency}${s.amount.toStringAsFixed(2)} / ${s.billingCycle}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          if (s.source == 'manual')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: PingTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('manual', style: TextStyle(fontSize: 10, color: PingTheme.primary)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent ? PingTheme.danger.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isUrgent ? '${daysLeft}d left!' : '${daysLeft}d',
              style: TextStyle(color: isUrgent ? PingTheme.danger : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
