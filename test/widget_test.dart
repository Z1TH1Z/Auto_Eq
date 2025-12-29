import 'package:flutter_test/flutter_test.dart';
import 'package:auto_eq_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoEQApp());
    expect(find.text('Auto EQ'), findsOneWidget);
  });
}
