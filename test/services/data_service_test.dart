import 'package:flutter_test/flutter_test.dart';
import 'package:worldscribe/services/in_memory_data_service.dart';

void main() {
  late InMemoryDataService service;

  setUp(() async {
    service = InMemoryDataService.instance..resetForTests();
    await service.initialize();
  });

  test('seeds two worlds with characters', () {
    expect(service.worlds.length, 2);
    final first = service.worlds.first;
    expect(service.charactersFor(first.id), isNotEmpty);
  });

  test('addWorld prepends and returns the new world', () async {
    final before = service.worlds.length;
    final world = await service.addWorld(
      name: 'Testoria',
      genre: 'Fantasy',
      description: 'A demo world.',
    );

    expect(service.worlds.length, before + 1);
    expect(service.worlds.first.id, world.id);
    expect(service.worldById(world.id)?.name, 'Testoria');
  });

  test('addCharacter appends to the right world', () async {
    final world = service.worlds.first;
    final before = service.charactersFor(world.id).length;

    final character = await service.addCharacter(
      worldId: world.id,
      name: 'Witness',
      role: 'Herald',
      description: 'Speaks only in riddles.',
    );

    expect(service.charactersFor(world.id).length, before + 1);
    expect(service.characterById(world.id, character.id)?.name, 'Witness');
  });

  test('addLocation appends to the right world', () async {
    final world = service.worlds.first;
    final before = service.locationsFor(world.id).length;

    final location = await service.addLocation(
      worldId: world.id,
      name: 'Ashen Spire',
      type: 'Fortress',
      description: 'A watchtower fused into volcanic glass.',
    );

    expect(service.locationsFor(world.id).length, before + 1);
    expect(service.locationById(world.id, location.id)?.name, 'Ashen Spire');
  });

  test('updateWorld changes the stored fields', () async {
    final world = service.worlds.first;

    await service.updateWorld(
      world.copyWith(
        name: 'Aerenthal Reforged',
        genre: 'Epic fantasy',
        description: 'Now with a rewritten court and cleaner map.',
      ),
    );

    final updated = service.worldById(world.id);
    expect(updated?.name, 'Aerenthal Reforged');
    expect(updated?.genre, 'Epic fantasy');
    expect(updated?.description, 'Now with a rewritten court and cleaner map.');
  });

  test('updateCharacter changes the stored fields', () async {
    final world = service.worlds.first;
    final character = await service.addCharacter(
      worldId: world.id,
      name: 'Old Name',
      role: 'Old Role',
      description: 'A first draft.',
    );

    await service.updateCharacter(
      character.copyWith(
        name: 'New Name',
        role: 'New Role',
        description: 'Now with full backstory.',
      ),
    );

    final updated = service.characterById(world.id, character.id);
    expect(updated?.name, 'New Name');
    expect(updated?.role, 'New Role');
    expect(updated?.description, 'Now with full backstory.');
  });

  test('updateLocation changes the stored fields', () async {
    final world = service.worlds.first;
    final location = await service.addLocation(
      worldId: world.id,
      name: 'Old Name',
      type: 'Ruin',
      description: 'A first draft.',
    );

    await service.updateLocation(
      location.copyWith(
        name: 'New Name',
        type: 'Fortress',
        description: 'Now with finished walls.',
      ),
    );

    final updated = service.locationById(world.id, location.id);
    expect(updated?.name, 'New Name');
    expect(updated?.type, 'Fortress');
    expect(updated?.description, 'Now with finished walls.');
  });

  test('deleteLocation removes from the list', () async {
    final world = service.worlds.first;
    final location = await service.addLocation(
      worldId: world.id,
      name: 'Mayfly Outpost',
      type: 'Camp',
      description: '',
    );

    await service.deleteLocation(
      worldId: world.id,
      locationId: location.id,
    );

    expect(service.locationById(world.id, location.id), isNull);
  });

  test('deleteCharacter removes from the list', () async {
    final world = service.worlds.first;
    final character = await service.addCharacter(
      worldId: world.id,
      name: 'Mayfly',
      role: 'Extra',
      description: '',
    );

    await service.deleteCharacter(worldId: world.id, characterId: character.id);

    expect(service.characterById(world.id, character.id), isNull);
  });

  test('deleteWorld also clears its characters', () async {
    final world = await service.addWorld(
      name: 'Ephemera',
      genre: '',
      description: '',
    );
    await service.addCharacter(
      worldId: world.id,
      name: 'Ghost',
      role: 'Specter',
      description: '',
    );

    await service.deleteWorld(world.id);

    expect(service.worldById(world.id), isNull);
    expect(service.charactersFor(world.id), isEmpty);
  });

  test('notifies listeners on add', () async {
    var callCount = 0;
    void listener() => callCount += 1;

    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    await service.addWorld(name: 'Nova', genre: '', description: '');

    expect(callCount, greaterThanOrEqualTo(1));
  });

  group('factions', () {
    test('seeds factions for the seeded worlds', () {
      for (final world in service.worlds) {
        expect(service.factionsFor(world.id), isNotEmpty);
      }
    });

    test('addFaction prepends to the right world', () async {
      final world = service.worlds.first;
      final before = service.factionsFor(world.id).length;

      final faction = await service.addFaction(
        worldId: world.id,
        name: 'The Glass Court',
        ideology: 'Order through ritual.',
        description: 'A circle of seers who interpret the cracked sky.',
      );

      expect(service.factionsFor(world.id).length, before + 1);
      expect(service.factionsFor(world.id).first.id, faction.id);
      expect(service.factionById(world.id, faction.id)?.name, 'The Glass Court');
    });

    test('updateFaction changes the stored fields', () async {
      final world = service.worlds.first;
      final faction = await service.addFaction(
        worldId: world.id,
        name: 'Old Name',
        ideology: 'Old creed',
        description: 'A draft.',
      );

      await service.updateFaction(
        faction.copyWith(
          name: 'New Name',
          ideology: 'Refined creed',
          description: 'Now with full charter.',
        ),
      );

      final updated = service.factionById(world.id, faction.id);
      expect(updated?.name, 'New Name');
      expect(updated?.ideology, 'Refined creed');
      expect(updated?.description, 'Now with full charter.');
    });

    test('deleteFaction removes from the list', () async {
      final world = service.worlds.first;
      final faction = await service.addFaction(
        worldId: world.id,
        name: 'Mayfly Cabal',
        ideology: '',
        description: '',
      );

      await service.deleteFaction(worldId: world.id, factionId: faction.id);

      expect(service.factionById(world.id, faction.id), isNull);
    });

    test('deleteWorld also clears its factions', () async {
      final world = await service.addWorld(
        name: 'Ephemera',
        genre: '',
        description: '',
      );
      await service.addFaction(
        worldId: world.id,
        name: 'Phantoms',
        ideology: '',
        description: '',
      );

      await service.deleteWorld(world.id);

      expect(service.worldById(world.id), isNull);
      expect(service.factionsFor(world.id), isEmpty);
    });
  });

  group('relationships', () {
    test('linkCharacterAndLocation updates both sides', () async {
      final world = service.worlds.first;
      final character = await service.addCharacter(
        worldId: world.id,
        name: 'Veyra',
        role: 'Heir',
        description: '',
      );
      final location = await service.addLocation(
        worldId: world.id,
        name: 'Karr',
        type: 'Salt mine',
        description: '',
      );

      await service.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );

      expect(
        service.characterById(world.id, character.id)?.locationIds,
        contains(location.id),
      );
      expect(
        service.locationById(world.id, location.id)?.characterIds,
        contains(character.id),
      );
    });

    test('linking the same pair twice is a no-op', () async {
      final world = service.worlds.first;
      final character = await service.addCharacter(
        worldId: world.id,
        name: 'Veyra',
        role: 'Heir',
        description: '',
      );
      final location = await service.addLocation(
        worldId: world.id,
        name: 'Karr',
        type: 'Salt mine',
        description: '',
      );

      await service.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );
      await service.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );

      expect(
        service
            .characterById(world.id, character.id)
            ?.locationIds
            .where((id) => id == location.id)
            .length,
        1,
      );
      expect(
        service
            .locationById(world.id, location.id)
            ?.characterIds
            .where((id) => id == character.id)
            .length,
        1,
      );
    });

    test('unlinkCharacterAndLocation removes the link from both sides',
        () async {
      final world = service.worlds.first;
      final character = await service.addCharacter(
        worldId: world.id,
        name: 'Veyra',
        role: 'Heir',
        description: '',
      );
      final location = await service.addLocation(
        worldId: world.id,
        name: 'Karr',
        type: 'Salt mine',
        description: '',
      );

      await service.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );
      await service.unlinkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );

      expect(
        service.characterById(world.id, character.id)?.locationIds,
        isEmpty,
      );
      expect(
        service.locationById(world.id, location.id)?.characterIds,
        isEmpty,
      );
    });

    test('deleting a character cascades the link off its locations',
        () async {
      final world = service.worlds.first;
      final character = await service.addCharacter(
        worldId: world.id,
        name: 'Veyra',
        role: 'Heir',
        description: '',
      );
      final location = await service.addLocation(
        worldId: world.id,
        name: 'Karr',
        type: 'Salt mine',
        description: '',
      );
      await service.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );

      await service.deleteCharacter(
        worldId: world.id,
        characterId: character.id,
      );

      expect(
        service.locationById(world.id, location.id)?.characterIds,
        isEmpty,
      );
    });

    test('deleting a location cascades the link off its characters',
        () async {
      final world = service.worlds.first;
      final character = await service.addCharacter(
        worldId: world.id,
        name: 'Veyra',
        role: 'Heir',
        description: '',
      );
      final location = await service.addLocation(
        worldId: world.id,
        name: 'Karr',
        type: 'Salt mine',
        description: '',
      );
      await service.linkCharacterAndLocation(
        worldId: world.id,
        characterId: character.id,
        locationId: location.id,
      );

      await service.deleteLocation(
        worldId: world.id,
        locationId: location.id,
      );

      expect(
        service.characterById(world.id, character.id)?.locationIds,
        isEmpty,
      );
    });
  });
}
