import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../services/service_locator.dart';
import '../widgets/add_faction_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/faction_card.dart';
import '../widgets/loading_state.dart';

/// List of factions for a world. The FAB opens a modal sheet to add a
/// new organized power to the setting.
class FactionsScreen extends StatelessWidget {
  const FactionsScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    final data = dataService;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.factionsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddFactionSheet.show(context, worldId),
        icon: const Icon(Icons.add_moderator_outlined),
        label: const Text(AppStrings.newFaction),
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final factions = data.factionsFor(worldId);
          if (data.isLoading && factions.isEmpty) {
            return const LoadingState(label: AppStrings.loadingFactions);
          }
          if (data.errorMessage != null && factions.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: AppStrings.loadDataFailed,
              hint: data.errorMessage!,
            );
          }
          if (factions.isEmpty) {
            return const EmptyState(
              icon: Icons.shield_outlined,
              title: AppStrings.factionsEmpty,
              hint: AppStrings.factionsEmptyHint,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: factions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final faction = factions[i];
              return FactionCard(
                faction: faction,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.factionDetail,
                  arguments: FactionRouteArgs(
                    worldId: worldId,
                    factionId: faction.id,
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
