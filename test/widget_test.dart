import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/main.dart';

void main() {
  testWidgets('Splash shows the WorldScribe brand',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WorldScribeApp());
    // First frame — widgets are mounted but the fade is at 0.
    await tester.pump();
    expect(find.text('WorldScribe'), findsOneWidget);
    expect(find.text('Chronicles of worlds unwritten.'), findsOneWidget);
  });
}
