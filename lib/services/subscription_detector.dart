import 'dart:math';
import '../models/subscription.dart';

/// Subscription Detection Engine
/// Analyzes bank transactions to identify recurring subscriptions.
class SubscriptionDetector {
  static final Map<String, _MerchantPattern> _knownMerchants = {
    'netflix':    _MerchantPattern('Netflix', 'Entertainment', r'netflix', [7.99, 13.99, 17.99]),
    'spotify':    _MerchantPattern('Spotify', 'Music', r'spotify', [5.99, 10.99, 12.99, 16.99]),
    'disney+':    _MerchantPattern('Disney+', 'Entertainment', r'disney', [5.99, 8.99, 11.99, 89.90]),
    'amazon prime': _MerchantPattern('Amazon Prime', 'Shopping', r'amazon.*prime|prime.*amazon', [8.99, 14.99]),
    'apple':      _MerchantPattern('Apple Services', 'Cloud', r'apple\.com/bill|apple\.com', [0.99, 2.99, 9.99]),
    'icloud':     _MerchantPattern('iCloud+', 'Cloud', r'icloud', [0.99, 2.99, 9.99]),
    'youtube':    _MerchantPattern('YouTube Premium', 'Entertainment', r'youtube', [12.99, 17.99]),
    'adobe':      _MerchantPattern('Adobe CC', 'Software', r'adobe', [11.99, 26.43, 62.99]),
    'google one': _MerchantPattern('Google One', 'Cloud', r'google.*one|google.*storage', [1.99, 2.99, 9.99]),
    'microsoft':  _MerchantPattern('Microsoft 365', 'Software', r'microsoft', [6.99, 9.99]),
    'dropbox':    _MerchantPattern('Dropbox', 'Cloud', r'dropbox', [9.99, 11.99]),
    'hbo':        _MerchantPattern('HBO Max', 'Entertainment', r'hbo', [4.99, 7.99, 9.99]),
    'gym':        _MerchantPattern('Gym', 'Health', r'gym|fitness|mcfit|basic.fit', null), // any amount
    'dazn':       _MerchantPattern('DAZN', 'Entertainment', r'dazn', [9.99, 14.99, 29.99]),
    'sky':        _MerchantPattern('Sky', 'Entertainment', r'sky(?!pe|scanner)', null),
    'deezer':     _MerchantPattern('Deezer', 'Music', r'deezer', [5.99, 9.99, 10.99]),
    'strava':     _MerchantPattern('Strava', 'Health', r'strava', [5.99, 7.99]),
    'deliveroo':  _MerchantPattern('Deliveroo Plus', 'Food', r'deliveroo.*plus', [5.99, 7.99]),
    'canal+':     _MerchantPattern('Canal+', 'Entertainment', r'canal\+', [19.90, 24.99, 29.99]),
    'rtl+':       _MerchantPattern('RTL+', 'Entertainment', r'rtl\+|rtl plus|tvnow', [4.99, 6.99, 9.99]),
    'zalando':    _MerchantPattern('Zalando Plus', 'Shopping', r'zalando.*plus', [9.95, 14.95]),
    'bolt':       _MerchantPattern('Bolt Food', 'Food', r'bolt.*food|bolt.*delivery', [3.99, 5.99]),
  };

  (List<Subscription>, List<Subscription>) detect(List<Map<String, dynamic>> transactions) {
    final confirmed = <Subscription>[];
    final possible = <Subscription>[];

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final tx in transactions) {
      final merchant = _normalizeMerchant(tx['description']?.toString() ?? '');
      groups.putIfAbsent(merchant, () => []).add(tx);
    }

    for (final entry in groups.entries) {
      final merchant = entry.key;
      final txs = entry.value;
      if (txs.length < 2) continue;

      final amounts = txs.map((t) => (t['amount'] as num?)?.toDouble() ?? 0.0).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final maxDeviation = amounts.map((a) => (a - avgAmount).abs() / avgAmount.clamp(0.01, double.infinity)).reduce(max);
      final isRecurring = maxDeviation < 0.05;

      final dates = txs.map((t) => DateTime.tryParse(t['date']?.toString() ?? '') ?? DateTime.now()).toList()..sort();
      final cycle = _detectCycle(dates);
      final match = _matchMerchant(merchant, avgAmount);

      if (isRecurring && cycle != null) {
        final sub = Subscription(
          id: 'det_${merchant.hashCode.abs()}',
          name: match?.name ?? _humanizeName(merchant),
          logoUrl: merchant,
          amount: avgAmount,
          currency: _normalizeCurrencyCode(txs.first['currency']?.toString() ?? 'EUR'),
          billingCycle: cycle,
          nextBillingDate: _predictNextDate(dates.last, cycle),
          category: match?.category ?? _guessCategory(merchant),
          isActive: true,
          paymentMethod: 'Bank',
          source: 'bank',
          themeColor: match != null ? SubscriptionTheme.match(match.name)?.color : null,
        );
        (match != null ? confirmed : possible).add(sub);
      }
    }

    confirmed.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    possible.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    return (confirmed, possible);
  }

  String _normalizeMerchant(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[^a-z0-9\s.]'), '').trim();

  String? _detectCycle(List<DateTime> sortedDates) {
    if (sortedDates.length < 2) return null;
    final gaps = <int>[];
    for (int i = 1; i < sortedDates.length; i++) {
      gaps.add(sortedDates[i].difference(sortedDates[i - 1]).inDays);
    }
    final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
    if (avgGap <= 9) return 'weekly';
    if (avgGap <= 45) return 'monthly';
    if (avgGap <= 400) return 'yearly';
    return null;
  }

  DateTime _predictNextDate(DateTime last, String cycle) {
    switch (cycle) {
      case 'weekly': return last.add(const Duration(days: 7));
      case 'yearly': return last.add(const Duration(days: 365));
      default: return last.add(const Duration(days: 30));
    }
  }

  _MerchantPattern? _matchMerchant(String merchant, double amount) {
    for (final p in _knownMerchants.values) {
      if (RegExp(p.pattern, caseSensitive: false).hasMatch(merchant)) {
        if (p.amounts == null) return p;
        for (final a in p.amounts!) {
          if ((amount - a).abs() < 0.15) return p;
        }
      }
    }
    return null;
  }

  String _humanizeName(String raw) => raw
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ')
      .trim();

  String _normalizeCurrencyCode(String raw) {
    final upper = raw.toUpperCase().trim();
    if (CurrencyProvider.all.contains(upper)) return upper;
    // Map common symbols back to codes
    switch (upper) {
      case '\$': case 'USD': return 'USD';
      case '£': case 'GBP': return 'GBP';
      case '€': case 'EUR': return 'EUR';
      case 'CHF': return 'CHF';
      case 'SEK': return 'SEK';
      case 'NOK': return 'NOK';
      case 'DKK': return 'DKK';
      default: return 'EUR';
    }
  }

  String _guessCategory(String merchant) {
    final m = merchant.toLowerCase();
    if (RegExp(r'netflix|disney|hbo|prime|video|tv|stream|hulu|canal|sky|dazn|rtl').hasMatch(m)) return 'Entertainment';
    if (RegExp(r'spotify|apple.music|deezer|tidal|music').hasMatch(m)) return 'Music';
    if (RegExp(r'icloud|dropbox|google.*one|drive|storage|cloud').hasMatch(m)) return 'Cloud';
    if (RegExp(r'adobe|microsoft|office|notion|figma|github|gitlab').hasMatch(m)) return 'Software';
    if (RegExp(r'gym|fitness|strava|peloton|health').hasMatch(m)) return 'Health';
    if (RegExp(r'amazon|prime|deliveroo|uber|bolt|zalando').hasMatch(m)) return 'Shopping';
    return 'Other';
  }
}

class _MerchantPattern {
  final String name;
  final String category;
  final String pattern;
  final List<double>? amounts;
  _MerchantPattern(this.name, this.category, this.pattern, this.amounts);
}
