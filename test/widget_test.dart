import 'package:flutter_test/flutter_test.dart';
import 'package:ping/main.dart';
import 'package:ping/models/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders an empty dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final provider = SubscriptionProvider();
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const PingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(find.text('Add Manually'), findsOneWidget);
    expect(find.text('Connect Bank'), findsNothing);
    expect(find.text('Premium'), findsNothing);
  });
}
