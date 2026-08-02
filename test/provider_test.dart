import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ping/models/subscription.dart';
import 'package:ping/models/subscription_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubscriptionProvider', () {
    test('init loads empty state', () async {
      final p = SubscriptionProvider();
      await p.init();
      expect(p.subscriptions, isEmpty);
      expect(p.isLoading, isFalse);
      expect(p.activeCount, 0);
      expect(p.totalMonthly, 0.0);
    });

    test('addManual adds subscription and updates totals', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Netflix', logoUrl: 'netflix',
        amount: 15.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        category: 'Entertainment', paymentMethod: 'Credit Card',
      ));
      expect(p.subscriptions.length, 1);
      expect(p.activeCount, 1);
      expect(p.totalMonthly, closeTo(15.99, 0.01));
      expect(p.totalYearly, closeTo(15.99 * 12, 0.01));
    });

    test('setStatus pauses subscription', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Spotify', logoUrl: 'spotify',
        amount: 9.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        category: 'Music', paymentMethod: 'PayPal',
      ));
      expect(p.activeCount, 1);
      expect(p.pausedCount, 0);
      await p.setStatus('test1', SubscriptionStatus.paused);
      expect(p.activeCount, 0);
      expect(p.pausedCount, 1);
      expect(p.totalMonthly, 0.0);
    });

    test('removeSubscription removes from list', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Gym', logoUrl: 'gym',
        amount: 30.0, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        category: 'Health', paymentMethod: 'SEPA',
      ));
      expect(p.subscriptions.length, 1);
      await p.removeSubscription('test1');
      expect(p.subscriptions, isEmpty);
    });

    test('categoryBreakdown groups by category', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Netflix', logoUrl: 'netflix',
        amount: 15.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        category: 'Entertainment', paymentMethod: 'Credit Card',
      ));
      await p.addManual(Subscription(
        id: 'test2', name: 'Disney+', logoUrl: 'disney+',
        amount: 8.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 25)),
        category: 'Entertainment', paymentMethod: 'PayPal',
      ));
      await p.addManual(Subscription(
        id: 'test3', name: 'Spotify', logoUrl: 'spotify',
        amount: 9.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 15)),
        category: 'Music', paymentMethod: 'Apple Pay',
      ));
      final breakdown = p.categoryBreakdown;
      expect(breakdown['Entertainment'], closeTo(24.98, 0.01));
      expect(breakdown['Music'], closeTo(9.99, 0.01));
      expect(breakdown.length, 2);
    });

    test('upcomingBills sorts by date ascending', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Netflix', logoUrl: 'netflix',
        amount: 15.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        category: 'Entertainment', paymentMethod: 'Credit Card',
      ));
      await p.addManual(Subscription(
        id: 'test2', name: 'Spotify', logoUrl: 'spotify',
        amount: 9.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        category: 'Music', paymentMethod: 'PayPal',
      ));
      final bills = p.upcomingBills;
      expect(bills.first.name, 'Spotify');
      expect(bills.last.name, 'Netflix');
    });

    test('dueSoonCount counts bills within 3 days', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Netflix', logoUrl: 'netflix',
        amount: 15.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 2)),
        category: 'Entertainment', paymentMethod: 'Credit Card',
      ));
      await p.addManual(Subscription(
        id: 'test2', name: 'Spotify', logoUrl: 'spotify',
        amount: 9.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 10)),
        category: 'Music', paymentMethod: 'PayPal',
      ));
      expect(p.dueSoonCount, 1);
    });
  });

  group('Subscription', () {
    test('monthlyAmount converts yearly to monthly', () {
      final s = Subscription(
        id: 'test', name: 'iCloud+', logoUrl: 'icloud+',
        amount: 99.0, currency: 'EUR', billingCycle: 'yearly',
        nextBillingDate: DateTime.now().add(const Duration(days: 200)),
        category: 'Cloud', paymentMethod: 'Apple Pay',
      );
      expect(s.monthlyAmount, closeTo(8.25, 0.01));
    });

    test('monthlyAmount converts weekly to monthly', () {
      final s = Subscription(
        id: 'test', name: 'Test', logoUrl: 'test',
        amount: 5.0, currency: 'EUR', billingCycle: 'weekly',
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        category: 'Other', paymentMethod: 'Cash',
      );
      expect(s.monthlyAmount, closeTo(5.0 * 52 / 12, 0.01));
    });

    test('rollForward advances past dates', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 35));
      final s = Subscription(
        id: 'test', name: 'Test', logoUrl: 'test',
        amount: 10.0, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: oldDate,
        category: 'Other', paymentMethod: 'Cash',
      );
      final changed = s.rollForward(DateTime.now());
      expect(changed, isTrue);
      expect(s.nextBillingDate.isAfter(DateTime.now()), isTrue);
    });

    test('toJson/fromJson round-trip', () {
      final original = Subscription(
        id: 'test123', name: 'Netflix', logoUrl: 'netflix',
        amount: 15.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime(2026, 8, 15),
        category: 'Entertainment', paymentMethod: 'Credit Card',
        status: SubscriptionStatus.active, source: 'manual',
      );
      final json = original.toJson();
      final restored = Subscription.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.billingCycle, original.billingCycle);
      expect(restored.category, original.category);
      expect(restored.status, original.status);
      expect(restored.paymentMethod, original.paymentMethod);
    });
  });

  group('CurrencyProvider', () {
    test('getRate returns 1.0 for same currency', () {
      expect(CurrencyProvider.getRate('EUR', 'EUR'), 1.0);
    });

    test('getRate converts EUR to USD', () {
      final rate = CurrencyProvider.getRate('EUR', 'USD');
      expect(rate, greaterThan(1.0));
      expect(rate, lessThan(2.0));
    });

    test('getSymbol returns correct symbols', () {
      expect(CurrencyProvider.getSymbol('EUR'), '€');
      expect(CurrencyProvider.getSymbol('USD'), '\$');
      expect(CurrencyProvider.getSymbol('GBP'), '£');
    });
  });

  group('SubscriptionTheme', () {
    test('match finds Netflix theme', () {
      final theme = SubscriptionTheme.match('Netflix');
      expect(theme, isNotNull);
      expect(theme!.color, const Color(0xFFE50914));
    });

    test('match finds Spotify theme case-insensitive', () {
      final theme = SubscriptionTheme.match('SPOTIFY');
      expect(theme, isNotNull);
    });

    test('match returns null for unknown service', () {
      final theme = SubscriptionTheme.match('Unknown Service XYZ');
      expect(theme, isNull);
    });

    test('normalizeName removes special chars', () {
      expect(SubscriptionTheme.normalizeName('Disney+'), 'disney');
      expect(SubscriptionTheme.normalizeName('iCloud+'), 'icloud');
      expect(SubscriptionTheme.normalizeName('YouTube Premium'), 'youtubepremium');
    });

    test('brandIconUrl returns URL for known brands', () {
      final url = SubscriptionTheme.brandIconUrl('Netflix');
      expect(url, isNotNull);
      expect(url, contains('simpleicons'));
    });

    test('brandIconUrl returns null for unknown', () {
      final url = SubscriptionTheme.brandIconUrl('Unknown XYZ');
      expect(url, isNull);
    });
  });

  group('SortOption', () {
    test('all options have labels', () {
      for (final opt in SortOption.values) {
        expect(opt.label, isNotEmpty);
      }
    });

    test('setSortOption updates provider', () async {
      final p = SubscriptionProvider();
      await p.init();
      p.setSortOption(SortOption.amountDesc);
      expect(p.sortOption, SortOption.amountDesc);
    });

    test('setFilterCategory updates provider', () async {
      final p = SubscriptionProvider();
      await p.init();
      await p.addManual(Subscription(
        id: 'test1', name: 'Netflix', logoUrl: 'netflix',
        amount: 15.99, currency: 'EUR', billingCycle: 'monthly',
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
        category: 'Entertainment', paymentMethod: 'Credit Card',
      ));
      p.setFilterCategory('Entertainment');
      expect(p.filterCategory, 'Entertainment');
      expect(p.sortedSubscriptions.length, 1);
      p.setFilterCategory('Music');
      expect(p.sortedSubscriptions, isEmpty);
      p.setFilterCategory(null);
      expect(p.sortedSubscriptions.length, 1);
    });
  });
}
