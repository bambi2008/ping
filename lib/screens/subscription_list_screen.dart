import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import 'subscription_detail_screen.dart';
import 'add_subscription_screen.dart';

class SubscriptionListScreen extends StatelessWidget {
  const SubscriptionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Subscriptions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search subscriptions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async => await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, p, _) {
          final filtered = _query.isEmpty
              ? p.subscriptions
              : p.subscriptions.where((s) => s.name.toLowerCase().contains(_query) || s.category.toLowerCase().contains(_query)).toList();
          final active = filtered.where((s) => s.isActive).toList();
          final inactive = filtered.where((s) => !s.isActive).toList();
          if (filtered.isEmpty && _query.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No results for "\$_query"',
                      style: TextStyle(color: Colors.grey[500], fontSize: 15)),
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
                  const SizedBox(height: 16),
                  const Text('No subscriptions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                      onPressed: () async => await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddSubscriptionScreen())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First')),
                ]));
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (active.isNotEmpty) ...[
              Text('Active (${active.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...active.map((s) => _tile(context, s)),
            ],
            if (inactive.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Inactive (${inactive.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...inactive.map((s) => _tile(context, s)),
            ],
          ]);
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Subscription s) {
    final themeColor = s.themeColor ??
        SubscriptionTheme.categoryColors[s.category] ??
        PingTheme.primary;
    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: PingTheme.danger.withValues(alpha: 0.1)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child:
              const Icon(Icons.pause_circle_outline, color: PingTheme.danger)),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: themeColor.withValues(alpha: 0.15)),
              child: Center(
                  child: Text(s.name[0],
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: themeColor)))),
          title: Text(s.name,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: s.isActive ? null : TextDecoration.lineThrough)),
          subtitle: Text(
              '${s.currencySymbol}${s.amount.toStringAsFixed(2)} · ${s.billingCycle} · ${s.paymentMethod}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (s.source == 'manual')
              Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: PingTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('manual',
                      style:
                          TextStyle(fontSize: 10, color: PingTheme.primary))),
            Icon(
              s.isActive ? Icons.check_circle : Icons.pause_circle,
              color: s.isActive ? PingTheme.success : Colors.grey,
              size: 22,
            ),
          ]),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SubscriptionDetailScreen(id: s.id))),
        ),
      ),
    );
  }
}
