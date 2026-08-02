import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'subscription.dart';

/// Sort options for subscription list
enum SortOption { nameAsc, nameDesc, amountDesc, amountAsc, dateAsc, dateDesc }

extension SortOptionLabel on SortOption {
  String get label => switch (this) {
        SortOption.nameAsc => 'Name A-Z',
        SortOption.nameDesc => 'Name Z-A',
        SortOption.amountDesc => 'Amount: High-Low',
        SortOption.amountAsc => 'Amount: Low-High',
        SortOption.dateAsc => 'Next bill: Soonest',
        SortOption.dateDesc => 'Next bill: Latest',
      };
  IconData get icon => switch (this) {
        SortOption.nameAsc => Icons.sort_by_alpha,
        SortOption.nameDesc => Icons.sort_by_alpha,
        SortOption.amountDesc => Icons.attach_money,
        SortOption.amountAsc => Icons.attach_money,
        SortOption.dateAsc => Icons.calendar_today,
        SortOption.dateDesc => Icons.calendar_today,
      };
}

class SubscriptionProvider extends ChangeNotifier {
  static const _subscriptionsKey = 'subscriptions_v1';
  static const _currencyKey = 'currency';
  static const _notificationsKey = 'notifications';
  static const _lastMonthKey = 'last_month_total';
  static const _lastMonthDateKey = 'last_month_date';
  static const _monthlyHistoryKey = 'monthly_history_v1';
  static const _priceHistoryKey = 'price_history_v1';

  final List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _displayCurrency = 'EUR';
  bool _notificationsEnabled = false;
  double _lastMonthTotal = 0;

  // ── Sort & Filter State ──
  SortOption _sortOption = SortOption.dateAsc;
  String? _filterCategory;

  // ── Monthly History (for trend chart) ──
  final List<MapEntry<DateTime, double>> _monthlyHistory = [];

  // ── Price Change History ──
  // Map: subscriptionId → list of (date, oldAmount, newAmount)
  final Map<String, List<_PriceChange>> _priceHistory = {};

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get displayCurrency => _displayCurrency;
  bool get notificationsEnabled => _notificationsEnabled;
  double get lastMonthTotal => _lastMonthTotal;
  double get momChange => totalMonthly - _lastMonthTotal;
  bool get momAvailable => _lastMonthTotal > 0;
  SortOption get sortOption => _sortOption;
  String? get filterCategory => _filterCategory;

  /// Sorted & filtered subscription list
  List<Subscription> get sortedSubscriptions {
    var list = _filterCategory == null
        ? List<Subscription>.from(_subscriptions)
        : _subscriptions.where((s) => s.category == _filterCategory).toList();

    list.sort((a, b) {
      switch (_sortOption) {
        case SortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case SortOption.amountDesc:
          return b.convertedMonthlyAmount(_displayCurrency)
              .compareTo(a.convertedMonthlyAmount(_displayCurrency));
        case SortOption.amountAsc:
          return a.convertedMonthlyAmount(_displayCurrency)
              .compareTo(b.convertedMonthlyAmount(_displayCurrency));
        case SortOption.dateAsc:
          return a.nextBillingDate.compareTo(b.nextBillingDate);
        case SortOption.dateDesc:
          return b.nextBillingDate.compareTo(a.nextBillingDate);
      }
    });
    return list;
  }

  /// All categories present in subscriptions
  List<String> get availableCategories =>
      _subscriptions.map((s) => s.category).toSet().toList()..sort();

  /// Monthly history for trend chart (oldest first)
  List<MapEntry<DateTime, double>> get monthlyHistory =>
      List.unmodifiable(_monthlyHistory);

  /// Price changes for a subscription
  List<_PriceChange>? priceChangesFor(String id) => _priceHistory[id];

  double get totalMonthly =>
      _subscriptions.where((subscription) => subscription.isActive).fold(
          0,
          (sum, subscription) =>
              sum + subscription.convertedMonthlyAmount(_displayCurrency));
  double get totalYearly => totalMonthly * 12;
  int get activeCount =>
      _subscriptions.where((subscription) => subscription.isActive).length;
  int get pausedCount => _subscriptions
      .where((subscription) => subscription.status == SubscriptionStatus.paused)
      .length;

  Map<String, double> get categoryBreakdown {
    final breakdown = <String, double>{};
    for (final subscription in _subscriptions.where((item) => item.isActive)) {
      breakdown[subscription.category] =
          (breakdown[subscription.category] ?? 0) +
              subscription.convertedMonthlyAmount(_displayCurrency);
    }
    return breakdown;
  }

  List<Subscription> get upcomingBills {
    final active =
        _subscriptions.where((subscription) => subscription.isActive).toList()
          ..sort(
            (first, second) =>
                first.nextBillingDate.compareTo(second.nextBillingDate),
          );
    return active;
  }

  int get dueSoonCount {
    final now = DateTime.now();
    return upcomingBills.where((subscription) {
      final days = DateTime(
        subscription.nextBillingDate.year,
        subscription.nextBillingDate.month,
        subscription.nextBillingDate.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
      return days >= 0 && days <= 3;
    }).length;
  }

  // ── Bills for a specific month (calendar view) ──
  List<Subscription> billsForMonth(int year, int month) {
    return _subscriptions.where((s) {
      final d = s.nextBillingDate;
      return s.isActive && d.year == year && d.month == month;
    }).toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  static const paymentMethods = [
    'Apple Pay', 'PayPal', 'Credit Card', 'Debit Card',
    'Bank Transfer', 'SEPA', 'iDEAL', 'Unknown',
  ];
  static const categories = [
    'Entertainment', 'Music', 'Cloud', 'Software',
    'Health', 'Shopping', 'Food', 'Other',
  ];
  static const cycles = ['weekly', 'monthly', 'yearly'];

  // ── Sort & Filter Actions ──
  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _displayCurrency = prefs.getString(_currencyKey) ?? 'EUR';
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;
      final raw = prefs.getString(_subscriptionsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _subscriptions
          ..clear()
          ..addAll(decoded.map(
            (item) => _enrichSubscription(
              Subscription.fromJson(item as Map<String, dynamic>),
            ),
          ));
      }

      // Load monthly history
      final historyRaw = prefs.getString(_monthlyHistoryKey);
      if (historyRaw != null) {
        final historyList = jsonDecode(historyRaw) as List<dynamic>;
        _monthlyHistory
          ..clear()
          ..addAll(historyList.map((e) {
            final parts = (e as String).split('|');
            return MapEntry(DateTime.parse(parts[0]), double.parse(parts[1]));
          }));
      }

      // Load price history
      final priceRaw = prefs.getString(_priceHistoryKey);
      if (priceRaw != null) {
        final priceMap = jsonDecode(priceRaw) as Map<String, dynamic>;
        _priceHistory.clear();
        for (final entry in priceMap.entries) {
          final changes = (entry.value as List<dynamic>)
              .map((c) => _PriceChange(
                    DateTime.parse((c as Map)['date']),
                    (c['old'] as num).toDouble(),
                    (c['new'] as num).toDouble(),
                  ))
              .toList();
          _priceHistory[entry.key] = changes;
        }
      }

      _lastMonthTotal = prefs.getDouble(_lastMonthKey) ?? 0;
      CurrencyProvider.fetchLiveRates();
      _maybeUpdateMonthlySnapshot(prefs);

      final changed = _rollForwardBillingDates();
      if (changed) await _persist();
      if (_notificationsEnabled) await scheduleAllNotifications();
    } on FormatException {
      _errorMessage =
          'Saved data could not be read. Your subscriptions were not changed.';
    } catch (error) {
      _errorMessage = 'Could not load subscriptions: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String code) async {
    _displayCurrency = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
    notifyListeners();
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) return false;
    }
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    if (enabled) {
      await scheduleAllNotifications();
    } else {
      await NotificationService.cancelAll();
    }
    notifyListeners();
    return true;
  }

  Future<void> scheduleAllNotifications() async {
    if (!_notificationsEnabled) return;
    await NotificationService.cancelAll();
    for (final subscription in upcomingBills) {
      await NotificationService.scheduleBillReminder(subscription);
    }
  }

  Future<void> addManual(Subscription subscription) async {
    final enriched = _enrichSubscription(subscription);
    _subscriptions.add(enriched);
    await _persist();
    if (_notificationsEnabled) {
      await NotificationService.scheduleBillReminder(enriched);
    }
    notifyListeners();
  }

  Future<void> updateSubscription(
    String id, {
    String? name,
    double? amount,
    String? billingCycle,
    DateTime? nextBillingDate,
    String? category,
    String? paymentMethod,
    String? currency,
    SubscriptionStatus? status,
  }) async {
    final subscription = _subscriptions.firstWhere((item) => item.id == id);
    if (name != null) {
      subscription
        ..name = name
        ..logoUrl = name.toLowerCase();
      final theme = SubscriptionTheme.match(name);
      subscription.themeColor = theme?.color;
    }
    // ── Track price change ──
    if (amount != null && amount != subscription.amount) {
      final now = DateTime.now();
      _priceHistory.putIfAbsent(id, () => []);
      _priceHistory[id]!.add(_PriceChange(now, subscription.amount, amount));
      _persistPriceHistory();
    }
    if (amount != null) subscription.amount = amount;
    if (billingCycle != null) subscription.billingCycle = billingCycle;
    if (nextBillingDate != null) {
      subscription.nextBillingDate = nextBillingDate;
    }
    if (category != null) subscription.category = category;
    if (paymentMethod != null) subscription.paymentMethod = paymentMethod;
    if (currency != null) subscription.currency = currency;
    if (status != null) subscription.status = status;

    if (subscription.isActive) subscription.rollForward(DateTime.now());
    await _persist();
    await NotificationService.cancelForSubscription(id);
    if (_notificationsEnabled && subscription.isActive) {
      await NotificationService.scheduleBillReminder(subscription);
    }
    notifyListeners();
  }

  Future<void> setStatus(String id, SubscriptionStatus status) =>
      updateSubscription(id, status: status);

  Future<void> removeSubscription(String id) async {
    _subscriptions.removeWhere((subscription) => subscription.id == id);
    _priceHistory.remove(id);
    await _persist();
    await _persistPriceHistory();
    await NotificationService.cancelForSubscription(id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _subscriptions.clear();
    _priceHistory.clear();
    _monthlyHistory.clear();
    await _persist();
    await _persistPriceHistory();
    await NotificationService.cancelAll();
    notifyListeners();
  }

  Subscription _enrichSubscription(Subscription subscription) {
    subscription.themeColor = SubscriptionTheme.match(subscription.name)?.color;
    return subscription;
  }

  bool _rollForwardBillingDates() {
    var changed = false;
    for (final subscription in _subscriptions) {
      changed = subscription.rollForward(DateTime.now()) || changed;
    }
    return changed;
  }

  void _maybeUpdateMonthlySnapshot(SharedPreferences prefs) {
    final now = DateTime.now();
    final lastDateStr = prefs.getString(_lastMonthDateKey);
    final lastDate = lastDateStr != null ? DateTime.tryParse(lastDateStr) : null;

    if (lastDate == null ||
        lastDate.month != now.month ||
        lastDate.year != now.year) {
      // Save current month's total to history before updating
      if (lastDate != null) {
        final monthKey = DateTime(lastDate.year, lastDate.month);
        // Replace if same month exists
        _monthlyHistory.removeWhere((e) =>
            e.key.year == monthKey.year && e.key.month == monthKey.month);
        _monthlyHistory.add(MapEntry(monthKey, totalMonthly));
        _persistMonthlyHistory();
      }
      prefs.setDouble(_lastMonthKey, totalMonthly);
      prefs.setString(_lastMonthDateKey, now.toIso8601String());
      _lastMonthTotal = totalMonthly;
    }
  }

  /// Manually record a monthly snapshot (for testing or explicit capture)
  void recordMonthlySnapshot() {
    final now = DateTime.now();
    final monthKey = DateTime(now.year, now.month);
    _monthlyHistory.removeWhere(
        (e) => e.key.year == monthKey.year && e.key.month == monthKey.month);
    _monthlyHistory.add(MapEntry(monthKey, totalMonthly));
    _monthlyHistory.sort((a, b) => a.key.compareTo(b.key));
    _persistMonthlyHistory();
    notifyListeners();
  }

  void _persistMonthlyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _monthlyHistory
        .map((e) => '${e.key.toIso8601String()}|${e.value}')
        .toList();
    await prefs.setString(_monthlyHistoryKey, jsonEncode(encoded));
  }

  void _persistPriceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _priceHistory.map((id, changes) => MapEntry(
          id,
          changes
              .map((c) => {'date': c.date.toIso8601String(), 'old': c.oldAmount, 'new': c.newAmount})
              .toList(),
        ));
    await prefs.setString(_priceHistoryKey, jsonEncode(encoded));
  }

  Future<void> refresh() async {
    final changed = _rollForwardBillingDates();
    if (changed) {
      await _persist();
      if (_notificationsEnabled) await scheduleAllNotifications();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final value = jsonEncode(
        _subscriptions.map((subscription) => subscription.toJson()).toList());
    await prefs.setString(_subscriptionsKey, value);
  }
}

/// Price change record
class _PriceChange {
  final DateTime date;
  final double oldAmount;
  final double newAmount;
  _PriceChange(this.date, this.oldAmount, this.newAmount);

  double get delta => newAmount - oldAmount;
  bool get isIncrease => newAmount > oldAmount;
}
