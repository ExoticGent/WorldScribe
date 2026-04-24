import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../services/service_locator.dart';
import '../widgets/add_location_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/location_card.dart';

/// List of locations for a world. The FAB opens a modal sheet to add
/// a new place to the setting.
class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    final data = dataService;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.locationsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddLocationSheet.show(context, worldId),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(AppStrings.newLocation),
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final locations = data.locationsFor(worldId);
          if (data.isLoading && locations.isEmpty) {
            return const LoadingState(label: AppStrings.loadingLocations);
          }
          if (data.errorMessage != null && locations.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: AppStrings.loadDataFailed,
              hint: data.errorMessage!,
            );
          }
          if (locations.isEmpty) {
            return const EmptyState(
              icon: Icons.place_outlined,
              title: AppStrings.locationsEmpty,
              hint: AppStrings.locationsEmptyHint,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: locations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => LocationCard(location: locations[i]),
          );
        },
      ),
    );
  }
}
