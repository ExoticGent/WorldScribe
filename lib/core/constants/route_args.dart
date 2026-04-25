// Typed argument objects for named routes. Using a typed object instead of
// raw maps keeps navigation call-sites safer as the app grows.

class WorldRouteArgs {
  const WorldRouteArgs({required this.worldId});

  final String worldId;
}

class CharacterRouteArgs {
  const CharacterRouteArgs({required this.worldId, required this.characterId});

  final String worldId;
  final String characterId;
}

class LocationRouteArgs {
  const LocationRouteArgs({required this.worldId, required this.locationId});

  final String worldId;
  final String locationId;
}
