import 'package:flutter/services.dart';

import '../models/subscription.dart';

class NotificationService {
  static const _channel = MethodChannel('ping/notifications');

  static Future<void> init() async {}

  static Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  static Future<void> scheduleBillReminder(Subscription subscription) async {
    if (!subscription.isActive ||
        !subscription.nextBillingDate.isAfter(DateTime.now())) {
      return;
    }

    for (final offset in [3, 1, 0]) {
      final billingDate = DateTime(
        subscription.nextBillingDate.year,
        subscription.nextBillingDate.month,
        subscription.nextBillingDate.day,
        9,
      );
      final notifyDate = billingDate.subtract(Duration(days: offset));
      if (notifyDate.isBefore(DateTime.now())) continue;

      await _schedule(
        id: subscription.id.hashCode + offset,
        title: offset == 0
            ? '💰 ${subscription.name} billed today'
            : '⏰ ${subscription.name} due in $offset '
                'day${offset > 1 ? "s" : ""}',
        body: '${subscription.currencySymbol}'
            '${subscription.amount.toStringAsFixed(2)} will be charged'
            '${offset > 0 ? " on ${_fmt(subscription.nextBillingDate)}" : ""}',
        date: notifyDate,
      );
    }
  }

  static Future<void> scheduleTrialReminder({
    required String serviceName,
    required DateTime trialEnd,
    required int id,
  }) async {
    for (final offset in [7, 3, 1]) {
      final notifyDate = DateTime(
        trialEnd.year,
        trialEnd.month,
        trialEnd.day,
        9,
      ).subtract(Duration(days: offset));
      if (notifyDate.isBefore(DateTime.now())) continue;
      await _schedule(
        id: id * 100 + offset,
        title: '⏳ $serviceName trial ends in $offset '
            'day${offset > 1 ? "s" : ""}',
        body: 'Cancel before ${_fmt(trialEnd)} to avoid being charged.',
        date: notifyDate,
      );
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) =>
      _channel.invokeMethod<void>('schedule', {
        'id': id,
        'title': title,
        'body': body,
        'epochMillis': date.millisecondsSinceEpoch,
      });

  static Future<void> cancelForSubscription(String subscriptionId) async {
    for (final offset in [3, 1, 0]) {
      await _channel.invokeMethod<void>(
        'cancel',
        {'id': subscriptionId.hashCode + offset},
      );
    }
  }

  static Future<void> cancelAll() => _channel.invokeMethod<void>('cancelAll');

  static Future<void> showNow(String title, String body) =>
      _channel.invokeMethod<void>('showNow', {
        'id': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'title': title,
        'body': body,
      });

  static String _fmt(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
