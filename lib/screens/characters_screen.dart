import 'package:flutter/material.dart';

/// Placeholder characters-list screen.
class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Characters · $worldId')),
    );
  }
}
