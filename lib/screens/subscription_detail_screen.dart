import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';
import 'add_subscription_screen.dart';
import 'cancel_guide_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final String id;
  const SubscriptionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, p, _) {
        final s = p.subscriptions.firstWhere((sub) => sub.id == id);
        final daysLeft = DateTime(
          s.nextBillingDate.year,
          s.nextBillingDate.month,
          s.nextBillingDate.day,
        )
            .difference(DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ))
            .inDays;
        final themeColor = s.themeColor ??
            SubscriptionTheme.categoryColors[s.category] ??
            PingTheme.primary;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSubscriptionScreen(subscription: s),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
                child: Column(children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: themeColor.withValues(alpha: 0.15)),
                  child: Center(
                      child: Text(s.name[0],
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: themeColor)))),
              const SizedBox(height: 16),
              Text(s.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(s.category,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(s.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.status.label,
                  style: TextStyle(
                    color: _statusColor(s.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ])),
            const SizedBox(height: 28),
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _row('Amount',
                      '${s.currencySymbol}${s.amount.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _row('Monthly equivalent',
                      '${CurrencyProvider.getSymbol(p.displayCurrency)}${s.convertedMonthlyAmount(p.displayCurrency).toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _row('Billing cycle', s.billingCycle),
                  const Divider(height: 24),
                  _row('Next billing',
                      '$daysLeft days (${_fmt(s.nextBillingDate)})'),
                  const Divider(height: 24),
                  _row('Category', s.category),
                  const Divider(height: 24),
                  _row('Payment method', s.paymentMethod),
                  const Divider(height: 24),
                  _row('Currency', '${s.currency} (${s.currencySymbol})'),
                  const Divider(height: 24),
                  _row('Source', '✍️ Manual'),
                ])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSubscriptionScreen(subscription: s),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Subscription'),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel guide
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final cancelled = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CancelGuideScreen(serviceName: s.name)));
                  if (cancelled == true && context.mounted) {
                    await p.setStatus(id, SubscriptionStatus.cancelled);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Guide'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.grey[300]!)),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () async {
                  await p.setStatus(
                    id,
                    s.isActive
                        ? SubscriptionStatus.paused
                        : SubscriptionStatus.active,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                icon: Icon(s.isActive ? Icons.pause : Icons.play_arrow),
                label: Text(s.isActive ? 'Pause' : 'Resume'),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        s.isActive ? PingTheme.warning : PingTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () async {
                  await p.removeSubscription(id);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: PingTheme.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: PingTheme.danger)),
              )),
            ]),
          ]),
        );
      },
    );
  }

  Widget _row(String label, String value) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))
      ]);

  Color _statusColor(SubscriptionStatus status) => switch (status) {
        SubscriptionStatus.active => PingTheme.success,
        SubscriptionStatus.trial => PingTheme.primary,
        SubscriptionStatus.paused => PingTheme.warning,
        SubscriptionStatus.cancelled => PingTheme.danger,
        SubscriptionStatus.expired => Colors.grey,
      };

  String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
