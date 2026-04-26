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

  Future<void> seedFaction({
    required String worldId,
    required String factionId,
    required String name,
    required String ideology,
    required String description,
    required DateTime createdAt,
  }) {
    return worldsRef().doc(worldId).collection('factions').doc(factionId).set({
      'name': name,
      'ideology': ideology,
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

      final faction = await service.addFaction(
        worldId: world.id,
        name: 'Beaconwatch',
        ideology: 'Light kept against the storm.',
        description: 'A volunteer order tending the rebuilt beacons.',
      );
      await settleFirestore();

      expect(
        (await worldsRef()
                .doc(world.id)
                .collection('factions')
                .doc(faction.id)
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
      expect(
        (await worldsRef().doc(world.id).collection('factions').get()).docs,
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

    await service.deleteLocation(worldId: 'world-2', locationId: location.id);
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

  test('initialize loads seeded factions in created order', () async {
    await seedWorld(
      id: 'world-fac',
      name: 'Glass Court',
      genre: 'Fantasy',
      description: 'A court of seers under a cracked sky.',
      createdAt: DateTime.utc(2025, 6, 1),
    );
    await seedFaction(
      worldId: 'world-fac',
      factionId: 'fac-older',
      name: 'The Old Reading',
      ideology: 'Doctrine carved in obsidian.',
      description: 'The original interpreters of the cracks.',
      createdAt: DateTime.utc(2025, 6, 2),
    );
    await seedFaction(
      worldId: 'world-fac',
      factionId: 'fac-newer',
      name: 'The New Reading',
      ideology: 'Living scripture, reread each dawn.',
      description: 'A reformist circle that broke from the Old Reading.',
      createdAt: DateTime.utc(2025, 6, 3),
    );

    await service.initialize();
    await settleFirestore();

    expect(service.factionsFor('world-fac').map((faction) => faction.id), [
      'fac-newer',
      'fac-older',
    ]);
    expect(
      service.factionById('world-fac', 'fac-newer')?.name,
      'The New Reading',
    );
  });

  test(
    'live snapshots update the local cache for remote faction writes',
    () async {
      await service.initialize();

      await seedWorld(
        id: 'world-fac-remote',
        name: 'Mire Marches',
        genre: 'Dark fantasy',
        description: 'Sunken halls below the river plain.',
        createdAt: DateTime.utc(2025, 6, 10),
      );
      await settleFirestore();

      await seedFaction(
        worldId: 'world-fac-remote',
        factionId: 'fac-remote',
        name: 'The Drowned Hand',
        ideology: 'Tribute to the river.',
        description: 'Smugglers and reed-walkers loyal to the flood.',
        createdAt: DateTime.utc(2025, 6, 11),
      );
      await settleFirestore();

      expect(
        service.factionById('world-fac-remote', 'fac-remote')?.name,
        'The Drowned Hand',
      );
      expect(
        service.factionById('world-fac-remote', 'fac-remote')?.ideology,
        'Tribute to the river.',
      );
    },
  );

  test('faction CRUD persists to Firestore', () async {
    await seedWorld(
      id: 'world-3',
      name: 'Ember Coast',
      genre: 'Fantasy',
      description: 'A coastline lit by drift-fire.',
      createdAt: DateTime.utc(2025, 7, 1),
    );

    await service.initialize();
    await settleFirestore();

    final faction = await service.addFaction(
      worldId: 'world-3',
      name: 'Lanternkeepers',
      ideology: 'Light at any cost.',
      description: 'Hereditary guardians of the coastal lanterns.',
    );
    await settleFirestore();

    expect(service.factionById('world-3', faction.id)?.name, 'Lanternkeepers');
    expect(
      (await worldsRef()
              .doc('world-3')
              .collection('factions')
              .doc(faction.id)
              .get())
          .data()?['ideology'],
      'Light at any cost.',
    );

    await service.updateFaction(
      faction.copyWith(
        name: 'Lanternkeepers Reformed',
        ideology: 'Light, but only by oath.',
        description: 'A reformed charter signed at the Glass Beacon.',
      ),
    );
    await settleFirestore();

    final updatedFactionDoc = await worldsRef()
        .doc('world-3')
        .collection('factions')
        .doc(faction.id)
        .get();
    expect(
      service.factionById('world-3', faction.id)?.name,
      'Lanternkeepers Reformed',
    );
    expect(updatedFactionDoc.data()?['ideology'], 'Light, but only by oath.');

    await service.deleteFaction(worldId: 'world-3', factionId: faction.id);
    await settleFirestore();

    expect(service.factionById('world-3', faction.id), isNull);
    expect(
      (await worldsRef()
              .doc('world-3')
              .collection('factions')
              .doc(faction.id)
              .get())
          .exists,
      isFalse,
    );
  });

  group('relationships', () {
    Future<
      ({
        String worldId,
        String characterId,
        String locationId,
        String factionId,
      })
    >
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
      await seedFaction(
        worldId: 'world-rel',
        factionId: 'fac-morne',
        name: 'House Morne',
        ideology: 'Restoration of the shard-crown.',
        description: 'An exiled house with a claim on the silver coast.',
        createdAt: DateTime.utc(2025, 5, 4),
      );
      await service.initialize();
      await settleFirestore();
      return (
        worldId: 'world-rel',
        characterId: 'char-veyra',
        locationId: 'loc-karr',
        factionId: 'fac-morne',
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
        service.characterById(ids.worldId, ids.characterId)?.locationIds,
        contains(ids.locationId),
      );
      expect(
        service.locationById(ids.worldId, ids.locationId)?.characterIds,
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

    test(
      'linking the same pair twice keeps a single entry on each side',
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
      },
    );

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
        service.characterById(ids.worldId, ids.characterId)?.locationIds,
        isEmpty,
      );
      expect(
        service.locationById(ids.worldId, ids.locationId)?.characterIds,
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

    test(
      'deleting a linked character clears the inverse on its locations',
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
          service.locationById(ids.worldId, ids.locationId)?.characterIds,
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
      },
    );

    test(
      'deleting a linked location clears the inverse on its characters',
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
          service.characterById(ids.worldId, ids.characterId)?.locationIds,
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
      },
    );

    test('linkCharacterAndFaction writes both sides to Firestore', () async {
      final ids = await seedLinkable();

      await service.linkCharacterAndFaction(
        worldId: ids.worldId,
        characterId: ids.characterId,
        factionId: ids.factionId,
      );
      await settleFirestore();

      expect(
        service.characterById(ids.worldId, ids.characterId)?.factionIds,
        contains(ids.factionId),
      );
      expect(
        service.factionById(ids.worldId, ids.factionId)?.characterIds,
        contains(ids.characterId),
      );

      final characterDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('characters')
          .doc(ids.characterId)
          .get();
      final factionDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('factions')
          .doc(ids.factionId)
          .get();

      expect(
        (characterDoc.data()?['factionIds'] as List?)?.cast<String>(),
        contains(ids.factionId),
      );
      expect(
        (factionDoc.data()?['characterIds'] as List?)?.cast<String>(),
        contains(ids.characterId),
      );
    });

    test('linkLocationAndFaction writes both sides to Firestore', () async {
      final ids = await seedLinkable();

      await service.linkLocationAndFaction(
        worldId: ids.worldId,
        locationId: ids.locationId,
        factionId: ids.factionId,
      );
      await settleFirestore();

      expect(
        service.locationById(ids.worldId, ids.locationId)?.factionIds,
        contains(ids.factionId),
      );
      expect(
        service.factionById(ids.worldId, ids.factionId)?.locationIds,
        contains(ids.locationId),
      );

      final locationDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('locations')
          .doc(ids.locationId)
          .get();
      final factionDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('factions')
          .doc(ids.factionId)
          .get();

      expect(
        (locationDoc.data()?['factionIds'] as List?)?.cast<String>(),
        contains(ids.factionId),
      );
      expect(
        (factionDoc.data()?['locationIds'] as List?)?.cast<String>(),
        contains(ids.locationId),
      );
    });

    test(
      'linking faction pairs twice keeps a single entry on each side',
      () async {
        final ids = await seedLinkable();

        await service.linkCharacterAndFaction(
          worldId: ids.worldId,
          characterId: ids.characterId,
          factionId: ids.factionId,
        );
        await settleFirestore();
        await service.linkCharacterAndFaction(
          worldId: ids.worldId,
          characterId: ids.characterId,
          factionId: ids.factionId,
        );
        await settleFirestore();
        await service.linkLocationAndFaction(
          worldId: ids.worldId,
          locationId: ids.locationId,
          factionId: ids.factionId,
        );
        await settleFirestore();
        await service.linkLocationAndFaction(
          worldId: ids.worldId,
          locationId: ids.locationId,
          factionId: ids.factionId,
        );
        await settleFirestore();

        expect(
          service
              .characterById(ids.worldId, ids.characterId)
              ?.factionIds
              .where((id) => id == ids.factionId)
              .length,
          1,
        );
        expect(
          service
              .locationById(ids.worldId, ids.locationId)
              ?.factionIds
              .where((id) => id == ids.factionId)
              .length,
          1,
        );
        expect(
          service
              .factionById(ids.worldId, ids.factionId)
              ?.characterIds
              .where((id) => id == ids.characterId)
              .length,
          1,
        );
        expect(
          service
              .factionById(ids.worldId, ids.factionId)
              ?.locationIds
              .where((id) => id == ids.locationId)
              .length,
          1,
        );
      },
    );

    test(
      'unlink faction relationships clears both sides in Firestore',
      () async {
        final ids = await seedLinkable();

        await service.linkCharacterAndFaction(
          worldId: ids.worldId,
          characterId: ids.characterId,
          factionId: ids.factionId,
        );
        await service.linkLocationAndFaction(
          worldId: ids.worldId,
          locationId: ids.locationId,
          factionId: ids.factionId,
        );
        await settleFirestore();
        await service.unlinkCharacterAndFaction(
          worldId: ids.worldId,
          characterId: ids.characterId,
          factionId: ids.factionId,
        );
        await service.unlinkLocationAndFaction(
          worldId: ids.worldId,
          locationId: ids.locationId,
          factionId: ids.factionId,
        );
        await settleFirestore();

        expect(
          service.characterById(ids.worldId, ids.characterId)?.factionIds,
          isEmpty,
        );
        expect(
          service.locationById(ids.worldId, ids.locationId)?.factionIds,
          isEmpty,
        );
        expect(
          service.factionById(ids.worldId, ids.factionId)?.characterIds,
          isEmpty,
        );
        expect(
          service.factionById(ids.worldId, ids.factionId)?.locationIds,
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
        final factionDoc = await worldsRef()
            .doc(ids.worldId)
            .collection('factions')
            .doc(ids.factionId)
            .get();
        expect(
          (characterDoc.data()?['factionIds'] as List?)?.cast<String>() ??
              const <String>[],
          isEmpty,
        );
        expect(
          (locationDoc.data()?['factionIds'] as List?)?.cast<String>() ??
              const <String>[],
          isEmpty,
        );
        expect(
          (factionDoc.data()?['characterIds'] as List?)?.cast<String>() ??
              const <String>[],
          isEmpty,
        );
        expect(
          (factionDoc.data()?['locationIds'] as List?)?.cast<String>() ??
              const <String>[],
          isEmpty,
        );
      },
    );

    test('deleting linked entities clears faction inverse arrays', () async {
      final ids = await seedLinkable();
      await service.linkCharacterAndFaction(
        worldId: ids.worldId,
        characterId: ids.characterId,
        factionId: ids.factionId,
      );
      await service.linkLocationAndFaction(
        worldId: ids.worldId,
        locationId: ids.locationId,
        factionId: ids.factionId,
      );
      await settleFirestore();

      await service.deleteCharacter(
        worldId: ids.worldId,
        characterId: ids.characterId,
      );
      await service.deleteLocation(
        worldId: ids.worldId,
        locationId: ids.locationId,
      );
      await settleFirestore();

      expect(
        service.factionById(ids.worldId, ids.factionId)?.characterIds,
        isEmpty,
      );
      expect(
        service.factionById(ids.worldId, ids.factionId)?.locationIds,
        isEmpty,
      );

      final factionDoc = await worldsRef()
          .doc(ids.worldId)
          .collection('factions')
          .doc(ids.factionId)
          .get();
      expect(
        (factionDoc.data()?['characterIds'] as List?)?.cast<String>() ??
            const <String>[],
        isEmpty,
      );
      expect(
        (factionDoc.data()?['locationIds'] as List?)?.cast<String>() ??
            const <String>[],
        isEmpty,
      );
    });

    test(
      'deleting a linked faction clears character and location refs',
      () async {
        final ids = await seedLinkable();
        await service.linkCharacterAndFaction(
          worldId: ids.worldId,
          characterId: ids.characterId,
          factionId: ids.factionId,
        );
        await service.linkLocationAndFaction(
          worldId: ids.worldId,
          locationId: ids.locationId,
          factionId: ids.factionId,
        );
        await settleFirestore();

        await service.deleteFaction(
          worldId: ids.worldId,
          factionId: ids.factionId,
        );
        await settleFirestore();

        expect(
          service.characterById(ids.worldId, ids.characterId)?.factionIds,
          isEmpty,
        );
        expect(
          service.locationById(ids.worldId, ids.locationId)?.factionIds,
          isEmpty,
        );
        expect(service.factionById(ids.worldId, ids.factionId), isNull);

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
          (characterDoc.data()?['factionIds'] as List?)?.cast<String>() ??
              const <String>[],
          isEmpty,
        );
        expect(
          (locationDoc.data()?['factionIds'] as List?)?.cast<String>() ??
              const <String>[],
          isEmpty,
        );
        expect(
          (await worldsRef()
                  .doc(ids.worldId)
                  .collection('factions')
                  .doc(ids.factionId)
                  .get())
              .exists,
          isFalse,
        );
      },
    );
  });
}
