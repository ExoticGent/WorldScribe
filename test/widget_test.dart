import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/core/constants/app_routes.dart';
import 'package:worldscribe/core/constants/route_args.dart';
import 'package:worldscribe/core/router.dart';
import 'package:worldscribe/core/theme/app_theme.dart';
import 'package:worldscribe/main.dart';
import 'package:worldscribe/services/in_memory_data_service.dart';

void main() {
  setUp(() {
    InMemoryDataService.instance.resetForTests();
  });

  // Give the test surface a phone-sized window so popup menus, dialogs,
  // and sliver app bars all fit without RenderFlex overflows.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize =
        const Size(800, 1600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
  });

  testWidgets('Splash shows the WorldScribe brand then hands off to Home',
      (tester) async {
    await tester.pumpWidget(const WorldScribeApp());

    // Initial frame: splash is mounted.
    await tester.pump();
    expect(find.text('WorldScribe'), findsOneWidget);
    expect(find.text('Chronicles of worlds unwritten.'), findsOneWidget);

    // Let the splash timer elapse and navigation settle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Your Worlds'), findsOneWidget);
  });

  testWidgets('Home renders seeded worlds', (tester) async {
    await tester.pumpWidget(_appAtHome());
    await tester.pumpAndSettle();

    expect(find.text('Aerenthal'), findsOneWidget);
    expect(find.text('Neo-Havana'), findsOneWidget);
  });

  testWidgets('Create World saves and navigates to the dashboard',
      (tester) async {
    await tester.pumpWidget(_appAtRoute(AppRoutes.createWorld));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'World name'),
      'Testoria',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Genre'),
      'Low fantasy',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create World'));
    await tester.pumpAndSettle();

    // After save we land on the world dashboard with the name in the app bar.
    expect(find.text('Testoria'), findsWidgets);
    expect(find.text('Characters'), findsOneWidget);
  });

  testWidgets('Add character flow pushes a new row onto Characters',
      (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    await tester.pumpWidget(_appAtRoute(
      AppRoutes.characters,
      arguments: WorldRouteArgs(worldId: world.id),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(
      FloatingActionButton,
      'New Character',
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'The Unnamed',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Character'));
    await tester.pumpAndSettle();

    expect(find.text('The Unnamed'), findsOneWidget);
  });

  testWidgets('Delete from Character Detail removes the character',
      (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final character = InMemoryDataService.instance.charactersFor(world.id).first;

    await tester.pumpWidget(_appAtRoute(
      AppRoutes.characterDetail,
      arguments: CharacterRouteArgs(
        worldId: world.id,
        characterId: character.id,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(character.name), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete character'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      InMemoryDataService.instance.characterById(world.id, character.id),
      isNull,
    );
  });
}

Widget _appAtHome() => _appAtRoute(AppRoutes.home);

Widget _appAtRoute(String route, {Object? arguments}) {
  return MaterialApp(
    theme: AppTheme.dark,
    onGenerateRoute: AppRouter.generate,
    initialRoute: route,
    onGenerateInitialRoutes: (initialRoute) => [
      AppRouter.generate(
        RouteSettings(name: initialRoute, arguments: arguments),
      ),
    ],
  );
}
