import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../services/data_service.dart';
import '../widgets/add_character_sheet.dart';
import '../widgets/character_card.dart';
import '../widgets/empty_state.dart';

/// List of characters for a world. Tapping a card opens the detail
/// screen; the FAB opens a modal sheet to add a new character.
class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    final data = DataService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.charactersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddCharacterSheet.show(context, worldId),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(AppStrings.newCharacter),
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final characters = data.charactersFor(worldId);
          if (characters.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: AppStrings.charactersEmpty,
              hint: AppStrings.charactersEmptyHint,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: characters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final character = characters[i];
              return CharacterCard(
                character: character,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.characterDetail,
                  arguments: CharacterRouteArgs(
                    worldId: worldId,
                    characterId: character.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
