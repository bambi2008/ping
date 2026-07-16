import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import '../app/theme.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final String id;
  const SubscriptionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, p, _) {
        final s = p.subscriptions.firstWhere((sub) => sub.id == id);
        final daysLeft = s.nextBillingDate.difference(DateTime.now()).inDays;
        final themeColor = s.themeColor ?? SubscriptionTheme.categoryColors[s.category] ?? PingTheme.primary;

        return Scaffold(
          appBar: AppBar(title: Text(s.name)),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: Column(children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: themeColor.withValues(alpha: 0.15)),
                child: Center(child: Text(s.name[0], style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: themeColor)))),
              const SizedBox(height: 16),
              Text(s.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(s.category, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              if (!s.isActive) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: PingTheme.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: const Text('⏸ Paused', style: TextStyle(color: PingTheme.warning, fontWeight: FontWeight.w600))),
            ])),
            const SizedBox(height: 28),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Column(children: [
              _row('Amount', '${s.currencySymbol}${s.amount.toStringAsFixed(2)}'),
              const Divider(height: 24),
              _row('Monthly equivalent', '${CurrencyProvider.getSymbol(p.displayCurrency)}${s.convertedMonthlyAmount(p.displayCurrency).toStringAsFixed(2)}'),
              const Divider(height: 24),
              _row('Billing cycle', s.billingCycle),
              const Divider(height: 24),
              _row('Next billing', '$daysLeft days (${_fmt(s.nextBillingDate)})'),
              const Divider(height: 24),
              _row('Category', s.category),
              const Divider(height: 24),
              _row('Payment method', s.paymentMethod),
              const Divider(height: 24),
              _row('Currency', '${s.currency} (${s.currencySymbol})'),
              if (s.source != null) ...[const Divider(height: 24), _row('Source', s.source == 'bank' ? '🏦 Bank (auto)' : '✍️ Manual')],
            ])),
            const SizedBox(height: 24),
            // Edit fields
            _editRow(context, 'Category', s.category, SubscriptionProvider.categories, (v) => p.updateSubscription(id, category: v)),
            const SizedBox(height: 10),
            _editRow(context, 'Payment', s.paymentMethod, SubscriptionProvider.paymentMethods, (v) => p.updateSubscription(id, paymentMethod: v)),
            const SizedBox(height: 10),
            _editRow(context, 'Currency', s.currency, CurrencyProvider.all, (v) => p.updateSubscription(id, currency: v)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () { p.toggleSubscription(id); Navigator.pop(context); },
                icon: Icon(s.isActive ? Icons.pause : Icons.play_arrow),
                label: Text(s.isActive ? 'Pause' : 'Resume'),
                style: ElevatedButton.styleFrom(backgroundColor: s.isActive ? PingTheme.warning : PingTheme.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () { p.removeSubscription(id); Navigator.pop(context); },
                icon: const Icon(Icons.delete_outline), label: const Text('Remove'),
                style: OutlinedButton.styleFrom(foregroundColor: PingTheme.danger, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: const BorderSide(color: PingTheme.danger)),
              )),
            ]),
          ]),
        );
      },
    );
  }

  Widget _row(String label, String value) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)), Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))]);
  
  Widget _editRow(BuildContext context, String label, String current, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const Spacer(),
        DropdownButton<String>(
          value: current, underline: const SizedBox(),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ]),
    );
  }

  String _fmt(DateTime d) { const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${d.day} ${m[d.month-1]} ${d.year}'; }
}
