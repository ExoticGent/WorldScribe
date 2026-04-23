import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/main.dart';

void main() {
  testWidgets('WorldScribe app boots on the splash route',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WorldScribeApp());
    expect(find.text('Splash'), findsOneWidget);
  });
}
