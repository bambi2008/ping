import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'subscription.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const _subscriptionsKey = 'subscriptions_v1';
  static const _currencyKey = 'currency';
  static const _notificationsKey = 'notifications';

  final List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _displayCurrency = 'EUR';
  bool _notificationsEnabled = false;

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get displayCurrency => _displayCurrency;
  bool get notificationsEnabled => _notificationsEnabled;

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

  static const paymentMethods = [
    'Apple Pay',
    'PayPal',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'SEPA',
    'iDEAL',
    'Unknown',
  ];
  static const categories = [
    'Entertainment',
    'Music',
    'Cloud',
    'Software',
    'Health',
    'Shopping',
    'Food',
    'Other',
  ];
  static const cycles = ['weekly', 'monthly', 'yearly'];

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
    await _persist();
    await NotificationService.cancelForSubscription(id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _subscriptions.clear();
    await _persist();
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

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final value = jsonEncode(
        _subscriptions.map((subscription) => subscription.toJson()).toList());
    await prefs.setString(_subscriptionsKey, value);
  }
}
