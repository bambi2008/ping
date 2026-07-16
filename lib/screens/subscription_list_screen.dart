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
      appBar: AppBar(title: const Text('All Subscriptions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async => await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())),
        icon: const Icon(Icons.add), label: const Text('Add'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, p, _) {
          final active = p.subscriptions.where((s) => s.isActive).toList();
          final paused = p.subscriptions.where((s) => !s.isActive).toList();
          if (p.subscriptions.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.subscriptions_outlined, size: 64, color: PingTheme.primary),
              const SizedBox(height: 16),
              const Text('No subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () async => await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())), icon: const Icon(Icons.add), label: const Text('Add Your First')),
            ]));
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (active.isNotEmpty) ...[
              Text('Active (${active.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...active.map((s) => _tile(context, s)),
            ],
            if (paused.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Paused (${paused.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...paused.map((s) => _tile(context, s)),
            ],
          ]);
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Subscription s) {
    final themeColor = s.themeColor ?? SubscriptionTheme.categoryColors[s.category] ?? PingTheme.primary;
    return Dismissible(
      key: Key(s.id), direction: DismissDirection.endToStart,
      background: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: PingTheme.danger.withValues(alpha: 0.1)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.pause_circle_outline, color: PingTheme.danger)),
      confirmDismiss: (_) async { context.read<SubscriptionProvider>().toggleSubscription(s.id); return false; },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(width: 42, height: 42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: themeColor.withValues(alpha: 0.15)),
            child: Center(child: Text(s.name[0], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: themeColor)))),
          title: Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, decoration: s.isActive ? null : TextDecoration.lineThrough)),
          subtitle: Text('${s.currencySymbol}${s.amount.toStringAsFixed(2)} · ${s.billingCycle} · ${s.paymentMethod}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (s.source == 'manual') Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: PingTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Text('manual', style: TextStyle(fontSize: 10, color: PingTheme.primary))),
            Icon(s.isActive ? Icons.check_circle : Icons.pause_circle, color: s.isActive ? PingTheme.success : Colors.grey, size: 22),
          ]),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailScreen(id: s.id))),
        ),
      ),
    );
  }
}
