import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';

class CancelGuideScreen extends StatelessWidget {
  final String serviceName;
  const CancelGuideScreen({super.key, required this.serviceName});

  static final Map<String, _CancelInfo> _guides = {
    'netflix': _CancelInfo(
      'Netflix', 'Cancel anytime from your account page.',
      ['Go to netflix.com/account', 'Click "Cancel Membership" under Membership & Billing', 'Confirm cancellation'],
      'https://www.netflix.com/cancelplan',
    ),
    'spotify': _CancelInfo(
      'Spotify', 'Downgrade to free or cancel Premium.',
      ['Go to spotify.com/account', 'Click "Change Plan" under Your Plan', 'Scroll down and click "Cancel Premium"'],
      'https://www.spotify.com/account/',
    ),
    'disney+': _CancelInfo(
      'Disney+', 'Cancel your subscription from account settings.',
      ['Go to disneyplus.com/account', 'Click your subscription', 'Click "Cancel Subscription"'],
      'https://www.disneyplus.com/account',
    ),
    'amazon prime': _CancelInfo(
      'Amazon Prime', 'End your Prime membership.',
      ['Go to amazon.com/prime', 'Click "Manage Membership"', 'Click "End Membership"'],
      'https://www.amazon.com/prime',
    ),
    'icloud+': _CancelInfo(
      'iCloud+', 'Downgrade to free 5GB plan.',
      ['Open Settings → [your name] → iCloud', 'Tap "Manage Storage" → "Change Storage Plan"', 'Select "Downgrade Options" → 5GB Free'],
      null,
    ),
    'youtube': _CancelInfo(
      'YouTube Premium', 'Cancel Premium membership.',
      ['Go to youtube.com/paid_memberships', 'Click "Manage Membership"', 'Click "Deactivate" → "Continue to Cancel"'],
      'https://www.youtube.com/paid_memberships',
    ),
    'adobe': _CancelInfo(
      'Adobe CC', 'Note: early cancellation may incur fees.',
      ['Go to account.adobe.com/plans', 'Click "Manage Plan"', 'Click "Cancel Plan" — check for early termination fee'],
      'https://account.adobe.com/plans',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final key = serviceName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final guide = _guides[key] ?? _CancelInfo(
      serviceName, 'Contact the service provider directly.',
      ['Find cancellation page on their website', 'Look for "Account" or "Subscription" settings', 'Follow cancellation steps'],
      null,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Cancel ${guide.name}')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Warning card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PingTheme.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.info_outline, color: PingTheme.warning),
            const SizedBox(width: 12),
            Expanded(child: Text(guide.note, style: const TextStyle(fontSize: 14))),
          ]),
        ),
        const SizedBox(height: 24),

        // Steps
        const Text('Steps to cancel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...guide.steps.asMap().entries.map((e) => _buildStep(e.key + 1, e.value)),
        const SizedBox(height: 24),

        // Open cancellation page
        if (guide.url != null) ...[
          SizedBox(
            width: double.infinity, height: 52,
            child: FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(guide.url!)),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Cancellation Page'),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Alternative: mark as cancelled
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, true); // true = cancelled
          },
          icon: const Icon(Icons.check),
          label: const Text('I\'ve Cancelled — Mark as Paused'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: PingTheme.primary.withValues(alpha: 0.15)),
          child: Center(child: Text('$num', style: const TextStyle(fontWeight: FontWeight.w700, color: PingTheme.primary, fontSize: 13))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
      ]),
    );
  }
}

class _CancelInfo {
  final String name;
  final String note;
  final List<String> steps;
  final String? url;
  _CancelInfo(this.name, this.note, this.steps, this.url);
}
