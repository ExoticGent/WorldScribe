import 'package:flutter/material.dart';

import '../screens/character_detail_screen.dart';
import '../screens/characters_screen.dart';
import '../screens/create_world_screen.dart';
import '../screens/faction_detail_screen.dart';
import '../screens/factions_screen.dart';
import '../screens/home_screen.dart';
import '../screens/location_detail_screen.dart';
import '../screens/locations_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/world_dashboard_screen.dart';
import 'constants/app_routes.dart';
import 'constants/route_args.dart';

/// Central onGenerateRoute handler. Using a single switch keeps all
/// navigation wiring in one place and makes typed arguments explicit.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);

      case AppRoutes.home:
        return _page(const HomeScreen(), settings);

      case AppRoutes.createWorld:
        return _page(const CreateWorldScreen(), settings);

      case AppRoutes.editWorld:
        final args = _require<WorldRouteArgs>(settings);
        return _page(CreateWorldScreen(worldId: args.worldId), settings);

      case AppRoutes.worldDashboard:
        final args = _require<WorldRouteArgs>(settings);
        return _page(WorldDashboardScreen(worldId: args.worldId), settings);

      case AppRoutes.characters:
        final args = _require<WorldRouteArgs>(settings);
        return _page(CharactersScreen(worldId: args.worldId), settings);

      case AppRoutes.locations:
        final args = _require<WorldRouteArgs>(settings);
        return _page(LocationsScreen(worldId: args.worldId), settings);

      case AppRoutes.factions:
        final args = _require<WorldRouteArgs>(settings);
        return _page(FactionsScreen(worldId: args.worldId), settings);

      case AppRoutes.characterDetail:
        final args = _require<CharacterRouteArgs>(settings);
        return _page(
          CharacterDetailScreen(
            worldId: args.worldId,
            characterId: args.characterId,
          ),
          settings,
        );

      case AppRoutes.locationDetail:
        final args = _require<LocationRouteArgs>(settings);
        return _page(
          LocationDetailScreen(
            worldId: args.worldId,
            locationId: args.locationId,
          ),
          settings,
        );

      case AppRoutes.factionDetail:
        final args = _require<FactionRouteArgs>(settings);
        return _page(
          FactionDetailScreen(worldId: args.worldId, factionId: args.factionId),
          settings,
        );

      default:
        return _page(
          Scaffold(
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child, RouteSettings settings) {
    return MaterialPageRoute<T>(builder: (_) => child, settings: settings);
  }

  static T _require<T>(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! T) {
      throw ArgumentError(
        'Route ${settings.name} expects arguments of type $T but got '
        '${args?.runtimeType}.',
      );
    }
    return args;
  }
}
