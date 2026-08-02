import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// IAP provider — manages subscription state.
/// In production, this connects to StoreKit (iOS) / Google Play Billing.
/// For now, it simulates purchase flow and persists trial/subscription state.
class IAPProvider extends ChangeNotifier {
  static const _subStatusKey = 'iap_status_v1';
  static const _trialStartKey = 'iap_trial_start_v1';
  static const _subExpiryKey = 'iap_sub_expiry_v1';
  static const _planKey = 'iap_plan_v1';

  SubscriptionStatus _status = SubscriptionStatus.expired;
  DateTime? _trialStart;
  DateTime? _subExpiry;
  SubscriptionPlan _plan = SubscriptionPlan.none;

  SubscriptionStatus get status => _status;
  DateTime? get trialStart => _trialStart;
  DateTime? get subExpiry => _subExpiry;
  SubscriptionPlan get plan => _plan;
  bool get hasAccess => _status == SubscriptionStatus.trial || _status == SubscriptionStatus.active;
  bool get isOnTrial => _status == SubscriptionStatus.trial;
  bool get isExpired => _status == SubscriptionStatus.expired;

  /// Days remaining in trial (3-day trial)
  int get trialDaysLeft {
    if (_trialStart == null || _status != SubscriptionStatus.trial) return 0;
    final elapsed = DateTime.now().difference(_trialStart!).inDays;
    return (3 - elapsed).clamp(0, 3);
  }

  /// Days remaining in subscription
  int get subDaysLeft {
    if (_subExpiry == null) return 0;
    return _subExpiry!.difference(DateTime.now()).inDays;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final statusName = prefs.getString(_subStatusKey);
    if (statusName != null) {
      _status = SubscriptionStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => SubscriptionStatus.expired,
      );
    }
    final trialRaw = prefs.getString(_trialStartKey);
    if (trialRaw != null) _trialStart = DateTime.parse(trialRaw);
    final expiryRaw = prefs.getString(_subExpiryKey);
    if (expiryRaw != null) _subExpiry = DateTime.parse(expiryRaw);
    final planName = prefs.getString(_planKey);
    if (planName != null) {
      _plan = SubscriptionPlan.values.firstWhere(
        (p) => p.name == planName,
        orElse: () => SubscriptionPlan.none,
      );
    }

    // Check if trial expired
    if (_status == SubscriptionStatus.trial && trialDaysLeft <= 0) {
      _status = SubscriptionStatus.expired;
      await _persist();
    }
    // Check if subscription expired
    if (_status == SubscriptionStatus.active && subDaysLeft <= 0) {
      _status = SubscriptionStatus.expired;
      await _persist();
    }

    notifyListeners();
  }

  /// Start 3-day free trial (no payment yet in this simulation)
  Future<void> startTrial() async {
    _status = SubscriptionStatus.trial;
    _trialStart = DateTime.now();
    _plan = SubscriptionPlan.none;
    await _persist();
    notifyListeners();
  }

  /// Purchase a subscription plan
  Future<void> purchase(SubscriptionPlan plan) async {
    _isLoading = true;
    notifyListeners();
    // Simulate StoreKit purchase delay
    await Future.delayed(const Duration(milliseconds: 800));
    _plan = plan;
    _status = SubscriptionStatus.active;
    _trialStart ??= DateTime.now();
    _subExpiry = plan == SubscriptionPlan.yearly
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 30));
    await _persist();
    _isLoading = false;
    notifyListeners();
  }

  /// Cancel subscription (still has access until expiry)
  Future<void> cancel() async {
    // In production, this would revoke via StoreKit
    // For now, just mark as cancelled at expiry
    await _persist();
    notifyListeners();
  }

  /// Restore purchases
  Future<void> restore() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    // Check stored state
    await init();
    _isLoading = false;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subStatusKey, _status.name);
    await prefs.setString(_trialStartKey, _trialStart?.toIso8601String() ?? '');
    await prefs.setString(_subExpiryKey, _subExpiry?.toIso8601String() ?? '');
    await prefs.setString(_planKey, _plan.name);
  }
}

enum SubscriptionStatus { trial, active, expired }
enum SubscriptionPlan { none, monthly, yearly }

extension SubscriptionPlanInfo on SubscriptionPlan {
  String get label => switch (this) {
        SubscriptionPlan.none => 'Free Trial',
        SubscriptionPlan.monthly => 'Monthly',
        SubscriptionPlan.yearly => 'Yearly',
      };
  String get price => switch (this) {
        SubscriptionPlan.none => '',
        SubscriptionPlan.monthly => '€2.99',
        SubscriptionPlan.yearly => '€19.99',
      };
  String get period => switch (this) {
        SubscriptionPlan.none => '',
        SubscriptionPlan.monthly => '/month',
        SubscriptionPlan.yearly => '/year',
      };
}
