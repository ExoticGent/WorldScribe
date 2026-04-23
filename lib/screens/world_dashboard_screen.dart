import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/theme/app_colors.dart';
import '../services/service_locator.dart';
import '../widgets/dashboard_tile.dart';

/// Hub for a single world. Shows a header summary and a grid of
/// worldbuilding sections. Only Characters is interactive in the MVP;
/// the rest are visible-but-disabled so the roadmap is legible.
class WorldDashboardScreen extends StatelessWidget {
  const WorldDashboardScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    final data = dataService;

    return Scaffold(
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final world = data.worldById(worldId);
          if (world == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('World not found')),
            );
          }

          final characterCount = data.charactersFor(world.id).length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(world.name),
                centerTitle: true,
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
