import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/widgets/confirm_dialog.dart';

/// Mounts a button that opens [ConfirmDialog]; the dialog's resolved
/// value is reported back via a SnackBar so we can assert on it from
/// the widget tree without smuggling the future out of the closure.
Widget _harness({required bool isDestructive}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ConfirmDialog.show(
              context,
              title: 'Title?',
              message: 'Body.',
              confirmLabel: 'Confirm',
              isDestructive: isDestructive,
            ).then((value) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('result=$value')));
            }),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders title, message, and both action labels', (tester) async {
    await tester.pumpWidget(_harness(isDestructive: false));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Title?'), findsOneWidget);
    expect(find.text('Body.'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('returns true when confirm is tapped', (tester) async {
    await tester.pumpWidget(_harness(isDestructive: true));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('result=true'), findsOneWidget);
  });

  testWidgets('returns false when cancel is tapped', (tester) async {
    await tester.pumpWidget(_harness(isDestructive: false));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('result=false'), findsOneWidget);
  });

  testWidgets('returns false when dismissed via the scrim', (tester) async {
    await tester.pumpWidget(_harness(isDestructive: false));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap near a corner where only the modal barrier sits.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('result=false'), findsOneWidget);
  });
}
