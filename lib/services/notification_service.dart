import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/subscription_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  static Future<void> scheduleBillReminder(Subscription sub) async {
    await init();
    final daysLeft = sub.nextBillingDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return;

    for (final offset in [3, 1, 0]) {
      final notifyDate = sub.nextBillingDate.subtract(Duration(days: offset));
      if (notifyDate.isBefore(DateTime.now())) continue;

      await _plugin.zonedSchedule(
        sub.id.hashCode + offset,
        offset == 0
            ? '💰 ${sub.name} billed today'
            : '⏰ ${sub.name} due in $offset day${offset > 1 ? "s" : ""}',
        '${sub.currency}${sub.amount.toStringAsFixed(2)} will be charged${offset > 0 ? " on ${_fmt(sub.nextBillingDate)}" : ""}',
        tz.TZDateTime.from(notifyDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('bills', 'Bill Reminders',
              channelDescription: 'Upcoming bill alerts', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(sound: 'default'),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> scheduleTrialReminder({
    required String serviceName, required DateTime trialEnd, required int id,
  }) async {
    await init();
    for (final offset in [7, 3, 1]) {
      final notifyDate = trialEnd.subtract(Duration(days: offset));
      if (notifyDate.isBefore(DateTime.now())) continue;

      await _plugin.zonedSchedule(
        id * 100 + offset,
        '⏳ $serviceName trial ends in $offset day${offset > 1 ? "s" : ""}',
        'Cancel before ${_fmt(trialEnd)} to avoid being charged.',
        tz.TZDateTime.from(notifyDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('trials', 'Trial Expiration',
              channelDescription: 'Free trial expiration alerts', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(sound: 'default'),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelForSubscription(String subId) async {
    await init();
    for (final offset in [3, 1, 0]) {
      await _plugin.cancel(subId.hashCode + offset);
    }
  }

  static Future<void> cancelAll() async { await init(); await _plugin.cancelAll(); }

  static Future<void> showNow(String title, String body) async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails('general', 'General', importance: Importance.high),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]}';
  }
}
