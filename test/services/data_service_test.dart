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
}
