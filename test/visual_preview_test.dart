import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/core/constants/app_routes.dart';
import 'package:worldscribe/core/constants/route_args.dart';
import 'package:worldscribe/core/router.dart';
import 'package:worldscribe/core/theme/app_theme.dart';
import 'package:worldscribe/main.dart';
import 'package:worldscribe/services/in_memory_data_service.dart';
import 'package:worldscribe/services/service_locator.dart';

import 'fake_ai_forge_service.dart';

void main() {
  setUp(() async {
    InMemoryDataService.instance.resetForTests();
    await InMemoryDataService.instance.initialize();
    configureAiForgeService(const FakeAiForgeService());
  });

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize = const Size(900, 1600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
  });

  testWidgets('capture splash preview', (tester) async {
    await tester.pumpWidget(const WorldScribeApp());
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/splash_preview.png'),
    );
  });

  testWidgets('capture home preview', (tester) async {
    await tester.pumpWidget(_appAtRoute(AppRoutes.home));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_preview.png'),
    );
  });

  testWidgets('capture world dashboard preview', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.worldDashboard,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/world_dashboard_preview.png'),
    );
  });

  testWidgets('capture character detail preview', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final character = InMemoryDataService.instance
        .charactersFor(world.id)
        .first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.characterDetail,
        arguments: CharacterRouteArgs(
          worldId: world.id,
          characterId: character.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/character_detail_preview.png'),
    );
  });
}

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
