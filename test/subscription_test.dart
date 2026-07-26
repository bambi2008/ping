import 'package:flutter_test/flutter_test.dart';
import 'package:ping/models/subscription.dart';

void main() {
  group('Subscription lifecycle', () {
    test('monthly renewal preserves the calendar day when possible', () {
      final subscription = Subscription(
        id: 'monthly',
        name: 'Example',
        logoUrl: '',
        amount: 10,
        billingCycle: 'monthly',
        nextBillingDate: DateTime(2026, 1, 31),
      );

      expect(subscription.rollForward(DateTime(2026, 2, 1)), isTrue);
      expect(subscription.nextBillingDate, DateTime(2026, 2, 28));
    });

    test('an old renewal rolls forward until it is in the future', () {
      final subscription = Subscription(
        id: 'weekly',
        name: 'Example',
        logoUrl: '',
        amount: 10,
        billingCycle: 'weekly',
        nextBillingDate: DateTime(2026, 1, 1),
      );

      subscription.rollForward(DateTime(2026, 1, 20));

      expect(subscription.nextBillingDate, DateTime(2026, 1, 22));
    });

    test('cancelled subscriptions do not roll forward', () {
      final subscription = Subscription(
        id: 'cancelled',
        name: 'Example',
        logoUrl: '',
        amount: 10,
        billingCycle: 'monthly',
        nextBillingDate: DateTime(2026, 1, 1),
        status: SubscriptionStatus.cancelled,
      );

      expect(subscription.rollForward(DateTime(2026, 2, 1)), isFalse);
      expect(subscription.nextBillingDate, DateTime(2026, 1, 1));
    });

    test('JSON round-trip preserves editable fields and status', () {
      final original = Subscription(
        id: 'json',
        name: 'Example',
        logoUrl: 'example',
        amount: 19.99,
        currency: 'GBP',
        billingCycle: 'yearly',
        nextBillingDate: DateTime(2027, 3, 14),
        category: 'Software',
        status: SubscriptionStatus.trial,
        paymentMethod: 'PayPal',
      );

      final restored = Subscription.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.nextBillingDate, original.nextBillingDate);
      expect(restored.status, SubscriptionStatus.trial);
    });
  });
}
