import 'package:flutter/foundation.dart';

import '../models/character.dart';
import '../models/location.dart';
import '../models/world.dart';

/// Data-access contract for the whole app.
///
/// Every screen talks to the app's data layer through this abstraction,
/// not through a concrete class. This makes the in-memory MVP impl
/// ([InMemoryDataService]) and the future Firestore impl
/// ([FirestoreDataService]) drop-in interchangeable. Swap at startup
/// via the [service_locator].
///
/// Implementations must extend [ChangeNotifier] so screens can wrap
/// reads in `ListenableBuilder` and rebuild on change.
abstract class WorldscribeDataService extends ChangeNotifier {
  bool get isLoading;

  String? get errorMessage;

  Future<void> initialize();

  // -- Worlds ---------------------------------------------------------------

  List<World> get worlds;

  World? worldById(String id);

  Future<World> addWorld({
    required String name,
    required String genre,
    required String description,
  });

  Future<void> updateWorld(World updated);

  Future<void> deleteWorld(String id);

  // -- Characters -----------------------------------------------------------

  List<Character> charactersFor(String worldId);

  Character? characterById(String worldId, String characterId);

  Future<Character> addCharacter({
    required String worldId,
    required String name,
    required String role,
    required String description,
  });

  Future<void> updateCharacter(Character updated);

  Future<void> deleteCharacter({
    required String worldId,
    required String characterId,
  });

  // -- Locations ------------------------------------------------------------

  List<Location> locationsFor(String worldId);

  Location? locationById(String worldId, String locationId);

  Future<Location> addLocation({
    required String worldId,
    required String name,
    required String type,
    required String description,
  });
}
