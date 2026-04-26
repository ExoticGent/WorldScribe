import 'package:flutter/foundation.dart';

import '../models/character.dart';
import '../models/location.dart';
import '../models/world.dart';
import 'worldscribe_data_service.dart';

/// In-memory implementation of [WorldscribeDataService] used during the
/// mock-data phase of the MVP. Notifies listeners whenever worlds or
/// characters change, so screens can rebuild with `ListenableBuilder`.
///
/// The public surface intentionally mirrors the Firestore-backed
/// [FirestoreDataService] so the swap stays small — the service locator
/// is the only thing that needs to change.
class InMemoryDataService extends WorldscribeDataService {
  InMemoryDataService._() {
    _seedMockData();
  }

  /// Singleton accessor. The service locator returns this by default.
  /// Tests reset it through [resetForTests].
  static final InMemoryDataService instance = InMemoryDataService._();

  final List<World> _worlds = [];
  final Map<String, List<Character>> _charactersByWorld = {};
  final Map<String, List<Location>> _locationsByWorld = {};

  int _idSeq = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> initialize() async {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // -- Worlds ---------------------------------------------------------------

  @override
  List<World> get worlds => List.unmodifiable(_worlds);

  @override
  World? worldById(String id) {
    for (final w in _worlds) {
      if (w.id == id) return w;
    }
    return null;
  }

  @override
  Future<World> addWorld({
    required String name,
    required String genre,
    required String description,
  }) async {
    final world = World(
      id: _nextId('world'),
      name: name.trim(),
      genre: genre.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _worlds.insert(0, world);
    _charactersByWorld[world.id] = [];
    _locationsByWorld[world.id] = [];
    notifyListeners();
    return world;
  }

  @override
  Future<void> updateWorld(World updated) async {
    final i = _worlds.indexWhere((w) => w.id == updated.id);
    if (i == -1) return;
    _worlds[i] = updated;
    notifyListeners();
  }

  @override
  Future<void> deleteWorld(String id) async {
    _worlds.removeWhere((w) => w.id == id);
    _charactersByWorld.remove(id);
    _locationsByWorld.remove(id);
    notifyListeners();
  }

  // -- Characters -----------------------------------------------------------

  @override
  List<Character> charactersFor(String worldId) =>
      List.unmodifiable(_charactersByWorld[worldId] ?? const []);

  @override
  Character? characterById(String worldId, String characterId) {
    for (final c in _charactersByWorld[worldId] ?? const <Character>[]) {
      if (c.id == characterId) return c;
    }
    return null;
  }

  @override
  Future<Character> addCharacter({
    required String worldId,
    required String name,
    required String role,
    required String description,
  }) async {
    final character = Character(
      id: _nextId('char'),
      worldId: worldId,
      name: name.trim(),
      role: role.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    final list = _charactersByWorld.putIfAbsent(worldId, () => []);
    list.insert(0, character);
    notifyListeners();
    return character;
  }

  @override
  Future<void> updateCharacter(Character updated) async {
    final list = _charactersByWorld[updated.worldId];
    if (list == null) return;
    final i = list.indexWhere((c) => c.id == updated.id);
    if (i == -1) return;
    list[i] = updated;
    notifyListeners();
  }

  @override
  Future<void> deleteCharacter({
    required String worldId,
    required String characterId,
  }) async {
    final list = _charactersByWorld[worldId];
    if (list == null) return;
    list.removeWhere((c) => c.id == characterId);
    // Cascade: remove the dangling characterId from every location that
    // referenced this character, so links stay consistent.
    final locations = _locationsByWorld[worldId];
    if (locations != null) {
      for (var i = 0; i < locations.length; i++) {
        final location = locations[i];
        if (location.characterIds.contains(characterId)) {
          locations[i] = location.copyWith(
            characterIds: List<String>.from(location.characterIds)
              ..remove(characterId),
          );
        }
      }
    }
    notifyListeners();
  }

  // -- Locations ------------------------------------------------------------

  @override
  List<Location> locationsFor(String worldId) =>
      List.unmodifiable(_locationsByWorld[worldId] ?? const []);

  @override
  Location? locationById(String worldId, String locationId) {
    for (final location in _locationsByWorld[worldId] ?? const <Location>[]) {
      if (location.id == locationId) return location;
    }
    return null;
  }

  @override
  Future<Location> addLocation({
    required String worldId,
    required String name,
    required String type,
    required String description,
  }) async {
    final location = Location(
      id: _nextId('loc'),
      worldId: worldId,
      name: name.trim(),
      type: type.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    final list = _locationsByWorld.putIfAbsent(worldId, () => []);
    list.insert(0, location);
    notifyListeners();
    return location;
  }

  @override
  Future<void> updateLocation(Location updated) async {
    final list = _locationsByWorld[updated.worldId];
    if (list == null) return;
    final i = list.indexWhere((l) => l.id == updated.id);
    if (i == -1) return;
    list[i] = updated;
    notifyListeners();
  }

  @override
  Future<void> deleteLocation({
    required String worldId,
    required String locationId,
  }) async {
    final list = _locationsByWorld[worldId];
    if (list == null) return;
    list.removeWhere((l) => l.id == locationId);
    // Cascade: remove the dangling locationId from every character that
    // referenced this location.
    final characters = _charactersByWorld[worldId];
    if (characters != null) {
      for (var i = 0; i < characters.length; i++) {
        final character = characters[i];
        if (character.locationIds.contains(locationId)) {
          characters[i] = character.copyWith(
            locationIds: List<String>.from(character.locationIds)
              ..remove(locationId),
          );
        }
      }
    }
    notifyListeners();
  }

  // -- Relationships --------------------------------------------------------

  @override
  Future<void> linkCharacterAndLocation({
    required String worldId,
    required String characterId,
    required String locationId,
  }) async {
    final character = characterById(worldId, characterId);
    final location = locationById(worldId, locationId);
    if (character == null || location == null) return;

    final alreadyLinked =
        character.locationIds.contains(locationId) &&
        location.characterIds.contains(characterId);
    if (alreadyLinked) return;

    final characters = _charactersByWorld[worldId]!;
    final locations = _locationsByWorld[worldId]!;
    final ci = characters.indexWhere((c) => c.id == characterId);
    final li = locations.indexWhere((l) => l.id == locationId);

    characters[ci] = character.copyWith(
      locationIds: character.locationIds.contains(locationId)
          ? character.locationIds
          : [...character.locationIds, locationId],
    );
    locations[li] = location.copyWith(
      characterIds: location.characterIds.contains(characterId)
          ? location.characterIds
          : [...location.characterIds, characterId],
    );
    notifyListeners();
  }

  @override
  Future<void> unlinkCharacterAndLocation({
    required String worldId,
    required String characterId,
    required String locationId,
  }) async {
    final character = characterById(worldId, characterId);
    final location = locationById(worldId, locationId);
    if (character == null || location == null) return;

    final hadLink =
        character.locationIds.contains(locationId) ||
        location.characterIds.contains(characterId);
    if (!hadLink) return;

    final characters = _charactersByWorld[worldId]!;
    final locations = _locationsByWorld[worldId]!;
    final ci = characters.indexWhere((c) => c.id == characterId);
    final li = locations.indexWhere((l) => l.id == locationId);

    characters[ci] = character.copyWith(
      locationIds: List<String>.from(character.locationIds)..remove(locationId),
    );
    locations[li] = location.copyWith(
      characterIds: List<String>.from(location.characterIds)
        ..remove(characterId),
    );
    notifyListeners();
  }

  // -- Test helpers ---------------------------------------------------------

  /// Wipes all state and re-seeds the mock data. Only intended for tests;
  /// production code should never call this.
  @visibleForTesting
  void resetForTests() {
    _worlds.clear();
    _charactersByWorld.clear();
    _locationsByWorld.clear();
    _idSeq = 0;
    _isLoading = false;
    _errorMessage = null;
    _seedMockData();
    notifyListeners();
  }

  // -- Helpers --------------------------------------------------------------

  String _nextId(String prefix) {
    _idSeq += 1;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_idSeq';
  }

  void _seedMockData() {
    final aerenthal = World(
      id: _nextId('world'),
      name: 'Aerenthal',
      genre: 'High fantasy',
      description:
          'A fractured kingdom of ash and silver, where the old gods '
          'sleep beneath glass mountains and exiled heirs plot their return.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    );
    final neoHavana = World(
      id: _nextId('world'),
      name: 'Neo-Havana',
      genre: 'Cyberpunk',
      description:
          'A humid neon island where corporate spires spear the clouds '
          'and data-smugglers work the drowned quarters at low tide.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    _worlds
      ..add(aerenthal)
      ..add(neoHavana);

    _charactersByWorld[aerenthal.id] = [
      Character(
        id: _nextId('char'),
        worldId: aerenthal.id,
        name: 'Lady Veyra Morne',
        role: 'Exiled heir',
        description:
            'Last of the Morne bloodline, raised in the salt-mines of '
            'Karr. Carries the shard-crown in a reliquary she never opens.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Character(
        id: _nextId('char'),
        worldId: aerenthal.id,
        name: 'Ser Callen Hoarfrost',
        role: 'Oathbroken knight',
        description:
            'Once-captain of the Silver Watch. Refuses to speak of the '
            'Winter Vow he broke; his sword sings in the presence of lies.',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
    ];
    _charactersByWorld[neoHavana.id] = [
      Character(
        id: _nextId('char'),
        worldId: neoHavana.id,
        name: 'Marisol "Tide" Quesada',
        role: 'Data-smuggler',
        description:
            'Runs encrypted payloads through the drowned quarters on a '
            'hand-built hydrofoil. Missing three fingers, never her price.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    _locationsByWorld[aerenthal.id] = [];
    _locationsByWorld[neoHavana.id] = [];
  }
}
