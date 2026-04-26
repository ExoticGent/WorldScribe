import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/theme/app_colors.dart';
import '../models/character.dart';
import '../models/faction.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../widgets/add_faction_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/entity_picker_sheet.dart';
import '../widgets/linked_entities_section.dart';
import '../widgets/loading_state.dart';

/// Detail view for a single faction, including its linked characters and
/// locations.
class FactionDetailScreen extends StatelessWidget {
  const FactionDetailScreen({
    super.key,
    required this.worldId,
    required this.factionId,
  });

  final String worldId;
  final String factionId;

  Future<void> _openEdit(BuildContext context, Faction faction) async {
    await AddFactionSheet.show(context, worldId, initial: faction);
  }

  Future<void> _confirmDelete(BuildContext context, Faction faction) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${faction.name}?',
      message: AppStrings.deleteFactionPrompt,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await dataService.deleteFaction(worldId: worldId, factionId: factionId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteFactionFailed)),
      );
    }
  }

  Future<void> _openCharacterPicker(
    BuildContext context, {
    required List<Character> available,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasCharactersInWorld = dataService.charactersFor(worldId).isNotEmpty;
    final picked = await EntityPickerSheet.show(
      context,
      title: AppStrings.linkCharacterTitle,
      emptyHint: hasCharactersInWorld
          ? AppStrings.noCharactersToLink
          : AppStrings.noCharactersYet,
      emptyIcon: Icons.person_outline,
      defaultIcon: Icons.person_outline,
      options: available
          .map(
            (c) => EntityPickOption(
              id: c.id,
              title: c.name,
              subtitle: c.role,
              icon: Icons.person_outline,
            ),
          )
          .toList(growable: false),
    );
    if (picked == null) return;

    try {
      await dataService.linkCharacterAndFaction(
        worldId: worldId,
        characterId: picked,
        factionId: factionId,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.linkFailed)),
      );
    }
  }

  Future<void> _openLocationPicker(
    BuildContext context, {
    required List<Location> available,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasLocationsInWorld = dataService.locationsFor(worldId).isNotEmpty;
    final picked = await EntityPickerSheet.show(
      context,
      title: AppStrings.linkLocationTitle,
      emptyHint: hasLocationsInWorld
          ? AppStrings.noLocationsToLink
          : AppStrings.noLocationsYet,
      emptyIcon: Icons.place_outlined,
      defaultIcon: Icons.place_outlined,
      options: available
          .map(
            (loc) => EntityPickOption(
              id: loc.id,
              title: loc.name,
              subtitle: loc.type,
              icon: Icons.place_outlined,
            ),
          )
          .toList(growable: false),
    );
    if (picked == null) return;

    try {
      await dataService.linkLocationAndFaction(
        worldId: worldId,
        locationId: picked,
        factionId: factionId,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.linkFailed)),
      );
    }
  }

  Future<void> _unlinkCharacter(
    BuildContext context,
    String characterId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await dataService.unlinkCharacterAndFaction(
        worldId: worldId,
        characterId: characterId,
        factionId: factionId,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.unlinkFailed)),
      );
    }
  }

  Future<void> _unlinkLocation(BuildContext context, String locationId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await dataService.unlinkLocationAndFaction(
        worldId: worldId,
        locationId: locationId,
        factionId: factionId,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.unlinkFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = dataService;

    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final faction = data.factionById(worldId, factionId);
        if (data.isLoading && faction == null) {
          return const Scaffold(
            body: LoadingState(label: AppStrings.loadingFaction),
          );
        }
        if (faction == null) {
          return Scaffold(
            appBar: AppBar(),
            body: data.errorMessage != null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: AppStrings.loadDataFailed,
                    hint: data.errorMessage!,
                  )
                : const Center(child: Text('Faction not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                title: Text(faction.name),
                centerTitle: true,
                actions: [
                  PopupMenuButton<_MenuAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _MenuAction.edit:
                          _openEdit(context, faction);
                        case _MenuAction.delete:
                          _confirmDelete(context, faction);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _MenuAction.edit,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.edit_outlined, size: 20),
                          title: Text(AppStrings.editFactionAction),
                        ),
                      ),
                      PopupMenuItem(
                        value: _MenuAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(
                            Icons.delete_outline,
                            color: AppColors.emberRed,
                            size: 20,
                          ),
                          title: Text(AppStrings.deleteFactionAction),
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: const FlexibleSpaceBar(
                  background: _DetailHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (faction.ideology.isNotEmpty) ...[
                        const _SectionLabel(label: 'Ideology'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            faction.ideology,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (faction.description.isNotEmpty) ...[
                        const _SectionLabel(label: 'Description'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            faction.description,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.55),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      LinkedEntitiesSection(
                        label: AppStrings.linkedCharactersLabel,
                        addLabel: AppStrings.linkCharacterAction,
                        emptyHint:
                            'No characters linked yet. Link one to mark '
                            'membership, allegiance, rivalry, or influence.',
                        unlinkTooltip: AppStrings.unlinkCharacterTooltip,
                        defaultIcon: Icons.person_outline,
                        linked: _linkedCharacters(faction),
                        onTap: (id) => Navigator.of(context).pushNamed(
                          AppRoutes.characterDetail,
                          arguments: CharacterRouteArgs(
                            worldId: worldId,
                            characterId: id,
                          ),
                        ),
                        onUnlink: (id) => _unlinkCharacter(context, id),
                        onAdd: () => _openCharacterPicker(
                          context,
                          available: _availableCharacters(faction),
                        ),
                      ),
                      const SizedBox(height: 18),
                      LinkedEntitiesSection(
                        label: AppStrings.linkedLocationsLabel,
                        addLabel: AppStrings.linkLocationAction,
                        emptyHint:
                            'No locations linked yet. Link one to mark '
                            'territory, headquarters, influence, or history.',
                        unlinkTooltip: AppStrings.unlinkLocationTooltip,
                        defaultIcon: Icons.place_outlined,
                        linked: _linkedLocations(faction),
                        onTap: (id) => Navigator.of(context).pushNamed(
                          AppRoutes.locationDetail,
                          arguments: LocationRouteArgs(
                            worldId: worldId,
                            locationId: id,
                          ),
                        ),
                        onUnlink: (id) => _unlinkLocation(context, id),
                        onAdd: () => _openLocationPicker(
                          context,
                          available: _availableLocations(faction),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(label: 'Scribed'),
                      const SizedBox(height: 6),
                      _Panel(
                        child: Text(
                          _formatDate(faction.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<EntityPickOption> _linkedCharacters(Faction faction) {
    final ids = faction.characterIds.toSet();
    if (ids.isEmpty) return const [];
    return [
      for (final c in dataService.charactersFor(worldId))
        if (ids.contains(c.id))
          EntityPickOption(
            id: c.id,
            title: c.name,
            subtitle: c.role,
            icon: Icons.person_outline,
          ),
    ];
  }

  List<Character> _availableCharacters(Faction faction) {
    final linked = faction.characterIds.toSet();
    return [
      for (final c in dataService.charactersFor(worldId))
        if (!linked.contains(c.id)) c,
    ];
  }

  List<EntityPickOption> _linkedLocations(Faction faction) {
    final ids = faction.locationIds.toSet();
    if (ids.isEmpty) return const [];
    return [
      for (final loc in dataService.locationsFor(worldId))
        if (ids.contains(loc.id))
          EntityPickOption(
            id: loc.id,
            title: loc.name,
            subtitle: loc.type,
            icon: Icons.place_outlined,
          ),
    ];
  }

  List<Location> _availableLocations(Faction faction) {
    final linked = faction.locationIds.toSet();
    return [
      for (final loc in dataService.locationsFor(worldId))
        if (!linked.contains(loc.id)) loc,
    ];
  }
}

enum _MenuAction { edit, delete }

class _DetailHeader extends StatelessWidget {
  const _DetailHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.midnight, AppColors.ink],
        ),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldDeep, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.gold,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.goldDeep,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: child,
    );
  }
}
