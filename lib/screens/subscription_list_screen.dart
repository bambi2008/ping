import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../app/theme.dart';
import 'subscription_detail_screen.dart';

class SubscriptionListScreen extends StatelessWidget {
  const SubscriptionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Subscriptions')),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          final subs = provider.subscriptions;
          final active = subs.where((s) => s.isActive).toList();
          final paused = subs.where((s) => !s.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                Text('Active (${active.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...active.map((s) => _buildTile(context, s)),
              ],
              if (paused.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Paused (${paused.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...paused.map((s) => _buildTile(context, s)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTile(BuildContext context, Subscription s) {
    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: PingTheme.danger.withAlpha(40)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.pause_circle_outline, color: PingTheme.danger),
      ),
      confirmDismiss: (_) async {
        context.read<SubscriptionProvider>().toggleSubscription(s.id);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: s.isActive ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: PingTheme.primary.withAlpha(25)),
            child: Center(child: Text(s.name[0], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: PingTheme.primary))),
          ),
          title: Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, decoration: s.isActive ? null : TextDecoration.lineThrough, color: s.isActive ? null : Colors.grey)),
          subtitle: Text('${s.currency}${s.amount.toStringAsFixed(2)} · ${s.billingCycle} · next: ${_formatDate(s.nextBillingDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Icon(s.isActive ? Icons.check_circle : Icons.pause_circle, color: s.isActive ? PingTheme.success : Colors.grey, size: 22),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailScreen(id: s.id))),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month-1]}';
  }
}
