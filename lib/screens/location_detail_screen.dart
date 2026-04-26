import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/theme/app_colors.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../widgets/add_location_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/entity_picker_sheet.dart';
import '../widgets/linked_entities_section.dart';
import '../widgets/loading_state.dart';

/// Detail view for a single location. Mirrors [CharacterDetailScreen]
/// but exposes both edit (via the existing add-location sheet in edit
/// mode) and delete (with confirmation dialog) on the overflow menu.
class LocationDetailScreen extends StatelessWidget {
  const LocationDetailScreen({
    super.key,
    required this.worldId,
    required this.locationId,
  });

  final String worldId;
  final String locationId;

  Future<void> _openEdit(BuildContext context, Location location) async {
    await AddLocationSheet.show(context, worldId, initial: location);
  }

  Future<void> _confirmDelete(BuildContext context, Location location) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${location.name}?',
      message: AppStrings.deleteLocationPrompt,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await dataService.deleteLocation(
        worldId: worldId,
        locationId: locationId,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteLocationFailed)),
      );
    }
  }

  Future<void> _openLinkPicker(
    BuildContext context, {
    required List<Character> available,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasCharactersInWorld =
        dataService.charactersFor(worldId).isNotEmpty;
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
      await dataService.linkCharacterAndLocation(
        worldId: worldId,
        characterId: picked,
        locationId: locationId,
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
        final location = data.locationById(worldId, locationId);
        if (data.isLoading && location == null) {
          return const Scaffold(
            body: LoadingState(label: AppStrings.loadingLocation),
          );
        }
        if (location == null) {
          return Scaffold(
            appBar: AppBar(),
            body: data.errorMessage != null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: AppStrings.loadDataFailed,
                    hint: data.errorMessage!,
                  )
                : const Center(child: Text('Location not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                title: Text(location.name),
                centerTitle: true,
                actions: [
                  PopupMenuButton<_MenuAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _MenuAction.edit:
                          _openEdit(context, location);
                        case _MenuAction.delete:
                          _confirmDelete(context, location);
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
                          title: Text(AppStrings.editLocationAction),
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
                          title: Text(AppStrings.deleteLocationAction),
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
                      if (location.type.isNotEmpty) ...[
                        const _SectionLabel(label: 'Type'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            location.type,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (location.description.isNotEmpty) ...[
                        const _SectionLabel(label: 'Description'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            location.description,
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
                            'No characters linked yet. Link one to place '
                            'them at this location.',
                        unlinkTooltip: AppStrings.unlinkCharacterTooltip,
                        defaultIcon: Icons.person_outline,
                        linked: _linkedCharacters(location),
                        onTap: (id) => Navigator.of(context).pushNamed(
                          AppRoutes.characterDetail,
                          arguments: CharacterRouteArgs(
                            worldId: worldId,
                            characterId: id,
                          ),
                        ),
                        onUnlink: (id) => _unlinkCharacter(context, id),
                        onAdd: () => _openLinkPicker(
                          context,
                          available: _availableCharacters(location),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(label: 'Scribed'),
                      const SizedBox(height: 6),
                      _Panel(
                        child: Text(
                          _formatDate(location.createdAt),
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

  /// Characters currently linked to this location, in dashboard order.
  /// Drops dangling ids defensively in case the cascade hasn't yet
  /// caught up.
  List<EntityPickOption> _linkedCharacters(Location location) {
    final ids = location.characterIds.toSet();
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

  /// Characters in the same world that aren't already linked — i.e. the
  /// valid choices for the picker sheet.
  List<Character> _availableCharacters(Location location) {
    final linked = location.characterIds.toSet();
    return [
      for (final c in dataService.charactersFor(worldId))
        if (!linked.contains(c.id)) c,
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
              Icons.place_outlined,
              color: AppColors.gold,
              size: 28,
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
