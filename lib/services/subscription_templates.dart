import 'package:flutter/material.dart';

/// 常见订阅模板 — 预填价格、分类、品牌色，用于快速添加和 onboarding 预填。
class SubscriptionTemplate {
  final String id;
  final String name;
  final double defaultPrice;
  final String currency;
  final String category;
  final String billingCycle;
  final Color brandColor;
  final String logoText;
  final String? cancelGuideKey;

  const SubscriptionTemplate({
    required this.id,
    required this.name,
    required this.defaultPrice,
    this.currency = 'EUR',
    this.category = 'Entertainment',
    this.billingCycle = 'monthly',
    required this.brandColor,
    required this.logoText,
    this.cancelGuideKey,
  });
}

class SubscriptionTemplates {
  static const List<SubscriptionTemplate> all = [
    SubscriptionTemplate(id: 'netflix', name: 'Netflix', defaultPrice: 13.99, category: 'Entertainment', brandColor: Color(0xFFE50914), logoText: 'NF', cancelGuideKey: 'netflix'),
    SubscriptionTemplate(id: 'spotify', name: 'Spotify', defaultPrice: 10.99, category: 'Music', brandColor: Color(0xFF1DB954), logoText: 'SP', cancelGuideKey: 'spotify'),
    SubscriptionTemplate(id: 'disney', name: 'Disney+', defaultPrice: 8.99, category: 'Entertainment', brandColor: Color(0xFF0C39A7), logoText: 'DP', cancelGuideKey: 'disney'),
    SubscriptionTemplate(id: 'youtube', name: 'YouTube Premium', defaultPrice: 11.99, category: 'Entertainment', brandColor: Color(0xFFFF0000), logoText: 'YT', cancelGuideKey: 'youtube'),
    SubscriptionTemplate(id: 'icloud', name: 'iCloud+', defaultPrice: 2.99, category: 'Cloud', brandColor: Color(0xFF3693F2), logoText: 'iC', cancelGuideKey: 'icloud'),
    SubscriptionTemplate(id: 'amazon', name: 'Amazon Prime', defaultPrice: 8.99, category: 'Entertainment', brandColor: Color(0xFFFF9900), logoText: 'PR', cancelGuideKey: 'amazonprime'),
    SubscriptionTemplate(id: 'adobe', name: 'Adobe CC', defaultPrice: 23.99, category: 'Software', brandColor: Color(0xFFED2228), logoText: 'Ad', cancelGuideKey: 'adobe'),
    SubscriptionTemplate(id: 'chatgpt', name: 'ChatGPT Plus', defaultPrice: 22.00, category: 'Software', brandColor: Color(0xFF10A37F), logoText: 'GP'),
    SubscriptionTemplate(id: 'apple-music', name: 'Apple Music', defaultPrice: 10.99, category: 'Music', brandColor: Color(0xFFFA243D), logoText: 'AM'),
    SubscriptionTemplate(id: 'github', name: 'GitHub Pro', defaultPrice: 4.00, category: 'Software', brandColor: Color(0xFF8B5CF6), logoText: 'GH'),
    SubscriptionTemplate(id: 'notion', name: 'Notion', defaultPrice: 9.50, category: 'Productivity', brandColor: Color(0xFF555555), logoText: 'No'),
    SubscriptionTemplate(id: 'dropbox', name: 'Dropbox', defaultPrice: 11.99, category: 'Cloud', brandColor: Color(0xFF0061FF), logoText: 'DB'),
    SubscriptionTemplate(id: 'hbo', name: 'HBO Max', defaultPrice: 9.99, category: 'Entertainment', brandColor: Color(0xFF8B0000), logoText: 'HB'),
    SubscriptionTemplate(id: 'duolingo', name: 'Duolingo Plus', defaultPrice: 6.99, category: 'Education', brandColor: Color(0xFF58CC02), logoText: 'Du'),
    SubscriptionTemplate(id: 'figma', name: 'Figma', defaultPrice: 12.00, category: 'Software', brandColor: Color(0xFFF24E1E), logoText: 'Fi'),
    SubscriptionTemplate(id: '1password', name: '1Password', defaultPrice: 2.99, category: 'Software', brandColor: Color(0xFF0572EC), logoText: '1P'),
    SubscriptionTemplate(id: 'headspace', name: 'Headspace', defaultPrice: 12.99, category: 'Health', brandColor: Color(0xFFF47B20), logoText: 'He'),
    SubscriptionTemplate(id: 'gym', name: 'Gym', defaultPrice: 29.99, category: 'Health', brandColor: Color(0xFF6C5CE7), logoText: 'Gy'),
  ];

  /// 模糊匹配模板
  static SubscriptionTemplate? findTemplate(String name) {
    final lower = name.toLowerCase().trim();
    for (final t in all) {
      if (t.id == lower || t.name.toLowerCase() == lower) return t;
    }
    for (final t in all) {
      if (t.name.toLowerCase().contains(lower) || lower.contains(t.name.toLowerCase())) return t;
    }
    for (final t in all) {
      if (t.id.contains(lower) || lower.contains(t.id)) return t;
    }
    return null;
  }
}
