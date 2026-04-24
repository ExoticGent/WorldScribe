import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../services/service_locator.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/world_card.dart';

/// The list of every world the user has scribed. Entry point to the app
/// after the splash. Tapping a card opens its dashboard; the FAB opens
/// the create-world flow.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = dataService;
    final startupNotice = dataServiceNotice;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createWorld),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newWorld),
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final worlds = data.worlds;
          if (data.isLoading && worlds.isEmpty) {
            return const LoadingState(label: AppStrings.loadingWorlds);
          }
          if (data.errorMessage != null && worlds.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: AppStrings.loadDataFailed,
              hint: data.errorMessage!,
            );
          }
          if (worlds.isEmpty) {
            return Column(
              children: [
                if (startupNotice != null)
                  _StartupNotice(message: startupNotice),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: AppStrings.homeEmpty,
                    hint: AppStrings.homeEmptyHint,
                  ),
                ),
              ],
            );
          }

          final headerCount = startupNotice == null ? 0 : 1;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: worlds.length + headerCount,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (startupNotice != null && i == 0) {
                return _StartupNotice(message: startupNotice);
              }

              final world = worlds[i - headerCount];
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

class _StartupNotice extends StatelessWidget {
  const _StartupNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x16D9B382),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44D9B382)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFD9B382)),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
