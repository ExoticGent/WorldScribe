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

  // Give the test surface a phone-sized window so popup menus, dialogs,
  // and sliver app bars all fit without RenderFlex overflows.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 1600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
  });

  testWidgets('Splash shows the WorldScribe brand then hands off to Home', (
    tester,
  ) async {
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

  testWidgets('Create World saves and navigates to the dashboard', (
    tester,
  ) async {
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

  testWidgets('Edit world updates the dashboard details', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.worldDashboard,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit world'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'World name'),
      'Aerenthal Reforged',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Aerenthal Reforged'), findsWidgets);
    expect(
      InMemoryDataService.instance.worldById(world.id)?.name,
      'Aerenthal Reforged',
    );
  });

  testWidgets('Delete world from dashboard returns to Home', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        onGenerateRoute: AppRouter.generate,
        initialRoute: AppRoutes.home,
        onGenerateInitialRoutes: (_) => [
          AppRouter.generate(const RouteSettings(name: AppRoutes.home)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(world.name).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete world'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Your Worlds'), findsOneWidget);
    expect(InMemoryDataService.instance.worldById(world.id), isNull);
  });

  testWidgets('AI Forge generates a character for the current world', (
    tester,
  ) async {
    final world = InMemoryDataService.instance.worlds.first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.worldDashboard,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI Forge'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Prompt'),
      'A palace archivist who trades in forbidden maps',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Generate Character'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Forged The Glass Archivist'), findsOneWidget);
    expect(
      InMemoryDataService.instance
          .charactersFor(world.id)
          .any((character) => character.name == 'The Glass Archivist'),
      isTrue,
    );
  });

  testWidgets('Add location flow pushes a new row onto Locations', (
    tester,
  ) async {
    final world = InMemoryDataService.instance.worlds.first;
    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.locations,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New Location'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'The Hollow Observatory',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Location'));
    await tester.pumpAndSettle();

    expect(find.text('The Hollow Observatory'), findsOneWidget);
  });

  testWidgets('Add character flow pushes a new row onto Characters', (
    tester,
  ) async {
    final world = InMemoryDataService.instance.worlds.first;
    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.characters,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'New Character'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'The Unnamed',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Character'));
    await tester.pumpAndSettle();

    expect(find.text('The Unnamed'), findsOneWidget);
  });

  testWidgets('Edit character from detail updates the card', (tester) async {
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

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit character'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      '${character.name} Reforged',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('${character.name} Reforged'), findsWidgets);
    expect(
      InMemoryDataService.instance
          .characterById(world.id, character.id)
          ?.name,
      '${character.name} Reforged',
    );
  });

  testWidgets('Delete from Character Detail removes the character', (
    tester,
  ) async {
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

  testWidgets('Location detail shows the selected location', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final location = await InMemoryDataService.instance.addLocation(
      worldId: world.id,
      name: 'The Hollow Observatory',
      type: 'Ruined spire',
      description: 'A telescope nest perched above the ash storms.',
    );

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.locationDetail,
        arguments: LocationRouteArgs(
          worldId: world.id,
          locationId: location.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The Hollow Observatory'), findsWidgets);
    expect(find.text('Ruined spire'), findsOneWidget);
    expect(
      find.text('A telescope nest perched above the ash storms.'),
      findsOneWidget,
    );
  });

  testWidgets('Edit location from detail updates the card', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final location = await InMemoryDataService.instance.addLocation(
      worldId: world.id,
      name: 'The Hollow Observatory',
      type: 'Ruined spire',
      description: 'Old.',
    );

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.locationDetail,
        arguments: LocationRouteArgs(
          worldId: world.id,
          locationId: location.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit location'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'The Hollow Observatory Reforged',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('The Hollow Observatory Reforged'), findsWidgets);
    expect(
      InMemoryDataService.instance.locationById(world.id, location.id)?.name,
      'The Hollow Observatory Reforged',
    );
  });

  testWidgets('Delete from Location Detail removes the location', (
    tester,
  ) async {
    final world = InMemoryDataService.instance.worlds.first;
    final location = await InMemoryDataService.instance.addLocation(
      worldId: world.id,
      name: 'The Hollow Observatory',
      type: 'Ruined spire',
      description: 'Doomed.',
    );

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.locationDetail,
        arguments: LocationRouteArgs(
          worldId: world.id,
          locationId: location.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(location.name), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete location'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      InMemoryDataService.instance.locationById(world.id, location.id),
      isNull,
    );
  });

  testWidgets('Factions dashboard tile opens the faction list', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final faction = InMemoryDataService.instance.factionsFor(world.id).first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.worldDashboard,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Factions'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FloatingActionButton, 'New Faction'),
      findsOneWidget,
    );
    expect(find.text(faction.name), findsOneWidget);
  });

  testWidgets('Add faction flow pushes a new row onto Factions', (
    tester,
  ) async {
    final world = InMemoryDataService.instance.worlds.first;
    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.factions,
        arguments: WorldRouteArgs(worldId: world.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New Faction'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'The Glass Court',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ideology'),
      'Order through ritual.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Faction'));
    await tester.pumpAndSettle();

    expect(find.text('The Glass Court'), findsOneWidget);
    expect(
      InMemoryDataService.instance
          .factionsFor(world.id)
          .any((faction) => faction.name == 'The Glass Court'),
      isTrue,
    );
  });

  testWidgets('Faction detail shows the selected faction', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final faction = InMemoryDataService.instance.factionsFor(world.id).first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.factionDetail,
        arguments: FactionRouteArgs(worldId: world.id, factionId: faction.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(faction.name), findsWidgets);
    expect(find.text(faction.ideology), findsOneWidget);
    expect(find.text(faction.description), findsOneWidget);
    expect(find.text('LINKED CHARACTERS'), findsOneWidget);
    expect(find.text('LINKED LOCATIONS'), findsOneWidget);
  });

  testWidgets('Edit faction from detail updates the card', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final faction = InMemoryDataService.instance.factionsFor(world.id).first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.factionDetail,
        arguments: FactionRouteArgs(worldId: world.id, factionId: faction.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit faction'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      '${faction.name} Reforged',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('${faction.name} Reforged'), findsWidgets);
    expect(
      InMemoryDataService.instance.factionById(world.id, faction.id)?.name,
      '${faction.name} Reforged',
    );
  });

  testWidgets('Delete from Faction Detail removes the faction', (tester) async {
    final world = InMemoryDataService.instance.worlds.first;
    final faction = InMemoryDataService.instance.factionsFor(world.id).first;

    await tester.pumpWidget(
      _appAtRoute(
        AppRoutes.factionDetail,
        arguments: FactionRouteArgs(worldId: world.id, factionId: faction.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(faction.name), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete faction'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      InMemoryDataService.instance.factionById(world.id, faction.id),
      isNull,
    );
  });

  testWidgets(
    'Link a character from Faction Detail surfaces it and persists the link',
    (tester) async {
      final world = InMemoryDataService.instance.worlds.first;
      final faction = InMemoryDataService.instance.factionsFor(world.id).first;
      final character = InMemoryDataService.instance
          .charactersFor(world.id)
          .first;

      await tester.pumpWidget(
        _appAtRoute(
          AppRoutes.factionDetail,
          arguments: FactionRouteArgs(worldId: world.id, factionId: faction.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LINKED CHARACTERS'), findsOneWidget);
      expect(find.textContaining('No characters linked yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Link a character'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(character.name));
      await tester.pumpAndSettle();

      expect(find.text(character.name), findsWidgets);
      expect(
        InMemoryDataService.instance
            .factionById(world.id, faction.id)
            ?.characterIds,
        contains(character.id),
      );
      expect(
        InMemoryDataService.instance
            .characterById(world.id, character.id)
            ?.factionIds,
        contains(faction.id),
      );

      await tester.tap(find.byIcon(Icons.link_off).first);
      await tester.pumpAndSettle();

      expect(
        InMemoryDataService.instance
            .factionById(world.id, faction.id)
            ?.characterIds,
        isEmpty,
      );
      expect(
        InMemoryDataService.instance
            .characterById(world.id, character.id)
            ?.factionIds,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Link a location from Faction Detail surfaces it and persists the link',
    (tester) async {
      final world = InMemoryDataService.instance.worlds.first;
      final faction = InMemoryDataService.instance.factionsFor(world.id).first;
      final location = await InMemoryDataService.instance.addLocation(
        worldId: world.id,
        name: 'The Salt Terraces',
        type: 'Coastline',
        description: '',
      );

      await tester.pumpWidget(
        _appAtRoute(
          AppRoutes.factionDetail,
          arguments: FactionRouteArgs(worldId: world.id, factionId: faction.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LINKED LOCATIONS'), findsOneWidget);
      expect(find.textContaining('No locations linked yet'), findsOneWidget);

      await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Link a location'),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Link a location'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(location.name));
      await tester.pumpAndSettle();

      expect(find.text(location.name), findsWidgets);
      expect(
        InMemoryDataService.instance
            .factionById(world.id, faction.id)
            ?.locationIds,
        contains(location.id),
      );
      expect(
        InMemoryDataService.instance
            .locationById(world.id, location.id)
            ?.factionIds,
        contains(faction.id),
      );
    },
  );

  testWidgets(
    'Link a location from Character Detail surfaces it and persists the link',
    (tester) async {
      final world = InMemoryDataService.instance.worlds.first;
      final character = InMemoryDataService.instance
          .charactersFor(world.id)
          .first;
      final location = await InMemoryDataService.instance.addLocation(
        worldId: world.id,
        name: 'The Salt Terraces',
        type: 'Coastline',
        description: '',
      );

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

      // Empty linked-locations panel is shown by default.
      expect(find.text('LINKED LOCATIONS'), findsOneWidget);
      expect(find.textContaining('No locations linked yet'), findsOneWidget);

      // Open the picker via the "Link a location" action button.
      await tester.tap(find.widgetWithText(TextButton, 'Link a location'));
      await tester.pumpAndSettle();

      // Pick the only available location.
      await tester.tap(find.text('The Salt Terraces'));
      await tester.pumpAndSettle();

      // Linked section now lists it on both UI and data layer.
      expect(find.text('The Salt Terraces'), findsOneWidget);
      expect(
        InMemoryDataService.instance
            .characterById(world.id, character.id)
            ?.locationIds,
        contains(location.id),
      );
      expect(
        InMemoryDataService.instance
            .locationById(world.id, location.id)
            ?.characterIds,
        contains(character.id),
      );

      // Tapping the unlink icon removes the link from both sides.
      await tester.tap(find.byIcon(Icons.link_off));
      await tester.pumpAndSettle();

      expect(
        InMemoryDataService.instance
            .characterById(world.id, character.id)
            ?.locationIds,
        isEmpty,
      );
      expect(
        InMemoryDataService.instance
            .locationById(world.id, location.id)
            ?.characterIds,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Link a character from Location Detail surfaces it and persists the link',
    (tester) async {
      final world = InMemoryDataService.instance.worlds.first;
      final character = InMemoryDataService.instance
          .charactersFor(world.id)
          .first;
      final location = await InMemoryDataService.instance.addLocation(
        worldId: world.id,
        name: 'The Salt Terraces',
        type: 'Coastline',
        description: '',
      );

      await tester.pumpWidget(
        _appAtRoute(
          AppRoutes.locationDetail,
          arguments: LocationRouteArgs(
            worldId: world.id,
            locationId: location.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LINKED CHARACTERS'), findsOneWidget);
      expect(find.textContaining('No characters linked yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Link a character'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(character.name));
      await tester.pumpAndSettle();

      expect(find.text(character.name), findsWidgets);
      expect(
        InMemoryDataService.instance
            .locationById(world.id, location.id)
            ?.characterIds,
        contains(character.id),
      );

      await tester.tap(find.byIcon(Icons.link_off));
      await tester.pumpAndSettle();

      expect(
        InMemoryDataService.instance
            .locationById(world.id, location.id)
            ?.characterIds,
        isEmpty,
      );
      expect(
        InMemoryDataService.instance
            .characterById(world.id, character.id)
            ?.locationIds,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Link picker on Character Detail hides locations already linked',
    (tester) async {
      final world = InMemoryDataService.instance.worlds.first;
      final character = InMemoryDataService.instance
          .charactersFor(world.id)
          .first;
      final linked = await InMemoryDataService.instance.addLocation(
        worldId: world.id,
        name: 'The Salt Terraces',
        type: 'Coastline',
        description: '',
      );
      final available = await InMemoryDataService.instance.addLocation(
        worldId: world.id,
        name: 'The Glass Spire',
        type: 'Watchtower',
        description: '',
      );
      await InMemoryDataService.instance.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: linked.id,
      );

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

      await tester.tap(find.widgetWithText(TextButton, 'Link a location'));
      await tester.pumpAndSettle();

      // Picker only offers the not-yet-linked location.
      expect(find.text(available.name), findsOneWidget);
      // The already-linked one shows in the linked-section behind the
      // sheet but never duplicates as a picker option.
      final salt = find.text(linked.name);
      expect(salt, findsOneWidget);
    },
  );

  testWidgets('Back from Create World with no edits pops without prompting', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithStack(top: AppRoutes.createWorld));
    await tester.pumpAndSettle();

    // Nothing typed -> PopScope.canPop is true -> the route just pops.
    await Navigator.of(
      tester.element(find.text('Forge a New World')),
    ).maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Forge a New World'), findsNothing);
    expect(find.text('Your Worlds'), findsOneWidget);
  });

  testWidgets(
    'Back from Create World with edits prompts; Keep editing keeps the form',
    (tester) async {
      await tester.pumpWidget(_appWithStack(top: AppRoutes.createWorld));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'World name'),
        'Half typed',
      );
      // Two pumps: the first runs the controller listener + setState, the
      // second commits the new PopScope.canPop value into the framework.
      await tester.pump();
      await tester.pump();

      await Navigator.of(
        tester.element(find.text('Forge a New World')),
      ).maybePop();
      await tester.pumpAndSettle();

      // PopScope intercepted the pop; the discard prompt is on screen.
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Forge a New World'), findsOneWidget);

      // Keep editing keeps the form on screen with its draft intact.
      await tester.tap(find.widgetWithText(TextButton, 'Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Forge a New World'), findsOneWidget);
      expect(find.text('Half typed'), findsOneWidget);
    },
  );

  testWidgets('Discarding from Create World pops back to the previous route', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithStack(top: AppRoutes.createWorld));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'World name'),
      'Throwaway',
    );
    await tester.pump();
    await tester.pump();

    await Navigator.of(
      tester.element(find.text('Forge a New World')),
    ).maybePop();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Forge a New World'), findsNothing);
    expect(find.text('Your Worlds'), findsOneWidget);
    // No partial world was persisted.
    expect(
      InMemoryDataService.instance.worlds.any((w) => w.name == 'Throwaway'),
      isFalse,
    );
  });

  testWidgets(
    'Discarding from the Add Character sheet closes the sheet without saving',
    (tester) async {
      final world = InMemoryDataService.instance.worlds.first;
      final originalCount = InMemoryDataService.instance
          .charactersFor(world.id)
          .length;

      await tester.pumpWidget(
        _appAtRoute(
          AppRoutes.characters,
          arguments: WorldRouteArgs(worldId: world.id),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'New Character'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Unfinished hero',
      );
      await tester.pump();
      await tester.pump();

      // Sheet title text exists alongside the FAB label, so disambiguate
      // via the topmost form field's element.
      await Navigator.of(
        tester.element(find.widgetWithText(TextFormField, 'Name')),
      ).maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();

      // Sheet is gone (its name field unmounts), character was never saved.
      expect(find.widgetWithText(TextFormField, 'Name'), findsNothing);
      expect(
        InMemoryDataService.instance.charactersFor(world.id).length,
        originalCount,
      );
    },
  );
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

/// Builds an app whose initial route stack is Home → [top] so that the
/// top route has somewhere to pop back to. Used by the discard-changes
/// guard tests where popping the only route would exit the harness.
Widget _appWithStack({required String top, Object? arguments}) {
  return MaterialApp(
    theme: AppTheme.dark,
    onGenerateRoute: AppRouter.generate,
    initialRoute: top,
    onGenerateInitialRoutes: (_) => [
      AppRouter.generate(const RouteSettings(name: AppRoutes.home)),
      AppRouter.generate(RouteSettings(name: top, arguments: arguments)),
    ],
  );
}
