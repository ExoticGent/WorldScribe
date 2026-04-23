import 'package:flutter/material.dart';

/// Placeholder character-detail screen.
class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  final String worldId;
  final String characterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Character · $worldId / $characterId')),
    );
  }
}
