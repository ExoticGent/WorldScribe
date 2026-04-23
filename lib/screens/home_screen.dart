import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../services/service_locator.dart';
import '../widgets/empty_state.dart';
import '../widgets/world_card.dart';

/// The list of every world the user has scribed. Entry point to the app
/// after the splash. Tapping a card opens its dashboard; the FAB opens
/// the create-world flow.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = dataService;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.createWorld),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newWorld),
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final worlds = data.worlds;
          if (worlds.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: AppStrings.homeEmpty,
              hint: AppStrings.homeEmptyHint,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: worlds.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final world = worlds[i];
              return WorldCard(
                world: world,
                characterCount: data.charactersFor(world.id).length,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.worldDashboard,
                  arguments: WorldRouteArgs(worldId: world.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
