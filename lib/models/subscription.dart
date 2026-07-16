import 'dart:ui';

class Subscription {
  final String id;
  String name;
  final String logoUrl;
  final double amount;
  String currency;
  final String billingCycle;
  final DateTime nextBillingDate;
  String category;
  bool isActive;
  String paymentMethod;
  final DateTime? pausedUntil;
  final String? source;
  Color? themeColor;

  Subscription({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.amount,
    this.currency = '€',
    required this.billingCycle,
    required this.nextBillingDate,
    this.category = 'Other',
    this.isActive = true,
    this.paymentMethod = 'Unknown',
    this.pausedUntil,
    this.source,
    this.themeColor,
  });

  double get monthlyAmount {
    switch (billingCycle) {
      case 'yearly': return amount / 12;
      case 'weekly': return amount * 4.33;
      default: return amount;
    }
  }

  double convertedMonthlyAmount(String targetCurrency) {
    return monthlyAmount * CurrencyProvider.getRate(currency, targetCurrency);
  }

  String get currencySymbol => CurrencyProvider.getSymbol(currency);
}

/// Currency provider with exchange rates and symbols.
class CurrencyProvider {
  static const Map<String, String> _symbols = {
    'EUR': '€', 'USD': '\$', 'GBP': '£', 'CHF': 'Fr.', 'SEK': 'kr',
    'NOK': 'kr', 'DKK': 'kr', 'PLN': 'zł', 'CZK': 'Kč', 'HUF': 'Ft',
    'RON': 'lei', 'BGN': 'лв', 'JPY': '¥', 'CAD': 'C\$', 'AUD': 'A\$',
  };

  static const Map<String, double> _rates = {
    'EUR': 1.0, 'USD': 1.08, 'GBP': 0.85, 'CHF': 0.95, 'SEK': 11.3,
    'NOK': 11.5, 'DKK': 7.45, 'PLN': 4.3, 'CZK': 25.0, 'HUF': 390.0,
    'RON': 4.97, 'BGN': 1.96, 'JPY': 160.0, 'CAD': 1.48, 'AUD': 1.65,
  };

  static final List<String> popular = ['EUR', 'USD', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK', 'PLN'];
  static final List<String> all = _rates.keys.toList()..sort();

  static String getSymbol(String code) => _symbols[code] ?? code;
  static double getRate(String from, String to) {
    if (from == to) return 1.0;
    final fromRate = _rates[from] ?? 1.0;
    final toRate = _rates[to] ?? 1.0;
    return toRate / fromRate;
  }
}

/// Logo/theme library — colors and icons for known subscription services.
class SubscriptionTheme {
  final Color color;
  final String iconName;
  const SubscriptionTheme(this.color, this.iconName);

  static final Map<String, SubscriptionTheme> themes = {
    'netflix':      SubscriptionTheme(const Color(0xFFE50914), 'netflix'),
    'spotify':      SubscriptionTheme(const Color(0xFF1DB954), 'spotify'),
    'disney+':      SubscriptionTheme(const Color(0xFF113CCF), 'disney'),
    'amazon prime': SubscriptionTheme(const Color(0xFF00A8E1), 'amazon'),
    'icloud+':      SubscriptionTheme(const Color(0xFF3693F5), 'icloud'),
    'apple':        SubscriptionTheme(const Color(0xFF555555), 'apple'),
    'youtube':      SubscriptionTheme(const Color(0xFFFF0000), 'youtube'),
    'adobe cc':     SubscriptionTheme(const Color(0xFFFF0000), 'adobe'),
    'google one':   SubscriptionTheme(const Color(0xFF4285F4), 'google'),
    'microsoft 365':SubscriptionTheme(const Color(0xFF00A4EF), 'microsoft'),
    'dropbox':      SubscriptionTheme(const Color(0xFF0061FF), 'dropbox'),
    'hbo max':      SubscriptionTheme(const Color(0xFF5822B4), 'hbo'),
    'gym':          SubscriptionTheme(const Color(0xFFFF6B6B), 'gym'),
    'dazn':         SubscriptionTheme(const Color(0xFF00AAFF), 'dazn'),
    'sky':          SubscriptionTheme(const Color(0xFF0072C6), 'sky'),
    'deezer':       SubscriptionTheme(const Color(0xFFA238FF), 'deezer'),
    'strava':       SubscriptionTheme(const Color(0xFFFC4C02), 'strava'),
    'deliveroo':    SubscriptionTheme(const Color(0xFF00CCBC), 'deliveroo'),
    'canal+':       SubscriptionTheme(const Color(0xFF000000), 'canal'),
    'rtl+':         SubscriptionTheme(const Color(0xFFFF0033), 'rtl'),
    'zalando':      SubscriptionTheme(const Color(0xFFFF6900), 'zalando'),
    'bolt':         SubscriptionTheme(const Color(0xFF34D186), 'bolt'),
    'notion':       SubscriptionTheme(const Color(0xFF000000), 'notion'),
    'figma':        SubscriptionTheme(const Color(0xFFA259FF), 'figma'),
    'github':       SubscriptionTheme(const Color(0xFF24292E), 'github'),
    'gitlab':       SubscriptionTheme(const Color(0xFFFC6D26), 'gitlab'),
  };

  static SubscriptionTheme? match(String name) {
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();
    // Exact match
    if (themes.containsKey(key)) return themes[key];
    // Partial match
    for (final entry in themes.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) return entry.value;
    }
    return null;
  }

  static final Map<String, Color> categoryColors = {
    'Entertainment': const Color(0xFFE50914),
    'Music':         const Color(0xFF1DB954),
    'Cloud':         const Color(0xFF3693F5),
    'Software':      const Color(0xFFA259FF),
    'Health':        const Color(0xFFFF6B6B),
    'Shopping':      const Color(0xFFFF6900),
    'Food':          const Color(0xFF00CCBC),
    'Other':         const Color(0xFF6C5CE7),
  };
}
