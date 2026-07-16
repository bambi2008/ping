import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../app/theme.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final String id;
  const SubscriptionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        final sub = provider.subscriptions.firstWhere((s) => s.id == id);
        final daysLeft = sub.nextBillingDate.difference(DateTime.now()).inDays;

        return Scaffold(
          appBar: AppBar(title: Text(sub.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Logo + name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: PingTheme.primary.withAlpha(25)),
                      child: Center(child: Text(sub.name[0], style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: PingTheme.primary))),
                    ),
                    const SizedBox(height: 16),
                    Text(sub.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(sub.category, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Billing info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildInfoRow('Amount', '${sub.currency}${sub.amount.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _buildInfoRow('Billing cycle', sub.billingCycle == 'yearly' ? 'Yearly' : sub.billingCycle == 'weekly' ? 'Weekly' : 'Monthly'),
                    const Divider(height: 24),
                    _buildInfoRow('Monthly equivalent', '${sub.currency}${sub.monthlyAmount.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _buildInfoRow('Next billing', '$daysLeft days (${_formatDate(sub.nextBillingDate)})'),
                    const Divider(height: 24),
                    _buildInfoRow('Status', sub.isActive ? '🟢 Active' : '🟡 Paused'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => provider.toggleSubscription(sub.id),
                      icon: Icon(sub.isActive ? Icons.pause : Icons.play_arrow),
                      label: Text(sub.isActive ? 'Pause' : 'Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sub.isActive ? PingTheme.warning : PingTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PingTheme.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: PingTheme.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month-1]} ${d.year}';
  }
}
