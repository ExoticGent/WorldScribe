import 'package:flutter/material.dart';

/// Placeholder world-dashboard screen. The worldId will be passed via
/// route arguments once the navigation flow is wired up.
class WorldDashboardScreen extends StatelessWidget {
  const WorldDashboardScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('World Dashboard · $worldId')),
    );
  }
}
