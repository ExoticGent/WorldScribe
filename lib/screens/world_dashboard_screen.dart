import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/theme/app_colors.dart';
import '../models/character.dart';
import '../models/faction.dart';
import '../models/location.dart';
import '../models/world.dart';
import '../services/service_locator.dart';
import '../widgets/ai_forge_sheet.dart';
import '../widgets/app_search_field.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/dashboard_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

/// Hub for a single world. Shows a header summary and a grid of
/// worldbuilding sections. Entity sections open their list/detail flows,
/// while roadmap-only sections stay visible but disabled.
class WorldDashboardScreen extends StatefulWidget {
  const WorldDashboardScreen({super.key, required this.worldId});

  final String worldId;

  @override
  State<WorldDashboardScreen> createState() => _WorldDashboardScreenState();
}

class _WorldDashboardScreenState extends State<WorldDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  Future<void> _openAiForge(BuildContext context, World world) async {
    final character = await AiForgeSheet.show(context, world);
    if (character == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forged ${character.name} for ${world.name}.')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String worldName) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete $worldName?',
      message: AppStrings.deleteWorldPrompt,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await dataService.deleteWorld(widget.worldId);
      if (!context.mounted) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacementNamed(AppRoutes.home);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteWorldFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = dataService;

    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final world = data.worldById(widget.worldId);
        if (data.isLoading && world == null) {
          return const Scaffold(
            body: LoadingState(label: AppStrings.loadingWorld),
          );
        }
        if (world == null) {
          return Scaffold(
            appBar: AppBar(),
            body: data.errorMessage != null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: AppStrings.loadDataFailed,
                    hint: data.errorMessage!,
                  )
                : const Center(child: Text('World not found')),
          );
        }

        final characterCount = data.charactersFor(world.id).length;
        final locationCount = data.locationsFor(world.id).length;
        final factionCount = data.factionsFor(world.id).length;
        final searchResults = _query.isEmpty
            ? const <_DashboardSearchResult>[]
            : _searchResults(world.id);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(world.name),
                centerTitle: true,
                actions: [
                  PopupMenuButton<_WorldAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _WorldAction.edit:
                          Navigator.of(context).pushNamed(
                            AppRoutes.editWorld,
                            arguments: WorldRouteArgs(worldId: world.id),
                          );
                        case _WorldAction.delete:
                          _confirmDelete(context, world.name);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _WorldAction.edit,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.edit_outlined, size: 20),
                          title: Text(AppStrings.editWorldAction),
                        ),
                      ),
                      PopupMenuItem(
                        value: _WorldAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(
                            Icons.delete_outline,
                            color: AppColors.emberRed,
                            size: 20,
                          ),
                          title: Text(AppStrings.deleteWorldAction),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: _WorldHeader(
                    genre: world.genre,
                    description: world.description,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: AppSearchField(
                    controller: _searchController,
                    label: AppStrings.searchWorldEntitiesLabel,
                    hint: AppStrings.searchWorldEntitiesHint,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              if (_query.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                    delegate: SliverChildListDelegate.fixed([
                      DashboardTile(
                        icon: Icons.people_alt_outlined,
                        label: AppStrings.charactersSection,
                        count: characterCount,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.characters,
                          arguments: WorldRouteArgs(worldId: world.id),
                        ),
                      ),
                      DashboardTile(
                        icon: Icons.map_outlined,
                        label: AppStrings.locationsSection,
                        count: locationCount,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.locations,
                          arguments: WorldRouteArgs(worldId: world.id),
                        ),
                      ),
                      DashboardTile(
                        icon: Icons.shield_outlined,
                        label: AppStrings.factionsSection,
                        count: factionCount,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.factions,
                          arguments: WorldRouteArgs(worldId: world.id),
                        ),
                      ),
                      DashboardTile(
                        icon: Icons.menu_book_outlined,
                        label: AppStrings.loreSection,
                        onTap: null,
                        comingSoon: true,
                      ),
                      DashboardTile(
                        icon: Icons.auto_awesome_outlined,
                        label: AppStrings.aiForge,
                        onTap: () => _openAiForge(context, world),
                      ),
                    ]),
                  ),
                )
              else
                _SearchResultsSliver(
                  results: searchResults,
                  onTap: (result) => _openSearchResult(context, result),
                ),
            ],
          ),
        );
      },
    );
  }

  List<_DashboardSearchResult> _searchResults(String worldId) {
    final results = <_DashboardSearchResult>[];
    for (final character in dataService.charactersFor(worldId)) {
      if (_matchesCharacter(character)) {
        results.add(
          _DashboardSearchResult(
            id: character.id,
            title: character.name,
            subtitle: character.role,
            kind: _SearchResultKind.character,
          ),
        );
      }
    }
    for (final location in dataService.locationsFor(worldId)) {
      if (_matchesLocation(location)) {
        results.add(
          _DashboardSearchResult(
            id: location.id,
            title: location.name,
            subtitle: location.type,
            kind: _SearchResultKind.location,
          ),
        );
      }
    }
    for (final faction in dataService.factionsFor(worldId)) {
      if (_matchesFaction(faction)) {
        results.add(
          _DashboardSearchResult(
            id: faction.id,
            title: faction.name,
            subtitle: faction.ideology,
            kind: _SearchResultKind.faction,
          ),
        );
      }
    }
    return results;
  }

  bool _matchesCharacter(Character character) =>
      _matches([character.name, character.role, character.description]);

  bool _matchesLocation(Location location) =>
      _matches([location.name, location.type, location.description]);

  bool _matchesFaction(Faction faction) =>
      _matches([faction.name, faction.ideology, faction.description]);

  bool _matches(List<String> values) {
    final haystack = values.join(' ').toLowerCase();
    return haystack.contains(_query);
  }

  void _openSearchResult(BuildContext context, _DashboardSearchResult result) {
    switch (result.kind) {
      case _SearchResultKind.character:
        Navigator.of(context).pushNamed(
          AppRoutes.characterDetail,
          arguments: CharacterRouteArgs(
            worldId: widget.worldId,
            characterId: result.id,
          ),
        );
      case _SearchResultKind.location:
        Navigator.of(context).pushNamed(
          AppRoutes.locationDetail,
          arguments: LocationRouteArgs(
            worldId: widget.worldId,
            locationId: result.id,
          ),
        );
      case _SearchResultKind.faction:
        Navigator.of(context).pushNamed(
          AppRoutes.factionDetail,
          arguments: FactionRouteArgs(
            worldId: widget.worldId,
            factionId: result.id,
          ),
        );
    }
  }
}

enum _WorldAction { edit, delete }

enum _SearchResultKind { character, location, faction }

class _DashboardSearchResult {
  const _DashboardSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final _SearchResultKind kind;

  String get typeLabel {
    switch (kind) {
      case _SearchResultKind.character:
        return 'Character';
      case _SearchResultKind.location:
        return 'Location';
      case _SearchResultKind.faction:
        return 'Faction';
    }
  }

  IconData get icon {
    switch (kind) {
      case _SearchResultKind.character:
        return Icons.person_outline;
      case _SearchResultKind.location:
        return Icons.place_outlined;
      case _SearchResultKind.faction:
        return Icons.shield_outlined;
    }
  }
}

class _SearchResultsSliver extends StatelessWidget {
  const _SearchResultsSliver({required this.results, required this.onTap});

  final List<_DashboardSearchResult> results;
  final void Function(_DashboardSearchResult result) onTap;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 360,
          child: EmptyState(
            icon: Icons.search_off,
            title: AppStrings.worldEntitySearchEmpty,
            hint: AppStrings.worldEntitySearchEmptyHint,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      sliver: SliverList.separated(
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final result = results[i];
          return _SearchResultRow(result: result, onTap: () => onTap(result));
        },
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.result, required this.onTap});

  final _DashboardSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineSoft),
                ),
                child: Icon(result.icon, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        result.typeLabel,
                        if (result.subtitle.isNotEmpty) result.subtitle,
                      ].join(' - '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.parchmentDim,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.parchmentFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldHeader extends StatelessWidget {
  const _WorldHeader({required this.genre, required this.description});

  final String genre;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (genre.isNotEmpty)
            Text(
              genre.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.goldDeep,
                letterSpacing: 1.4,
              ),
            ),
          if (description.isNotEmpty) ...[
            if (genre.isNotEmpty) const SizedBox(height: 10),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.parchment,
                height: 1.5,
              ),
            ),
          ],
          if (genre.isEmpty && description.isEmpty)
            Text(
              'A world awaiting its first chronicler.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
