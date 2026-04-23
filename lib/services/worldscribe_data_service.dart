import 'package:flutter/foundation.dart';

import '../models/character.dart';
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
  // -- Worlds ---------------------------------------------------------------

  List<World> get worlds;

  World? worldById(String id);

  World addWorld({
    required String name,
    required String genre,
    required String description,
  });

  void updateWorld(World updated);

  void deleteWorld(String id);

  // -- Characters -----------------------------------------------------------

  List<Character> charactersFor(String worldId);

  Character? characterById(String worldId, String characterId);

  Character addCharacter({
    required String worldId,
    required String name,
    required String role,
    required String description,
  });

  void updateCharacter(Character updated);

  void deleteCharacter({
    required String worldId,
    required String characterId,
  });
}
