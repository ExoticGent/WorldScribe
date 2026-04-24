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
