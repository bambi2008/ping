import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WidgetService {
  static const _key = 'widget_data';

  static Future<void> updateWidgetData({
    required String totalMonthly,
    required String currency,
    required int activeCount,
    required List<Map<String, String>> upcoming,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      'total': totalMonthly, 'currency': currency,
      'active': activeCount,
      'upcoming': upcoming.take(4).toList(),
      'updated': DateTime.now().toIso8601String(),
    }));
  }

  static Future<Map<String, dynamic>?> readWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
