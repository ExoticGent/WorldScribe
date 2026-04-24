import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/theme/app_colors.dart';
import '../services/service_locator.dart';
import '../widgets/dashboard_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

/// Hub for a single world. Shows a header summary and a grid of
/// worldbuilding sections. Only Characters is interactive in the MVP;
/// the rest are visible-but-disabled so the roadmap is legible.
class WorldDashboardScreen extends StatelessWidget {
  const WorldDashboardScreen({super.key, required this.worldId});

  final String worldId;

  Future<void> _confirmDelete(BuildContext context, String worldName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete $worldName?'),
        content: const Text(AppStrings.deleteWorldPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.emberRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await dataService.deleteWorld(worldId);
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

    return Scaffold(
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final world = data.worldById(worldId);
          if (data.isLoading && world == null) {
            return const LoadingState(label: AppStrings.loadingWorld);
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

          return CustomScrollView(
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      onTap: null,
                      comingSoon: true,
                    ),
                    DashboardTile(
                      icon: Icons.shield_outlined,
                      label: AppStrings.factionsSection,
                      onTap: null,
                      comingSoon: true,
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
                      onTap: null,
                      comingSoon: true,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _WorldAction { edit, delete }

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
