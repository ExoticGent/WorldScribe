import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/theme/app_colors.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../widgets/add_character_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/entity_picker_sheet.dart';
import '../widgets/linked_entities_section.dart';
import '../widgets/loading_state.dart';

/// Detail view for a single character. Mirrors [LocationDetailScreen]:
/// the overflow menu offers Edit (via the existing add-character sheet
/// in edit mode) and Delete (with a confirmation dialog).
class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  final String worldId;
  final String characterId;

  Future<void> _openEdit(BuildContext context, Character character) async {
    await AddCharacterSheet.show(context, worldId, initial: character);
  }

  Future<void> _confirmDelete(BuildContext context, Character character) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${character.name}?',
      message: AppStrings.deleteCharacterPrompt,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await dataService.deleteCharacter(
        worldId: worldId,
        characterId: characterId,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteCharacterFailed)),
      );
    }
  }

  Future<void> _openLinkPicker(
    BuildContext context, {
    required List<Location> available,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasLocationsInWorld =
        dataService.locationsFor(worldId).isNotEmpty;
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
      await dataService.linkCharacterAndLocation(
        worldId: worldId,
        characterId: characterId,
        locationId: picked,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.linkFailed)),
      );
    }
  }

  Future<void> _unlinkLocation(
    BuildContext context,
    String locationId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await dataService.unlinkCharacterAndLocation(
        worldId: worldId,
        characterId: characterId,
        locationId: locationId,
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
        final character = data.characterById(worldId, characterId);
        if (data.isLoading && character == null) {
          return const Scaffold(
            body: LoadingState(label: AppStrings.loadingCharacter),
          );
        }
        if (character == null) {
          return Scaffold(
            appBar: AppBar(),
            body: data.errorMessage != null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: AppStrings.loadDataFailed,
                    hint: data.errorMessage!,
                  )
                : const Center(child: Text('Character not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                title: Text(character.name),
                centerTitle: true,
                actions: [
                  PopupMenuButton<_MenuAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _MenuAction.edit:
                          _openEdit(context, character);
                        case _MenuAction.delete:
                          _confirmDelete(context, character);
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
                          title: Text(AppStrings.editCharacterAction),
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
                          title: Text(AppStrings.deleteCharacterAction),
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _DetailHeader(character: character),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (character.role.isNotEmpty) ...[
                        const _SectionLabel(label: 'Role'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            character.role,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (character.description.isNotEmpty) ...[
                        const _SectionLabel(label: 'Description'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            character.description,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.55),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      LinkedEntitiesSection(
                        label: AppStrings.linkedLocationsLabel,
                        addLabel: AppStrings.linkLocationAction,
                        emptyHint:
                            'No locations linked yet. Link one to anchor '
                            'this character on the map.',
                        unlinkTooltip: AppStrings.unlinkLocationTooltip,
                        defaultIcon: Icons.place_outlined,
                        linked: _linkedLocations(character),
                        onTap: (id) => Navigator.of(context).pushNamed(
                          AppRoutes.locationDetail,
                          arguments: LocationRouteArgs(
                            worldId: worldId,
                            locationId: id,
                          ),
                        ),
                        onUnlink: (id) => _unlinkLocation(context, id),
                        onAdd: () => _openLinkPicker(
                          context,
                          available: _availableLocations(character),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(label: 'Scribed'),
                      const SizedBox(height: 6),
                      _Panel(
                        child: Text(
                          _formatDate(character.createdAt),
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

  /// Locations the character is currently linked to, in their dashboard
  /// order (so the section reads top-down the same way the locations
  /// list does). Drops dangling ids defensively in case the cascade
  /// hasn't yet caught up.
  List<EntityPickOption> _linkedLocations(Character character) {
    final ids = character.locationIds.toSet();
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

  /// Locations in the same world that aren't already linked — i.e. the
  /// valid choices for the picker sheet.
  List<Location> _availableLocations(Character character) {
    final linked = character.locationIds.toSet();
    return [
      for (final loc in dataService.locationsFor(worldId))
        if (!linked.contains(loc.id)) loc,
    ];
  }
}

enum _MenuAction { edit, delete }

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.character});

  final Character character;

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
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldDeep, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(character.name),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
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
