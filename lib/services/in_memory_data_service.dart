import 'package:flutter/foundation.dart';

import '../models/character.dart';
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

  int _idSeq = 0;

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
  World addWorld({
    required String name,
    required String genre,
    required String description,
  }) {
    final world = World(
      id: _nextId('world'),
      name: name.trim(),
      genre: genre.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _worlds.insert(0, world);
    _charactersByWorld[world.id] = [];
    notifyListeners();
    return world;
  }

  @override
  void updateWorld(World updated) {
    final i = _worlds.indexWhere((w) => w.id == updated.id);
    if (i == -1) return;
    _worlds[i] = updated;
    notifyListeners();
  }

  @override
  void deleteWorld(String id) {
    _worlds.removeWhere((w) => w.id == id);
    _charactersByWorld.remove(id);
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
  Character addCharacter({
    required String worldId,
    required String name,
    required String role,
    required String description,
  }) {
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
  void updateCharacter(Character updated) {
    final list = _charactersByWorld[updated.worldId];
    if (list == null) return;
    final i = list.indexWhere((c) => c.id == updated.id);
    if (i == -1) return;
    list[i] = updated;
    notifyListeners();
  }

  @override
  void deleteCharacter({
    required String worldId,
    required String characterId,
  }) {
    final list = _charactersByWorld[worldId];
    if (list == null) return;
    list.removeWhere((c) => c.id == characterId);
    notifyListeners();
  }

  // -- Test helpers ---------------------------------------------------------

  /// Wipes all state and re-seeds the mock data. Only intended for tests;
  /// production code should never call this.
  @visibleForTesting
  void resetForTests() {
    _worlds.clear();
    _charactersByWorld.clear();
    _idSeq = 0;
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
  }
}
