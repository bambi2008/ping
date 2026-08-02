import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme.dart';
import '../models/subscription.dart';
import '../models/subscription_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const _shareChannel = MethodChannel('ping/share');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(PingTheme.spaceLg),
        children: [
          _section('Display'),
          _tile(
            context,
            Icons.currency_exchange_outlined,
            'Display currency',
            provider.displayCurrency,
            onTap: () => _showCurrencyPicker(context, provider),
          ),
          _tile(
            context,
            Icons.sync_alt,
            'Exchange rates',
            CurrencyProvider.isUsingLiveRates ? 'Live ✓' : 'Offline',
            subtitle2: CurrencyProvider.isUsingLiveRates
                ? 'Updated ${CurrencyProvider.ratesUpdated?.hour}:${CurrencyProvider.ratesUpdated?.minute.toString().padLeft(2, '0')}'
                : 'Tap to refresh',
            onTap: () async {
              final ok = await CurrencyProvider.fetchLiveRates();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Exchange rates updated' : 'Using offline rates'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: PingTheme.spaceSm),
          _section('Notifications'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(PingTheme.radiusMd),
            ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.notifications_outlined,
                color: PingTheme.primary,
              ),
              title: const Text('Bill reminders'),
              subtitle: const Text('3 days, 1 day, and day-of alerts'),
              value: provider.notificationsEnabled,
              onChanged: (enabled) async {
                final granted = await provider.setNotificationsEnabled(enabled);
                if (!context.mounted || granted || !enabled) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifications are disabled in system settings.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          if (provider.notificationsEnabled)
            _tile(
              context,
              Icons.notifications_active_outlined,
              'Test notification',
              'Send a test reminder now',
              onTap: () async {
                await NotificationService.showNow(
                  'Ping reminder',
                  'Your bill is due soon! This is a test notification.',
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          const SizedBox(height: PingTheme.spaceSm),
          _section('Data'),
          _tile(
            context,
            Icons.download_outlined,
            'Export as CSV',
            'Share a copy of your subscription list',
            onTap: () => _exportCsv(provider),
          ),
          _tile(
            context,
            Icons.upload_outlined,
            'Import from CSV',
            'Paste a CSV to bulk-add subscriptions',
            onTap: () => _showImportDialog(context, provider),
          ),
          _tile(
            context,
            Icons.delete_outline,
            'Clear all data',
            'Permanently remove local subscriptions',
            onTap: () => _confirmClear(context, provider),
            isDestructive: true,
          ),
          const SizedBox(height: PingTheme.spaceSm),
          _section('About'),
          _tile(
            context,
            Icons.privacy_tip_outlined,
            'Privacy',
            'How local data is handled',
            onTap: () => _showPrivacy(context),
          ),
          _tile(
            context,
            Icons.info_outline,
            'About Ping',
            'Version 1.0.0 · Open source',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: PingTheme.space3Xl),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: PingTheme.subtleText(context),
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    bool isDestructive = false,
    String? subtitle2,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(PingTheme.radiusMd),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? PingTheme.danger : PingTheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? PingTheme.danger : null),
        ),
        subtitle: subtitle2 != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: PingTheme.subtleText(context))),
                  Text(subtitle2,
                      style: TextStyle(fontSize: 10, color: PingTheme.subtleText(context))),
                ],
              )
            : Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: PingTheme.subtleText(context)),
              ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PingTheme.radiusMd),
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Display Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ...CurrencyProvider.all.map(
            (code) => ListTile(
              title: Text('${CurrencyProvider.getSymbol(code)}  $code'),
              trailing: code == provider.displayCurrency
                  ? const Icon(Icons.check, color: PingTheme.primary)
                  : null,
              onTap: () async {
                await provider.setCurrency(code);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(SubscriptionProvider provider) async {
    final buffer = StringBuffer()
      ..writeln(
        'Name,Amount,Currency,Billing Cycle,Category,Payment Method,'
        'Next Billing,Status',
      );
    for (final subscription in provider.subscriptions) {
      buffer.writeln([
        subscription.name,
        subscription.amount.toStringAsFixed(2),
        subscription.currency,
        subscription.billingCycle,
        subscription.category,
        subscription.paymentMethod,
        subscription.nextBillingDate.toIso8601String(),
        subscription.status.label,
      ].map(_csvCell).join(','));
    }
    await _shareChannel.invokeMethod<void>('shareText', {
      'text': buffer.toString(),
      'subject': 'Ping subscriptions export',
    });
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  void _showImportDialog(BuildContext context, SubscriptionProvider provider) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import from CSV'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: ctrl,
            maxLines: 10,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name,Amount,Currency,Billing Cycle,Category,Payment Method,Next Billing',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              final lines = text.split('\n');
              int imported = 0;
              for (int i = 0; i < lines.length; i++) {
                final line = lines[i].trim();
                if (line.isEmpty) continue;
                // Skip header row
                if (i == 0 && line.toLowerCase().contains('name')) continue;
                final cells = _parseCsvLine(line);
                if (cells.length < 3) continue;
                try {
                  final name = cells[0];
                  final amount = double.parse(cells[1]);
                  final currency = cells.length > 2 ? cells[2] : 'EUR';
                  final billingCycle = cells.length > 3 ? cells[3].toLowerCase() : 'monthly';
                  final category = cells.length > 4 ? cells[4] : 'Other';
                  final paymentMethod = cells.length > 5 ? cells[5] : 'Unknown';
                  DateTime nextBilling;
                  try {
                    nextBilling = cells.length > 6
                        ? DateTime.parse(cells[6])
                        : DateTime.now().add(const Duration(days: 30));
                  } catch (_) {
                    nextBilling = DateTime.now().add(const Duration(days: 30));
                  }
                  final theme = SubscriptionTheme.match(name);
                  await provider.addManual(Subscription(
                    id: 'import_${DateTime.now().millisecondsSinceEpoch}_$i',
                    name: name,
                    logoUrl: name.toLowerCase(),
                    amount: amount,
                    currency: currency,
                    billingCycle: billingCycle,
                    nextBillingDate: nextBilling,
                    category: category,
                    paymentMethod: paymentMethod,
                    source: 'import',
                    themeColor: theme?.color,
                  ));
                  imported++;
                } catch (_) {
                  // Skip invalid rows
                }
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imported $imported subscription${imported == 1 ? "" : "s"}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  void _confirmClear(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This permanently removes every subscription stored by Ping on '
          'this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.clearAll();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local data cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: PingTheme.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Privacy'),
        content: const Text(
          'Ping stores subscription records and preferences locally on this '
          'device.\n\n'
          'Ping does not connect to a bank, create an online account, include '
          'advertising, or send analytics in this version.\n\n'
          'Notification permission is used only for renewal reminders. '
          'Export shares data only after you choose a destination.\n\n'
          'Use “Clear all data” to delete subscription records and scheduled '
          'reminders.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ping'),
        content: const Text(
          'A private, offline-first subscription tracker.\n\nVersion 1.0.0',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/bambi2008/ping'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.code),
            label: const Text('Open Source'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
