import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../models/subscription_provider.dart';
import '../models/subscription.dart';
import 'pricing_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() => _notificationsEnabled = p.getBool('notifications') ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SubscriptionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Display ──
          _section('Display'),
          _tile(Icons.currency_exchange_outlined, 'Display currency', p.displayCurrency,
            onTap: () => _showCurrencyPicker(context, p)),
          _tile(Icons.dark_mode_outlined, 'Dark mode', 'System',
            onTap: () => _showThemePicker(context)),
          const SizedBox(height: 8),

          // ── Notifications ──
          _section('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: PingTheme.primary),
            title: const Text('Bill reminders'),
            subtitle: const Text('3 days, 1 day, and day-of alerts'),
            value: _notificationsEnabled,
            onChanged: (v) async {
              setState(() => _notificationsEnabled = v);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications', v);
            },
          ),
          const SizedBox(height: 8),

          // ── Data ──
          _section('Data'),
          _tile(Icons.download_outlined, 'Export as CSV', 'Share your subscription list',
            onTap: () => _exportCsv(context, p)),
          _tile(Icons.cloud_sync_outlined, 'iCloud sync', p.isPremium ? 'Enabled' : 'Premium only',
            onTap: p.isPremium ? null : () => _showPremiumLocked(context)),
          _tile(Icons.delete_outline, 'Clear all data', 'Remove all subscriptions',
            onTap: () => _confirmClear(context, p), isDestructive: true),
          const SizedBox(height: 8),

          // ── Premium ──
          _section('Premium'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: p.isPremium ? PingTheme.warning.withValues(alpha: 0.2) : PingTheme.primary.withValues(alpha: 0.1)),
                child: Icon(p.isPremium ? Icons.diamond : Icons.diamond_outlined, color: p.isPremium ? PingTheme.warning : PingTheme.primary)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.isPremium ? 'Ping Premium' : 'Upgrade to Premium', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(p.isPremium ? 'Forever access unlocked' : '€19.99 one-time · Lifetime access', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ])),
              if (!p.isPremium)
                FilledButton(onPressed: () => _showPremiumLocked(context), style: FilledButton.styleFrom(backgroundColor: PingTheme.primary), child: const Text('Upgrade')),
            ]),
          ),
          const SizedBox(height: 8),

          // ── About ──
          _section('About'),
          _tile(Icons.info_outline, 'Privacy', 'How we handle your data',
            onTap: () => _showPrivacy(context)),
          _tile(Icons.info_outline, 'About Ping', 'Version 1.0.0 · Made in Europe',
            onTap: () => _showAbout(context)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
    child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2)),
  );

  Widget _tile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? PingTheme.danger : PingTheme.primary),
        title: Text(title, style: TextStyle(color: isDestructive ? PingTheme.danger : null)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SubscriptionProvider p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text('Display Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ...CurrencyProvider.all.map((code) => RadioListTile<String>(
            title: Text('${CurrencyProvider.getSymbol(code)}  $code'),
            value: code, groupValue: p.displayCurrency,
            onChanged: (v) { p.setCurrency(v!); Navigator.pop(context); },
          )),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ListTile(title: const Text('🌞 Light'), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('🌙 Dark'), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('📱 System'), leading: const Icon(Icons.check, color: PingTheme.primary), onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  void _exportCsv(BuildContext context, SubscriptionProvider p) {
    final buf = StringBuffer();
    buf.writeln('Name,Amount,Currency,Billing Cycle,Category,Payment Method,Next Billing,Status');
    for (final s in p.subscriptions) {
      buf.writeln('"${s.name}",${s.amount},${s.currency},${s.billingCycle},"${s.category}","${s.paymentMethod}",${_fmt(s.nextBillingDate)},${s.isActive ? "Active" : "Paused"}');
    }
    Share.share(buf.toString(), subject: 'Ping Subscriptions Export');
  }

  void _showPremiumLocked(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
  }

  void _confirmClear(BuildContext context, SubscriptionProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text('This will permanently remove all your subscriptions. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              for (final s in List.from(p.subscriptions)) { p.removeSubscription(s.id); }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared'), behavior: SnackBarBehavior.floating));
            },
            style: FilledButton.styleFrom(backgroundColor: PingTheme.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy'),
        content: const Text(
          'Ping is designed with privacy first.\n\n'
          '• All subscription data is stored locally on your device.\n'
          '• If you connect your bank, we use Open Banking (PSD2) with read-only access. We never store your bank credentials.\n'
          '• We do not collect, sell, or share your personal data.\n'
          '• No analytics SDKs. No tracking. No ads.\n'
          '• You can delete all data at any time with one tap.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: PingTheme.primary.withValues(alpha: 0.15)), child: const Center(child: Text('P', style: TextStyle(fontWeight: FontWeight.w800, color: PingTheme.primary, fontSize: 20)))),
          const SizedBox(width: 12), const Text('Ping'),
        ]),
        content: const Text(
          'Subscription Tracker\n\n'
          'Version 1.0.0\n\n'
          'Built independently in Europe.\n'
          'Open Banking powered by Tink (PSD2).\n\n'
          '© 2026 Ping App',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse('https://github.com/bambi2008/ping')),
            icon: const Icon(Icons.code), label: const Text('Open Source'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  String _fmt(DateTime d) { const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${d.day} ${m[d.month-1]} ${d.year}'; }
}
