import 'package:flutter/material.dart';

/// Represents a pre-filled subscription template.
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
    required this.category,
    this.billingCycle = 'monthly',
    required this.brandColor,
    required this.logoText,
    this.cancelGuideKey,
  });
}

/// Provides access to common subscription templates with pre-filled data.
class SubscriptionTemplates {
  static const List<SubscriptionTemplate> all = [
    SubscriptionTemplate(
      id: 'netflix',
      name: 'Netflix',
      defaultPrice: 13.99,
      currency: 'EUR',
      category: 'Entertainment',
      billingCycle: 'monthly',
      brandColor: Color(0xFFE50914),
      logoText: 'NF',
      cancelGuideKey: 'netflix',
    ),
    SubscriptionTemplate(
      id: 'spotify',
      name: 'Spotify',
      defaultPrice: 10.99,
      currency: 'EUR',
      category: 'Music',
      billingCycle: 'monthly',
      brandColor: Color(0xFF1DB954),
      logoText: 'SP',
      cancelGuideKey: 'spotify',
    ),
    SubscriptionTemplate(
      id: 'disney',
      name: 'Disney+',
      defaultPrice: 8.99,
      currency: 'EUR',
      category: 'Entertainment',
      billingCycle: 'monthly',
      brandColor: Color(0xFF0C39A7),
      logoText: 'DP',
      cancelGuideKey: 'disney',
    ),
    SubscriptionTemplate(
      id: 'youtube',
      name: 'YouTube Premium',
      defaultPrice: 11.99,
      currency: 'EUR',
      category: 'Entertainment',
      billingCycle: 'monthly',
      brandColor: Color(0xFFFF0000),
      logoText: 'YT',
      cancelGuideKey: 'youtube',
    ),
    SubscriptionTemplate(
      id: 'icloud',
      name: 'iCloud+',
      defaultPrice: 2.99,
      currency: 'EUR',
      category: 'Cloud',
      billingCycle: 'monthly',
      brandColor: Color(0xFF3693F2),
      logoText: 'iC',
      cancelGuideKey: 'icloud',
    ),
    SubscriptionTemplate(
      id: 'amazon',
      name: 'Amazon Prime',
      defaultPrice: 8.99,
      currency: 'EUR',
      category: 'Entertainment',
      billingCycle: 'monthly',
      brandColor: Color(0xFFFF9900),
      logoText: 'PR',
      cancelGuideKey: 'amazonprime',
    ),
    SubscriptionTemplate(
      id: 'adobe',
      name: 'Adobe CC',
      defaultPrice: 23.99,
      currency: 'EUR',
      category: 'Software',
      billingCycle: 'monthly',
      brandColor: Color(0xFFED2228),
      logoText: 'Ad',
      cancelGuideKey: 'adobe',
    ),
    SubscriptionTemplate(
      id: 'chatgpt',
      name: 'ChatGPT Plus',
      defaultPrice: 22.00,
      currency: 'EUR',
      category: 'Software',
      billingCycle: 'monthly',
      brandColor: Color(0xFF10A37F),
      logoText: 'GP',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'apple-music',
      name: 'Apple Music',
      defaultPrice: 10.99,
      currency: 'EUR',
      category: 'Music',
      billingCycle: 'monthly',
      brandColor: Color(0xFFFA243D),
      logoText: 'AM',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'github',
      name: 'GitHub Pro',
      defaultPrice: 4.00,
      currency: 'EUR',
      category: 'Software',
      billingCycle: 'monthly',
      brandColor: Color(0xFF8B5CF6),
      logoText: 'GH',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'notion',
      name: 'Notion',
      defaultPrice: 9.50,
      currency: 'EUR',
      category: 'Productivity',
      billingCycle: 'monthly',
      brandColor: Color(0xFF555555),
      logoText: 'No',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'dropbox',
      name: 'Dropbox',
      defaultPrice: 11.99,
      currency: 'EUR',
      category: 'Cloud',
      billingCycle: 'monthly',
      brandColor: Color(0xFF0061FF),
      logoText: 'DB',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'hbo',
      name: 'HBO Max',
      defaultPrice: 9.99,
      currency: 'EUR',
      category: 'Entertainment',
      billingCycle: 'monthly',
      brandColor: Color(0xFF8B0000),
      logoText: 'HB',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'duolingo',
      name: 'Duolingo Plus',
      defaultPrice: 6.99,
      currency: 'EUR',
      category: 'Education',
      billingCycle: 'monthly',
      brandColor: Color(0xFF58CC02),
      logoText: 'Du',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'figma',
      name: 'Figma',
      defaultPrice: 12.00,
      currency: 'EUR',
      category: 'Software',
      billingCycle: 'monthly',
      brandColor: Color(0xFFF24E1E),
      logoText: 'Fi',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: '1password',
      name: '1Password',
      defaultPrice: 2.99,
      currency: 'EUR',
      category: 'Software',
      billingCycle: 'monthly',
      brandColor: Color(0xFF0572EC),
      logoText: '1P',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'headspace',
      name: 'Headspace',
      defaultPrice: 12.99,
      currency: 'EUR',
      category: 'Health',
      billingCycle: 'monthly',
      brandColor: Color(0xFFF47B20),
      logoText: 'He',
      cancelGuideKey: null,
    ),
    SubscriptionTemplate(
      id: 'gym',
      name: 'Gym',
      defaultPrice: 29.99,
      currency: 'EUR',
      category: 'Health',
      billingCycle: 'monthly',
      brandColor: Color(0xFF6C5CE7),
      logoText: 'Gy',
      cancelGuideKey: null,
    ),
  ];

  static List<SubscriptionTemplate> get templates => all;

  /// Helper method that performs fuzzy matching by name (case-insensitive, contains check).
  static SubscriptionTemplate? findTemplate(String name) {
    if (name.trim().isEmpty) return null;
    final query = name.trim().toLowerCase();

    // 1. Exact match on name (case-insensitive)
    for (final template in all) {
      if (template.name.toLowerCase() == query) {
        return template;
      }
    }

    // 2. Exact match on id (case-insensitive)
    for (final template in all) {
      if (template.id.toLowerCase() == query) {
        return template;
      }
    }

    // 3. Contains match on name: template name contains query or query contains template name
    for (final template in all) {
      final templateName = template.name.toLowerCase();
      if (templateName.contains(query) || query.contains(templateName)) {
        return template;
      }
    }

    // 4. Contains match on id: template id contains query or query contains template id
    for (final template in all) {
      final templateId = template.id.toLowerCase();
      if (templateId.contains(query) || query.contains(templateId)) {
        return template;
      }
    }

    return null;
  }
}
