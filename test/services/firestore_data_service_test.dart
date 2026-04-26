import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/services/firestore_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late FirestoreDataService service;

  const userId = 'test-user';

  CollectionReference<Map<String, dynamic>> worldsRef() =>
      firestore.collection('users').doc(userId).collection('worlds');

  Future<void> settleFirestore() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> seedWorld({
    required String id,
    required String name,
    required String genre,
    required String description,
    required DateTime createdAt,
  }) {
    return worldsRef().doc(id).set({
      'name': name,
      'genre': genre,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    });
  }

  Future<void> seedCharacter({
    required String worldId,
    required String characterId,
    required String name,
    required String role,
    required String description,
    required DateTime createdAt,
  }) {
    return worldsRef()
        .doc(worldId)
        .collection('characters')
        .doc(characterId)
        .set({
          'name': name,
          'role': role,
          'description': description,
          'createdAt': Timestamp.fromDate(createdAt),
        });
  }

  Future<void> seedLocation({
    required String worldId,
    required String locationId,
    required String name,
    required String type,
    required String description,
    required DateTime createdAt,
  }) {
    return worldsRef()
        .doc(worldId)
        .collection('locations')
        .doc(locationId)
        .set({
          'name': name,
          'type': type,
          'description': description,
          'createdAt': Timestamp.fromDate(createdAt),
        });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreDataService(firestore: firestore, userId: userId);
  });

  tearDown(() {
    service.dispose();
  });

  test(
    'initialize loads seeded worlds and characters in created order',
    () async {
      await seedWorld(
        id: 'world-older',
        name: 'Old Kingdom',
        genre: 'Epic fantasy',
        description: 'An older court with long winters.',
        createdAt: DateTime.utc(2025, 1, 1),
      );
      await seedWorld(
        id: 'world-newer',
        name: 'Glass Frontier',
        genre: 'Science fantasy',
        description: 'A newer world with drifting cities.',
        createdAt: DateTime.utc(2025, 2, 1),
      );
      await seedCharacter(
        worldId: 'world-newer',
        characterId: 'char-older',
        name: 'Mara',
        role: 'Scout',
        description: 'A patient cartographer.',
        createdAt: DateTime.utc(2025, 2, 2),
      );
      await seedCharacter(
        worldId: 'world-newer',
        characterId: 'char-newer',
        name: 'Tovin',
        role: 'Guide',
        description: 'Knows the routes between glass towers.',
        createdAt: DateTime.utc(2025, 2, 3),
      );
      await seedLocation(
        worldId: 'world-newer',
        locationId: 'loc-1',
        name: 'The Prism Causeway',
        type: 'Bridge district',
        description: 'A suspended route between drifting glass wards.',
        createdAt: DateTime.utc(2025, 2, 4),
      );

      await service.initialize();
      await settleFirestore();

      expect(service.isLoading, isFalse);
      expect(service.errorMessage, isNull);
      expect(service.worlds.map((world) => world.id), [
        'world-newer',
        'world-older',
      ]);
      expect(
        service.charactersFor('world-newer').map((character) => character.id),
        ['char-newer', 'char-older'],
      );
      expect(
        service.locationsFor('world-newer').map((location) => location.id),
        ['loc-1'],
      );
    },
  );

  test('live snapshots update the local cache for remote writes', () async {
    await service.initialize();

    await seedWorld(
      id: 'world-remote',
      name: 'Ash Vale',
      genre: 'Dark fantasy',
      description: 'A valley rewritten from another client.',
      createdAt: DateTime.utc(2025, 3, 1),
    );
    await settleFirestore();

    expect(service.worldById('world-remote')?.name, 'Ash Vale');

    await seedCharacter(
      worldId: 'world-remote',
      characterId: 'char-remote',
      name: 'Iria',
      role: 'Archivist',
      description: 'Keeps the forbidden indexes.',
      createdAt: DateTime.utc(2025, 3, 2),
    );
    await settleFirestore();

    expect(
      service.characterById('world-remote', 'char-remote')?.role,
      'Archivist',
    );

    await seedLocation(
      worldId: 'world-remote',
      locationId: 'loc-remote',
      name: 'The Ember Ferry',
      type: 'Harbor',
      description: 'The ferry terminal where the valley changes hands.',
      createdAt: DateTime.utc(2025, 3, 3),
    );
    await settleFirestore();

    expect(service.locationById('world-remote', 'loc-remote')?.type, 'Harbor');
  });

  test(
    'world CRUD persists to Firestore and deletes nested characters',
    () async {
      await service.initialize();

      final world = await service.addWorld(
        name: 'Stormreach',
        genre: 'High fantasy',
        description: 'A storm-lashed coastline of ruined observatories.',
      );
      await settleFirestore();

      expect(service.worldById(world.id)?.name, 'Stormreach');
      expect((await worldsRef().doc(world.id).get()).exists, isTrue);

      await service.updateWorld(
        world.copyWith(
          name: 'Stormreach Reforged',
          genre: 'Mythic fantasy',
          description: 'The same coast, now with rebuilt beacons.',
        ),
      );
      await settleFirestore();

      final updatedWorldDoc = await worldsRef().doc(world.id).get();
      expect(service.worldById(world.id)?.name, 'Stormreach Reforged');
      expect(updatedWorldDoc.data()?['genre'], 'Mythic fantasy');

      final character = await service.addCharacter(
        worldId: world.id,
        name: 'Seren',
        role: 'Keeper',
        description: 'Maintains the beacon fires.',
      );
      await settleFirestore();

      expect(
        (await worldsRef()
                .doc(world.id)
                .collection('characters')
                .doc(character.id)
                .get())
            .exists,
        isTrue,
      );

      await service.deleteWorld(world.id);
      await settleFirestore();

      expect(service.worldById(world.id), isNull);
      expect((await worldsRef().doc(world.id).get()).exists, isFalse);
      expect(
        (await worldsRef().doc(world.id).collection('characters').get()).docs,
        isEmpty,
      );
      expect(
        (await worldsRef().doc(world.id).collection('locations').get()).docs,
        isEmpty,
      );
    },
  );

  test('character CRUD persists to Firestore', () async {
    await seedWorld(
      id: 'world-1',
      name: 'Cinder Reach',
      genre: 'Fantasy',
      description: 'A borderland of ash and lanterns.',
      createdAt: DateTime.utc(2025, 4, 1),
    );

    await service.initialize();
    await settleFirestore();

    final character = await service.addCharacter(
      worldId: 'world-1',
      name: 'Lio',
      role: 'Messenger',
      description: 'Runs the ember roads at dusk.',
    );
    await settleFirestore();

    expect(service.characterById('world-1', character.id)?.name, 'Lio');

    await service.updateCharacter(
      character.copyWith(
        name: 'Lio Venn',
        role: 'Courier',
        description: 'Carries sealed letters between the watchfires.',
      ),
    );
    await settleFirestore();

    final updatedDoc = await worldsRef()
        .doc('world-1')
        .collection('characters')
        .doc(character.id)
        .get();
    expect(updatedDoc.data()?['name'], 'Lio Venn');
    expect(updatedDoc.data()?['role'], 'Courier');

    await service.deleteCharacter(
      worldId: 'world-1',
      characterId: character.id,
    );
    await settleFirestore();

    expect(service.characterById('world-1', character.id), isNull);
    expect(
      (await worldsRef()
              .doc('world-1')
              .collection('characters')
              .doc(character.id)
              .get())
          .exists,
      isFalse,
    );
  });

  test('location CRUD persists to Firestore', () async {
    await seedWorld(
      id: 'world-2',
      name: 'Rivercourt',
      genre: 'Fantasy',
      description: 'A floodplain of shrines and broken roads.',
      createdAt: DateTime.utc(2025, 4, 2),
    );

    await service.initialize();
    await settleFirestore();

    final location = await service.addLocation(
      worldId: 'world-2',
      name: 'Mirror Lock',
      type: 'Canal gate',
      description: 'A gatehouse that reflects moonlight into the river.',
    );
    await settleFirestore();

    expect(service.locationById('world-2', location.id)?.name, 'Mirror Lock');
    expect(
      (await worldsRef()
              .doc('world-2')
              .collection('locations')
              .doc(location.id)
              .get())
          .data()?['type'],
      'Canal gate',
    );

    await service.updateLocation(
      location.copyWith(
        name: 'Mirror Lock Reforged',
        type: 'Flood gate',
        description: 'The gate rebuilt after the summer floods.',
      ),
    );
    await settleFirestore();

    final updatedLocationDoc = await worldsRef()
        .doc('world-2')
        .collection('locations')
        .doc(location.id)
        .get();
    expect(
      service.locationById('world-2', location.id)?.name,
      'Mirror Lock Reforged',
    );
    expect(updatedLocationDoc.data()?['type'], 'Flood gate');

    await service.deleteLocation(
      worldId: 'world-2',
      locationId: location.id,
    );
    await settleFirestore();

    expect(service.locationById('world-2', location.id), isNull);
    expect(
      (await worldsRef()
              .doc('world-2')
              .collection('locations')
              .doc(location.id)
              .get())
          .exists,
      isFalse,
    );
  });

  group('relationships', () {
    Future<({String worldId, String characterId, String locationId})>
    seedLinkable() async {
      await seedWorld(
        id: 'world-rel',
        name: 'Karr Reach',
        genre: 'Fantasy',
        description: 'A salt-bitten coastline of exiled houses.',
        createdAt: DateTime.utc(2025, 5, 1),
      );
      await seedCharacter(
        worldId: 'world-rel',
        characterId: 'char-veyra',
        name: 'Veyra',
        role: 'Heir',
        description: 'Last of the Morne bloodline.',
        createdAt: DateTime.utc(2025, 5, 2),
      );
      await seedLocation(
        worldId: 'world-rel',
        locationId: 'loc-karr',
        name: 'Karr',
        type: 'Salt mine',
        description: 'Where the heir was raised.',
        createdAt: DateTime.utc(2025, 5, 3),
      );
      await service.initialize();
      await settleFirestore();
      return (
        worldId: 'world-rel',
        characterId: 'char-veyra',
        locationId: 'loc-karr',
      );
    }

    test('linkCharacterAndLocation writes both sides to Firestore', () async {
      final ids = await seedLinkable();

      await service.linkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      expect(
        service
            .characterById(ids.worldId, ids.characterId)
            ?.locationIds,
        contains(ids.locationId),
      );
      expect(
        service
            .locationById(ids.worldId, ids.locationId)
            ?.characterIds,
        contains(ids.characterId),
      );

      final characterDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('characters')
          .doc(ids.characterId)
          .get();
      final locationDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('locations')
          .doc(ids.locationId)
          .get();

      expect(
        (characterDoc.data()?['locationIds'] as List?)?.cast<String>(),
        contains(ids.locationId),
      );
      expect(
        (locationDoc.data()?['characterIds'] as List?)?.cast<String>(),
        contains(ids.characterId),
      );
    });

    test('linking the same pair twice keeps a single entry on each side',
        () async {
      final ids = await seedLinkable();

      await service.linkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();
      await service.linkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      expect(
        service
            .characterById(ids.worldId, ids.characterId)
            ?.locationIds
            .where((id) => id == ids.locationId)
            .length,
        1,
      );
      expect(
        service
            .locationById(ids.worldId, ids.locationId)
            ?.characterIds
            .where((id) => id == ids.characterId)
            .length,
        1,
      );

      final characterDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('characters')
          .doc(ids.characterId)
          .get();
      final locationDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('locations')
          .doc(ids.locationId)
          .get();
      expect(
        (characterDoc.data()?['locationIds'] as List?)
            ?.cast<String>()
            .where((id) => id == ids.locationId)
            .length,
        1,
      );
      expect(
        (locationDoc.data()?['characterIds'] as List?)
            ?.cast<String>()
            .where((id) => id == ids.characterId)
            .length,
        1,
      );
    });

    test('unlinkCharacterAndLocation clears both sides in Firestore', () async {
      final ids = await seedLinkable();

      await service.linkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();
      await service.unlinkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      expect(
        service
            .characterById(ids.worldId, ids.characterId)
            ?.locationIds,
        isEmpty,
      );
      expect(
        service
            .locationById(ids.worldId, ids.locationId)
            ?.characterIds,
        isEmpty,
      );

      final characterDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('characters')
          .doc(ids.characterId)
          .get();
      final locationDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('locations')
          .doc(ids.locationId)
          .get();
      expect(
        (characterDoc.data()?['locationIds'] as List?)?.cast<String>() ??
            const <String>[],
        isEmpty,
      );
      expect(
        (locationDoc.data()?['characterIds'] as List?)?.cast<String>() ??
            const <String>[],
        isEmpty,
      );
    });

    test('deleting a linked character clears the inverse on its locations',
        () async {
      final ids = await seedLinkable();
      await service.linkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      await service.deleteCharacter(
        worldId: ids.worldId,
        characterId: ids.characterId,
      );
      await settleFirestore();

      expect(
        service
            .locationById(ids.worldId, ids.locationId)
            ?.characterIds,
        isEmpty,
      );

      final locationDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('locations')
          .doc(ids.locationId)
          .get();
      expect(
        (locationDoc.data()?['characterIds'] as List?)?.cast<String>() ??
            const <String>[],
        isEmpty,
      );
      expect(
        (await worldsRef()
                .doc(ids.worldId)
                .collection('characters')
                .doc(ids.characterId)
                .get())
            .exists,
        isFalse,
      );
    });

    test('deleting a linked location clears the inverse on its characters',
        () async {
      final ids = await seedLinkable();
      await service.linkCharacterAndLocation(
        worldId: ids.worldId,
        characterId: ids.characterId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      await service.deleteLocation(
        worldId: ids.worldId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      expect(
        service
            .characterById(ids.worldId, ids.characterId)
            ?.locationIds,
        isEmpty,
      );

      final characterDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('characters')
          .doc(ids.characterId)
          .get();
      expect(
        (characterDoc.data()?['locationIds'] as List?)?.cast<String>() ??
            const <String>[],
        isEmpty,
      );
      expect(
        (await worldsRef()
                .doc(ids.worldId)
                .collection('locations')
                .doc(ids.locationId)
                .get())
            .exists,
        isFalse,
      );
    });
  });
}
