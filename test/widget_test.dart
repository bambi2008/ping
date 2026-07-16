import 'package:flutter_test/flutter_test.dart';
import 'package:ping/main.dart';

void main() {
  testWidgets('App renders dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const PingApp());
    await tester.pump(const Duration(milliseconds: 700)); // wait for mock data
    expect(find.text('Ping'), findsOneWidget);
  });
}
