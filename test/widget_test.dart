import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartifyApp());

    // Verify that the app starts by checking for the presence of the SmartifyApp widget.
    expect(find.byType(SmartifyApp), findsOneWidget);
  });
}
