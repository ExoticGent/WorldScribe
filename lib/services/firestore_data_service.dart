import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/character.dart';
import '../models/faction.dart';
import '../models/location.dart';
import '../models/world.dart';
import 'worldscribe_data_service.dart';

/// Firebase-backed implementation of [WorldscribeDataService].
///
/// Data is stored under `users/{userId}/worlds/{worldId}` with a
/// `characters` subcollection per world. The service maintains a local
/// cache fed by snapshot listeners so the rest of the app can keep using
/// synchronous getters while reads stay live.
class FirestoreDataService extends WorldscribeDataService {
  FirestoreDataService({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final String userId;

  final Map<String, List<Character>> _charactersByWorld = {};
  final Map<String, List<Location>> _locationsByWorld = {};
  final Map<String, List<Faction>> _factionsByWorld = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _characterSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _locationSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _factionSubs = {};

  List<World> _worlds = const [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _worldsSub;
  Future<void>? _initializeFuture;
  bool _isLoading = true;
  String? _errorMessage;

  CollectionReference<Map<String, dynamic>> get _worldsRef =>
      _firestore.collection('users').doc(userId).collection('worlds');

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  List<World> get worlds => List.unmodifiable(_worlds);

  @override
  World? worldById(String id) {
    for (final world in _worlds) {
      if (world.id == id) return world;
    }
    return null;
  }

  @override
  List<Character> charactersFor(String worldId) =>
      List.unmodifiable(_charactersByWorld[worldId] ?? const []);

  @override
  Character? characterById(String worldId, String characterId) {
    for (final character
        in _charactersByWorld[worldId] ?? const <Character>[]) {
      if (character.id == characterId) return character;
    }
    return null;
  }

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
  List<Faction> factionsFor(String worldId) =>
      List.unmodifiable(_factionsByWorld[worldId] ?? const []);

  @override
  Faction? factionById(String worldId, String factionId) {
    for (final faction in _factionsByWorld[worldId] ?? const <Faction>[]) {
      if (faction.id == factionId) return faction;
    }
    return null;
  }

  @override
  Future<void> initialize() => _initializeFuture ??= _initializeInternal();

  Future<void> _initializeInternal() {
    final completer = Completer<void>();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _worldsSub = _worldsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _worlds = snapshot.docs.map(_worldFromDoc).toList(growable: false);
            final worldIds = _worlds.map((world) => world.id).toSet();
            _syncCharacterSubscriptions(worldIds);
            _syncLocationSubscriptions(worldIds);
            _syncFactionSubscriptions(worldIds);
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Firestore worlds stream error: $error');
            debugPrintStack(stackTrace: stackTrace);
            _isLoading = false;
            _errorMessage = 'Could not load your worlds from Firebase.';
            notifyListeners();
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );

    return completer.future;
  }

  @override
  Future<World> addWorld({
    required String name,
    required String genre,
    required String description,
  }) async {
    final doc = _worldsRef.doc();
    final world = World(
      id: doc.id,
      name: name.trim(),
      genre: genre.trim(),
      description: description.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    _worlds = [world, ..._worlds];
    _charactersByWorld.putIfAbsent(world.id, () => []);
    _locationsByWorld.putIfAbsent(world.id, () => []);
    _factionsByWorld.putIfAbsent(world.id, () => []);
    _errorMessage = null;
    notifyListeners();

    try {
      await doc.set(_worldToFirestore(world));
      return world;
    } catch (_) {
      _worlds = _worlds
          .where((item) => item.id != world.id)
          .toList(growable: false);
      _charactersByWorld.remove(world.id);
      _locationsByWorld.remove(world.id);
      _factionsByWorld.remove(world.id);
      _errorMessage = 'Could not create the world in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> updateWorld(World updated) async {
    final index = _worlds.indexWhere((world) => world.id == updated.id);
    if (index == -1) return;

    final previous = _worlds[index];
    final nextWorlds = List<World>.from(_worlds);
    nextWorlds[index] = updated;
    _worlds = List.unmodifiable(nextWorlds);
    _errorMessage = null;
    notifyListeners();

    try {
      await _worldsRef
          .doc(updated.id)
          .set(_worldToFirestore(updated), SetOptions(merge: true));
    } catch (_) {
      final rollback = List<World>.from(_worlds);
      rollback[index] = previous;
      _worlds = List.unmodifiable(rollback);
      _errorMessage = 'Could not update the world in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> deleteWorld(String id) async {
    final index = _worlds.indexWhere((world) => world.id == id);
    if (index == -1) return;

    final removedWorld = _worlds[index];
    final removedCharacters = _charactersByWorld[id];
    final removedLocations = _locationsByWorld[id];
    final removedFactions = _factionsByWorld[id];
    final removedSubscription = _characterSubs.remove(id);
    final removedLocationSubscription = _locationSubs.remove(id);
    final removedFactionSubscription = _factionSubs.remove(id);

    final nextWorlds = List<World>.from(_worlds)..removeAt(index);
    _worlds = List.unmodifiable(nextWorlds);
    _charactersByWorld.remove(id);
    _locationsByWorld.remove(id);
    _factionsByWorld.remove(id);
    _errorMessage = null;
    removedSubscription?.cancel();
    removedLocationSubscription?.cancel();
    removedFactionSubscription?.cancel();
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final worldRef = _worldsRef.doc(id);
      final charactersSnapshot = await worldRef.collection('characters').get();
      final locationsSnapshot = await worldRef.collection('locations').get();
      final factionsSnapshot = await worldRef.collection('factions').get();

      for (final doc in charactersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in locationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in factionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(worldRef);
      await batch.commit();
    } catch (_) {
      final rollback = List<World>.from(_worlds);
      rollback.insert(index, removedWorld);
      _worlds = List.unmodifiable(rollback);
      if (removedCharacters != null) {
        _charactersByWorld[id] = removedCharacters;
      }
      if (removedLocations != null) {
        _locationsByWorld[id] = removedLocations;
      }
      if (removedFactions != null) {
        _factionsByWorld[id] = removedFactions;
      }
      if (worldById(id) != null) {
        _characterSubs[id] = _subscribeToCharacters(id);
        _locationSubs[id] = _subscribeToLocations(id);
        _factionSubs[id] = _subscribeToFactions(id);
      }
      _errorMessage = 'Could not delete the world from Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<Character> addCharacter({
    required String worldId,
    required String name,
    required String role,
    required String description,
  }) async {
    final doc = _worldsRef.doc(worldId).collection('characters').doc();
    final character = Character(
      id: doc.id,
      worldId: worldId,
      name: name.trim(),
      role: role.trim(),
      description: description.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    final previous = _charactersByWorld[worldId] ?? const <Character>[];
    _charactersByWorld[worldId] = [character, ...previous];
    _errorMessage = null;
    notifyListeners();

    try {
      await doc.set(_characterToFirestore(character));
      return character;
    } catch (_) {
      _charactersByWorld[worldId] = previous;
      _errorMessage = 'Could not save the character in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> updateCharacter(Character updated) async {
    final characters = _charactersByWorld[updated.worldId];
    if (characters == null) return;
    final index = characters.indexWhere(
      (character) => character.id == updated.id,
    );
    if (index == -1) return;

    final previous = characters[index];
    final nextCharacters = List<Character>.from(characters);
    nextCharacters[index] = updated;
    _charactersByWorld[updated.worldId] = nextCharacters;
    _errorMessage = null;
    notifyListeners();

    try {
      await _worldsRef
          .doc(updated.worldId)
          .collection('characters')
          .doc(updated.id)
          .set(_characterToFirestore(updated), SetOptions(merge: true));
    } catch (_) {
      final rollback = List<Character>.from(
        _charactersByWorld[updated.worldId] ?? const <Character>[],
      );
      rollback[index] = previous;
      _charactersByWorld[updated.worldId] = rollback;
      _errorMessage = 'Could not update the character in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> deleteCharacter({
    required String worldId,
    required String characterId,
  }) async {
    final characters = _charactersByWorld[worldId];
    if (characters == null) return;
    final index = characters.indexWhere(
      (character) => character.id == characterId,
    );
    if (index == -1) return;

    final removed = characters[index];
    final affectedLocations = <int, Location>{};
    final locations = _locationsByWorld[worldId];
    if (locations != null) {
      for (var i = 0; i < locations.length; i++) {
        if (locations[i].characterIds.contains(characterId)) {
          affectedLocations[i] = locations[i];
        }
      }
    }

    final nextCharacters = List<Character>.from(characters)..removeAt(index);
    _charactersByWorld[worldId] = nextCharacters;
    if (locations != null && affectedLocations.isNotEmpty) {
      final nextLocations = List<Location>.from(locations);
      for (final entry in affectedLocations.entries) {
        nextLocations[entry.key] = entry.value.copyWith(
          characterIds: List<String>.from(entry.value.characterIds)
            ..remove(characterId),
        );
      }
      _locationsByWorld[worldId] = nextLocations;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      batch.delete(
        _worldsRef.doc(worldId).collection('characters').doc(characterId),
      );
      // Drop the dangling characterId from each linked location.
      for (final entry in affectedLocations.entries) {
        batch.set(
          _worldsRef
              .doc(worldId)
              .collection('locations')
              .doc(entry.value.id),
          {
            'characterIds': FieldValue.arrayRemove([characterId]),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (_) {
      final rollback = List<Character>.from(
        _charactersByWorld[worldId] ?? const <Character>[],
      );
      rollback.insert(index, removed);
      _charactersByWorld[worldId] = rollback;
      if (locations != null && affectedLocations.isNotEmpty) {
        _locationsByWorld[worldId] = locations;
      }
      _errorMessage = 'Could not delete the character from Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<Location> addLocation({
    required String worldId,
    required String name,
    required String type,
    required String description,
  }) async {
    final doc = _worldsRef.doc(worldId).collection('locations').doc();
    final location = Location(
      id: doc.id,
      worldId: worldId,
      name: name.trim(),
      type: type.trim(),
      description: description.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    final previous = _locationsByWorld[worldId] ?? const <Location>[];
    _locationsByWorld[worldId] = [location, ...previous];
    _errorMessage = null;
    notifyListeners();

    try {
      await doc.set(_locationToFirestore(location));
      return location;
    } catch (_) {
      _locationsByWorld[worldId] = previous;
      _errorMessage = 'Could not save the location in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> updateLocation(Location updated) async {
    final locations = _locationsByWorld[updated.worldId];
    if (locations == null) return;
    final index = locations.indexWhere(
      (location) => location.id == updated.id,
    );
    if (index == -1) return;

    final previous = locations[index];
    final nextLocations = List<Location>.from(locations);
    nextLocations[index] = updated;
    _locationsByWorld[updated.worldId] = nextLocations;
    _errorMessage = null;
    notifyListeners();

    try {
      await _worldsRef
          .doc(updated.worldId)
          .collection('locations')
          .doc(updated.id)
          .set(_locationToFirestore(updated), SetOptions(merge: true));
    } catch (_) {
      final rollback = List<Location>.from(
        _locationsByWorld[updated.worldId] ?? const <Location>[],
      );
      rollback[index] = previous;
      _locationsByWorld[updated.worldId] = rollback;
      _errorMessage = 'Could not update the location in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> deleteLocation({
    required String worldId,
    required String locationId,
  }) async {
    final locations = _locationsByWorld[worldId];
    if (locations == null) return;
    final index = locations.indexWhere(
      (location) => location.id == locationId,
    );
    if (index == -1) return;

    final removed = locations[index];
    final affectedCharacters = <int, Character>{};
    final characters = _charactersByWorld[worldId];
    if (characters != null) {
      for (var i = 0; i < characters.length; i++) {
        if (characters[i].locationIds.contains(locationId)) {
          affectedCharacters[i] = characters[i];
        }
      }
    }

    final nextLocations = List<Location>.from(locations)..removeAt(index);
    _locationsByWorld[worldId] = nextLocations;
    if (characters != null && affectedCharacters.isNotEmpty) {
      final nextCharacters = List<Character>.from(characters);
      for (final entry in affectedCharacters.entries) {
        nextCharacters[entry.key] = entry.value.copyWith(
          locationIds: List<String>.from(entry.value.locationIds)
            ..remove(locationId),
        );
      }
      _charactersByWorld[worldId] = nextCharacters;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      batch.delete(
        _worldsRef.doc(worldId).collection('locations').doc(locationId),
      );
      for (final entry in affectedCharacters.entries) {
        batch.set(
          _worldsRef
              .doc(worldId)
              .collection('characters')
              .doc(entry.value.id),
          {
            'locationIds': FieldValue.arrayRemove([locationId]),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (_) {
      final rollback = List<Location>.from(
        _locationsByWorld[worldId] ?? const <Location>[],
      );
      rollback.insert(index, removed);
      _locationsByWorld[worldId] = rollback;
      if (characters != null && affectedCharacters.isNotEmpty) {
        _charactersByWorld[worldId] = characters;
      }
      _errorMessage = 'Could not delete the location from Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<Faction> addFaction({
    required String worldId,
    required String name,
    required String ideology,
    required String description,
  }) async {
    final doc = _worldsRef.doc(worldId).collection('factions').doc();
    final faction = Faction(
      id: doc.id,
      worldId: worldId,
      name: name.trim(),
      ideology: ideology.trim(),
      description: description.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    final previous = _factionsByWorld[worldId] ?? const <Faction>[];
    _factionsByWorld[worldId] = [faction, ...previous];
    _errorMessage = null;
    notifyListeners();

    try {
      await doc.set(_factionToFirestore(faction));
      return faction;
    } catch (_) {
      _factionsByWorld[worldId] = previous;
      _errorMessage = 'Could not save the faction in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> updateFaction(Faction updated) async {
    final factions = _factionsByWorld[updated.worldId];
    if (factions == null) return;
    final index = factions.indexWhere((faction) => faction.id == updated.id);
    if (index == -1) return;

    final previous = factions[index];
    final nextFactions = List<Faction>.from(factions);
    nextFactions[index] = updated;
    _factionsByWorld[updated.worldId] = nextFactions;
    _errorMessage = null;
    notifyListeners();

    try {
      await _worldsRef
          .doc(updated.worldId)
          .collection('factions')
          .doc(updated.id)
          .set(_factionToFirestore(updated), SetOptions(merge: true));
    } catch (_) {
      final rollback = List<Faction>.from(
        _factionsByWorld[updated.worldId] ?? const <Faction>[],
      );
      rollback[index] = previous;
      _factionsByWorld[updated.worldId] = rollback;
      _errorMessage = 'Could not update the faction in Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> deleteFaction({
    required String worldId,
    required String factionId,
  }) async {
    final factions = _factionsByWorld[worldId];
    if (factions == null) return;
    final index = factions.indexWhere((faction) => faction.id == factionId);
    if (index == -1) return;

    final removed = factions[index];
    final nextFactions = List<Faction>.from(factions)..removeAt(index);
    _factionsByWorld[worldId] = nextFactions;
    _errorMessage = null;
    notifyListeners();

    try {
      await _worldsRef
          .doc(worldId)
          .collection('factions')
          .doc(factionId)
          .delete();
    } catch (_) {
      final rollback = List<Faction>.from(
        _factionsByWorld[worldId] ?? const <Faction>[],
      );
      rollback.insert(index, removed);
      _factionsByWorld[worldId] = rollback;
      _errorMessage = 'Could not delete the faction from Firebase.';
      notifyListeners();
      rethrow;
    }
  }

  // -- Relationships --------------------------------------------------------

  @override
  Future<void> linkCharacterAndLocation({
    required String worldId,
    required String characterId,
    required String locationId,
  }) {
    return _writeLink(
      worldId: worldId,
      characterId: characterId,
      locationId: locationId,
      add: true,
    );
  }

  @override
  Future<void> unlinkCharacterAndLocation({
    required String worldId,
    required String characterId,
    required String locationId,
  }) {
    return _writeLink(
      worldId: worldId,
      characterId: characterId,
      locationId: locationId,
      add: false,
    );
  }

  /// Single code path for [linkCharacterAndLocation] and
  /// [unlinkCharacterAndLocation] — flips both ends of the relationship,
  /// optimistically updates the local cache, batches the Firestore
  /// writes, and rolls back on failure. [add] true links, false unlinks.
  Future<void> _writeLink({
    required String worldId,
    required String characterId,
    required String locationId,
    required bool add,
  }) async {
    final characters = _charactersByWorld[worldId];
    final locations = _locationsByWorld[worldId];
    if (characters == null || locations == null) return;

    final ci = characters.indexWhere((c) => c.id == characterId);
    final li = locations.indexWhere((l) => l.id == locationId);
    if (ci == -1 || li == -1) return;

    final character = characters[ci];
    final location = locations[li];
    final hasLink =
        character.locationIds.contains(locationId) &&
        location.characterIds.contains(characterId);
    if (add && hasLink) return;
    if (!add &&
        !character.locationIds.contains(locationId) &&
        !location.characterIds.contains(characterId)) {
      return;
    }

    final nextCharacterLocationIds = add
        ? (character.locationIds.contains(locationId)
              ? character.locationIds
              : [...character.locationIds, locationId])
        : (List<String>.from(character.locationIds)..remove(locationId));
    final nextLocationCharacterIds = add
        ? (location.characterIds.contains(characterId)
              ? location.characterIds
              : [...location.characterIds, characterId])
        : (List<String>.from(location.characterIds)..remove(characterId));

    final nextCharacters = List<Character>.from(characters);
    nextCharacters[ci] = character.copyWith(
      locationIds: nextCharacterLocationIds,
    );
    final nextLocations = List<Location>.from(locations);
    nextLocations[li] = location.copyWith(
      characterIds: nextLocationCharacterIds,
    );
    _charactersByWorld[worldId] = nextCharacters;
    _locationsByWorld[worldId] = nextLocations;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final characterRef = _worldsRef
          .doc(worldId)
          .collection('characters')
          .doc(characterId);
      final locationRef = _worldsRef
          .doc(worldId)
          .collection('locations')
          .doc(locationId);
      batch.set(characterRef, {
        'locationIds': add
            ? FieldValue.arrayUnion([locationId])
            : FieldValue.arrayRemove([locationId]),
      }, SetOptions(merge: true));
      batch.set(locationRef, {
        'characterIds': add
            ? FieldValue.arrayUnion([characterId])
            : FieldValue.arrayRemove([characterId]),
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {
      _charactersByWorld[worldId] = characters;
      _locationsByWorld[worldId] = locations;
      _errorMessage = add
          ? 'Could not link the character and location.'
          : 'Could not unlink the character and location.';
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _worldsSub?.cancel();
    for (final sub in _characterSubs.values) {
      sub.cancel();
    }
    _characterSubs.clear();
    for (final sub in _locationSubs.values) {
      sub.cancel();
    }
    _locationSubs.clear();
    for (final sub in _factionSubs.values) {
      sub.cancel();
    }
    _factionSubs.clear();
    super.dispose();
  }

  void _syncCharacterSubscriptions(Set<String> worldIds) {
    final activeWorldIds = _characterSubs.keys.toSet();

    for (final removedWorldId in activeWorldIds.difference(worldIds)) {
      _characterSubs.remove(removedWorldId)?.cancel();
      _charactersByWorld.remove(removedWorldId);
    }

    for (final worldId in worldIds.difference(activeWorldIds)) {
      _charactersByWorld.putIfAbsent(worldId, () => []);
      _characterSubs[worldId] = _subscribeToCharacters(worldId);
    }
  }

  void _syncLocationSubscriptions(Set<String> worldIds) {
    final activeWorldIds = _locationSubs.keys.toSet();

    for (final removedWorldId in activeWorldIds.difference(worldIds)) {
      _locationSubs.remove(removedWorldId)?.cancel();
      _locationsByWorld.remove(removedWorldId);
    }

    for (final worldId in worldIds.difference(activeWorldIds)) {
      _locationsByWorld.putIfAbsent(worldId, () => []);
      _locationSubs[worldId] = _subscribeToLocations(worldId);
    }
  }

  void _syncFactionSubscriptions(Set<String> worldIds) {
    final activeWorldIds = _factionSubs.keys.toSet();

    for (final removedWorldId in activeWorldIds.difference(worldIds)) {
      _factionSubs.remove(removedWorldId)?.cancel();
      _factionsByWorld.remove(removedWorldId);
    }

    for (final worldId in worldIds.difference(activeWorldIds)) {
      _factionsByWorld.putIfAbsent(worldId, () => []);
      _factionSubs[worldId] = _subscribeToFactions(worldId);
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
  _subscribeToCharacters(String worldId) {
    return _worldsRef
        .doc(worldId)
        .collection('characters')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _charactersByWorld[worldId] = snapshot.docs
                .map((doc) => _characterFromDoc(doc, worldId))
                .toList(growable: false);
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Firestore characters stream error: $error');
            debugPrintStack(stackTrace: stackTrace);
            _errorMessage = 'Could not load some characters from Firebase.';
            notifyListeners();
          },
        );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _subscribeToLocations(
    String worldId,
  ) {
    return _worldsRef
        .doc(worldId)
        .collection('locations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _locationsByWorld[worldId] = snapshot.docs
                .map((doc) => _locationFromDoc(doc, worldId))
                .toList(growable: false);
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Firestore locations stream error: $error');
            debugPrintStack(stackTrace: stackTrace);
            _errorMessage = 'Could not load some locations from Firebase.';
            notifyListeners();
          },
        );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _subscribeToFactions(
    String worldId,
  ) {
    return _worldsRef
        .doc(worldId)
        .collection('factions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _factionsByWorld[worldId] = snapshot.docs
                .map((doc) => _factionFromDoc(doc, worldId))
                .toList(growable: false);
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Firestore factions stream error: $error');
            debugPrintStack(stackTrace: stackTrace);
            _errorMessage = 'Could not load some factions from Firebase.';
            notifyListeners();
          },
        );
  }

  World _worldFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return World(
      id: doc.id,
      name: data['name'] as String? ?? '',
      genre: data['genre'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }

  Character _characterFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String worldId,
  ) {
    final data = doc.data();
    return Character(
      id: doc.id,
      worldId: worldId,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      locationIds:
          (data['locationIds'] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  Location _locationFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String worldId,
  ) {
    final data = doc.data();
    return Location(
      id: doc.id,
      worldId: worldId,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      characterIds:
          (data['characterIds'] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  Faction _factionFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String worldId,
  ) {
    final data = doc.data();
    return Faction(
      id: doc.id,
      worldId: worldId,
      name: data['name'] as String? ?? '',
      ideology: data['ideology'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }

  Map<String, dynamic> _worldToFirestore(World world) => {
    'name': world.name,
    'genre': world.genre,
    'description': world.description,
    'createdAt': Timestamp.fromDate(world.createdAt),
  };

  Map<String, dynamic> _characterToFirestore(Character character) => {
    'name': character.name,
    'role': character.role,
    'description': character.description,
    'createdAt': Timestamp.fromDate(character.createdAt),
    'locationIds': character.locationIds,
  };

  Map<String, dynamic> _locationToFirestore(Location location) => {
    'name': location.name,
    'type': location.type,
    'description': location.description,
    'createdAt': Timestamp.fromDate(location.createdAt),
    'characterIds': location.characterIds,
  };

  Map<String, dynamic> _factionToFirestore(Faction faction) => {
    'name': faction.name,
    'ideology': faction.ideology,
    'description': faction.description,
    'createdAt': Timestamp.fromDate(faction.createdAt),
  };

  DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
