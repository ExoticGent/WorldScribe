import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/core/constants/app_strings.dart';
import 'package:worldscribe/main.dart';
import 'package:worldscribe/services/firestore_data_service.dart';
import 'package:worldscribe/services/in_memory_data_service.dart';
import 'package:worldscribe/services/service_locator.dart';

import '../fake_ai_forge_service.dart';

/// End-to-end smoke test that drives the real [WorldScribeApp] widget
/// through a [FirestoreDataService] backed by an in-memory fake
/// Firestore. Catches breakage at the UI ↔ data-service boundary that
/// neither the unit tests of [FirestoreDataService] nor the widget
/// tests against [InMemoryDataService] would notice on their own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late FirestoreDataService service;

  const userId = 'integration-user';

  CollectionReference<Map<String, dynamic>> worldsRef() =>
      firestore.collection('users').doc(userId).collection('worlds');

  // Phone-sized surface so popup menus, dialogs, and sliver app bars all
  // lay out without RenderFlex overflows. Mirrors widget_test.dart.
  setUpAll(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 1600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
  });

  setUp(() async {
    // Make sure no leftover state from prior test files leaks in via
    // the singleton in-memory service or the global service locator.
    InMemoryDataService.instance.resetForTests();

    firestore = FakeFirebaseFirestore();
    service = FirestoreDataService(firestore: firestore, userId: userId);
    await service.initialize();
    configureDataService(service, mode: DataServiceMode.firestore);
    configureAiForgeService(const FakeAiForgeService());
  });

  tearDown(() async {
    service.dispose();
    // Restore the locator to the in-memory service so subsequent test
    // files (which assume the default wiring) keep working.
    InMemoryDataService.instance.resetForTests();
    await InMemoryDataService.instance.initialize();
    configureDataService(InMemoryDataService.instance);
  });

  testWidgets(
    'Boots through splash to home with no worlds shows the empty state',
    (tester) async {
      await tester.pumpWidget(const WorldScribeApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.homeTitle), findsOneWidget);
      expect(find.text(AppStrings.homeEmpty), findsOneWidget);
    },
  );

  testWidgets('Creating a world through the UI persists the doc in Firestore', (
    tester,
  ) async {
    await tester.pumpWidget(const WorldScribeApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Open the create-world form via the home FAB.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.worldNameLabel),
      'Stormreach',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.worldGenreLabel),
      'High fantasy',
    );

    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.createAction),
    );
    await tester.pumpAndSettle();

    // UI lands on the new world's dashboard.
    expect(find.text('Stormreach'), findsWidgets);
    expect(find.text(AppStrings.charactersSection), findsOneWidget);

    // And Firestore has the doc with matching fields.
    final docs = await worldsRef().get();
    expect(docs.docs, hasLength(1));
    final data = docs.docs.first.data();
    expect(data['name'], 'Stormreach');
    expect(data['genre'], 'High fantasy');
  });
}
