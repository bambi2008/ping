import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import 'subscription_detail_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});
  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Subscriptions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PingTheme.spaceMd, 0, PingTheme.spaceMd, PingTheme.spaceSm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search subscriptions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: PingTheme.spaceMd),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PingTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),

      body: Consumer<SubscriptionProvider>(
        builder: (context, p, _) {
          final filtered = _query.isEmpty
              ? p.subscriptions
              : p.subscriptions
                  .where((s) =>
                      s.name.toLowerCase().contains(_query) ||
                      s.category.toLowerCase().contains(_query))
                  .toList();
          final active = filtered.where((s) => s.isActive).toList();
          final inactive = filtered.where((s) => !s.isActive).toList();

          if (filtered.isEmpty && _query.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 56, color: PingTheme.subtleText(context)),
                  const SizedBox(height: PingTheme.spaceMd),
                  Text('No results for "$_query"',
                      style: TextStyle(
                          color: PingTheme.subtleText(context),
                          fontSize: PingTheme.textBody)),
                ],
              ),
            );
          }
          if (p.subscriptions.isEmpty) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(Icons.subscriptions_outlined,
                      size: 64, color: PingTheme.primary),
                  const SizedBox(height: PingTheme.spaceLg),
                  Text('No subscriptions',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: PingTheme.spaceLg),
                  FilledButton.icon(
                      onPressed: () async => await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddSubscriptionScreen())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First')),
                ]));
          }
          return CustomScrollView(
            slivers: [
              if (active.isNotEmpty) ...[
                _sectionHeader(context, 'Active', active.length),
                SliverList.builder(
                  itemCount: active.length,
                  itemBuilder: (context, i) => _tile(context, active[i]),
                ),
              ],
              if (inactive.isNotEmpty) ...[
                _sectionHeader(context, 'Inactive', inactive.length,
                    topPadding: PingTheme.space2Xl),
                SliverList.builder(
                  itemCount: inactive.length,
                  itemBuilder: (context, i) => _tile(context, inactive[i]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label, int count,
      {double topPadding = PingTheme.spaceLg}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            PingTheme.spaceLg, topPadding, PingTheme.spaceLg, PingTheme.spaceSm),
        child: Text('$label ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PingTheme.subtleText(context),
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _tile(BuildContext context, Subscription s) {
    final themeColor = s.themeColor ??
        SubscriptionTheme.categoryColors[s.category] ??
        PingTheme.primary;
    final serviceIcon = _getIcon(s.name);
    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
          margin: const EdgeInsets.only(bottom: PingTheme.spaceSm),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
              color: PingTheme.danger.withValues(alpha: 0.10)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: PingTheme.spaceXl),
          child: const Icon(Icons.pause_circle_outline, color: PingTheme.danger)),
      confirmDismiss: (_) async {
        await context.read<SubscriptionProvider>().setStatus(
              s.id,
              s.isActive
                  ? SubscriptionStatus.paused
                  : SubscriptionStatus.active,
            );
        return false;
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            PingTheme.spaceLg, 0, PingTheme.spaceLg, PingTheme.spaceSm),
        padding: const EdgeInsets.symmetric(
            horizontal: PingTheme.spaceMd, vertical: PingTheme.spaceSm + 2),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            border: Border.all(color: PingTheme.hairlineBorder(context))),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PingTheme.radiusSm),
                  color: themeColor.withValues(alpha: 0.12)),
              child: Icon(serviceIcon, size: 22, color: themeColor)),
          title: Text(s.name,
              style: TextStyle(
                  fontSize: PingTheme.textBody,
                  fontWeight: FontWeight.w600,
                  decoration:
                      s.isActive ? null : TextDecoration.lineThrough)),
          subtitle: Text(
              '${s.currencySymbol}${s.amount.toStringAsFixed(2)} · ${s.billingCycle} · ${s.paymentMethod}',
              style: TextStyle(
                  fontSize: PingTheme.textCaption,
                  color: PingTheme.subtleText(context))),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (s.source == 'manual')
              Container(
                  margin: const EdgeInsets.only(right: PingTheme.spaceSm),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: PingTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(PingTheme.radiusXs)),
                  child: const Text('manual',
                      style: TextStyle(
                          fontSize: 10, color: PingTheme.primary))),
            Icon(
              s.isActive ? Icons.check_circle : Icons.pause_circle,
              color: s.isActive ? PingTheme.success : PingTheme.subtleText(context),
              size: 22,
            ),
          ]),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SubscriptionDetailScreen(id: s.id))),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    const icons = {
      'netflix': Icons.movie, 'spotify': Icons.music_note,
      'disney+': Icons.movie_creation, 'icloud+': Icons.cloud,
      'apple': Icons.apple, 'youtube': Icons.play_circle,
      'youtube premium': Icons.play_circle, 'amazon prime': Icons.shopping_cart,
      'adobe cc': Icons.brush, 'google one': Icons.cloud_queue,
      'microsoft 365': Icons.computer, 'dropbox': Icons.inventory_2,
      'hbo max': Icons.live_tv, 'gym': Icons.fitness_center,
      'dazn': Icons.sports_soccer, 'sky': Icons.tv,
      'deezer': Icons.headphones, 'strava': Icons.directions_run,
      'deliveroo': Icons.delivery_dining, 'canal+': Icons.movie_filter,
      'rtl+': Icons.live_tv, 'zalando': Icons.checkroom,
      'bolt': Icons.electric_bolt, 'notion': Icons.article,
      'figma': Icons.design_services, 'github': Icons.code, 'gitlab': Icons.code,
    };
    return icons[name.toLowerCase()] ?? Icons.subscriptions_rounded;
  }
}
