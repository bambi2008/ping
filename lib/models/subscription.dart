import 'dart:ui';

enum SubscriptionStatus {
  active,
  paused,
  cancelled,
  trial,
  expired;

  String get label => switch (this) {
        active => 'Active',
        paused => 'Paused',
        cancelled => 'Cancelled',
        trial => 'Trial',
        expired => 'Expired',
      };
}

class Subscription {
  final String id;
  String name;
  String logoUrl;
  double amount;
  String currency;
  String billingCycle;
  DateTime nextBillingDate;
  String category;
  SubscriptionStatus status;
  String paymentMethod;
  DateTime? pausedUntil;
  String source;
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
    this.status = SubscriptionStatus.active,
    bool? isActive,
    this.paymentMethod = 'Unknown',
    this.pausedUntil,
    this.source = 'manual',
    this.themeColor,
  }) {
    if (isActive != null) {
      status = isActive ? SubscriptionStatus.active : SubscriptionStatus.paused;
    }
  }

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;

  double get monthlyAmount {
    switch (billingCycle) {
      case 'yearly':
        return amount / 12;
      case 'weekly':
        return amount * 52 / 12;
      default:
        return amount;
    }
  }

  double convertedMonthlyAmount(String targetCurrency) {
    return monthlyAmount * CurrencyProvider.getRate(currency, targetCurrency);
  }

  String get currencySymbol => CurrencyProvider.getSymbol(currency);

  /// Moves an active recurring bill to its next real calendar occurrence.
  bool rollForward(DateTime now) {
    if (!isActive || nextBillingDate.isAfter(now)) return false;
    do {
      nextBillingDate = _addCycle(nextBillingDate);
    } while (!nextBillingDate.isAfter(now));
    return true;
  }

  DateTime _addCycle(DateTime date) {
    switch (billingCycle) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'yearly':
        return _safeDate(date.year + 1, date.month, date.day);
      default:
        final nextMonth = date.month == 12 ? 1 : date.month + 1;
        final nextYear = date.month == 12 ? date.year + 1 : date.year;
        return _safeDate(nextYear, nextMonth, date.day);
    }
  }

  DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'amount': amount,
        'currency': currency,
        'billingCycle': billingCycle,
        'nextBillingDate': nextBillingDate.toIso8601String(),
        'category': category,
        'status': status.name,
        'paymentMethod': paymentMethod,
        'pausedUntil': pausedUntil?.toIso8601String(),
        'source': source,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final legacyActive = json['isActive'] as bool?;
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      category: json['category'] as String? ?? 'Other',
      status: SubscriptionStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => legacyActive == false
            ? SubscriptionStatus.paused
            : SubscriptionStatus.active,
      ),
      paymentMethod: json['paymentMethod'] as String? ?? 'Unknown',
      pausedUntil: json['pausedUntil'] == null
          ? null
          : DateTime.tryParse(json['pausedUntil'] as String),
      source: json['source'] as String? ?? 'manual',
    );
  }
}

/// Currency provider with exchange rates and symbols.
class CurrencyProvider {
  static const Map<String, String> _symbols = {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'CHF': 'Fr.',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'RON': 'lei',
    'BGN': 'лв',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
  };

  static const Map<String, double> _rates = {
    'EUR': 1.0,
    'USD': 1.08,
    'GBP': 0.85,
    'CHF': 0.95,
    'SEK': 11.3,
    'NOK': 11.5,
    'DKK': 7.45,
    'PLN': 4.3,
    'CZK': 25.0,
    'HUF': 390.0,
    'RON': 4.97,
    'BGN': 1.96,
    'JPY': 160.0,
    'CAD': 1.48,
    'AUD': 1.65,
  };

  static final List<String> popular = [
    'EUR',
    'USD',
    'GBP',
    'CHF',
    'SEK',
    'NOK',
    'DKK',
    'PLN'
  ];
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
    'netflix': SubscriptionTheme(const Color(0xFFE50914), 'netflix'),
    'spotify': SubscriptionTheme(const Color(0xFF1DB954), 'spotify'),
    'disney+': SubscriptionTheme(const Color(0xFF113CCF), 'disney'),
    'amazon prime': SubscriptionTheme(const Color(0xFF00A8E1), 'amazon'),
    'icloud+': SubscriptionTheme(const Color(0xFF3693F5), 'icloud'),
    'apple': SubscriptionTheme(const Color(0xFF555555), 'apple'),
    'youtube': SubscriptionTheme(const Color(0xFFFF0000), 'youtube'),
    'adobe cc': SubscriptionTheme(const Color(0xFFFF0000), 'adobe'),
    'google one': SubscriptionTheme(const Color(0xFF4285F4), 'google'),
    'microsoft 365': SubscriptionTheme(const Color(0xFF00A4EF), 'microsoft'),
    'dropbox': SubscriptionTheme(const Color(0xFF0061FF), 'dropbox'),
    'hbo max': SubscriptionTheme(const Color(0xFF5822B4), 'hbo'),
    'gym': SubscriptionTheme(const Color(0xFFFF6B6B), 'gym'),
    'dazn': SubscriptionTheme(const Color(0xFF00AAFF), 'dazn'),
    'sky': SubscriptionTheme(const Color(0xFF0072C6), 'sky'),
    'deezer': SubscriptionTheme(const Color(0xFFA238FF), 'deezer'),
    'strava': SubscriptionTheme(const Color(0xFFFC4C02), 'strava'),
    'deliveroo': SubscriptionTheme(const Color(0xFF00CCBC), 'deliveroo'),
    'canal+': SubscriptionTheme(const Color(0xFF000000), 'canal'),
    'rtl+': SubscriptionTheme(const Color(0xFFFF0033), 'rtl'),
    'zalando': SubscriptionTheme(const Color(0xFFFF6900), 'zalando'),
    'bolt': SubscriptionTheme(const Color(0xFF34D186), 'bolt'),
    'notion': SubscriptionTheme(const Color(0xFF000000), 'notion'),
    'figma': SubscriptionTheme(const Color(0xFFA259FF), 'figma'),
    'github': SubscriptionTheme(const Color(0xFF24292E), 'github'),
    'gitlab': SubscriptionTheme(const Color(0xFFFC6D26), 'gitlab'),
  };

  static SubscriptionTheme? match(String name) {
    final key = normalizeName(name);
    // Exact match
    for (final entry in themes.entries) {
      if (normalizeName(entry.key) == key) return entry.value;
    }
    // Partial match
    for (final entry in themes.entries) {
      final normalizedEntry = normalizeName(entry.key);
      if (key.contains(normalizedEntry) || normalizedEntry.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String normalizeName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static final Map<String, Color> categoryColors = {
    'Entertainment': const Color(0xFFE50914),
    'Music': const Color(0xFF1DB954),
    'Cloud': const Color(0xFF3693F5),
    'Software': const Color(0xFFA259FF),
    'Health': const Color(0xFFFF6B6B),
    'Shopping': const Color(0xFFFF6900),
    'Food': const Color(0xFF00CCBC),
    'Other': const Color(0xFF6C5CE7),
  };
}
