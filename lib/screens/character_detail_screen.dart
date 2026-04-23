import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/character.dart';
import '../services/data_service.dart';

/// Read-only detail view for a single character. Supports deletion via
/// the overflow menu (with a confirmation dialog); full edit flow lands
/// in a later milestone.
class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  final String worldId;
  final String characterId;

  Future<void> _confirmDelete(
    BuildContext context,
    Character character,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${character.name}?'),
        content: const Text(
          'This character will be removed from the world. '
          'This cannot be undone.',
        ),
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

    if (confirmed == true) {
      DataService.instance.deleteCharacter(
        worldId: worldId,
        characterId: characterId,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = DataService.instance;

    return Scaffold(
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final character = data.characterById(worldId, characterId);
          if (character == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Character not found')),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                title: Text(character.name),
                centerTitle: true,
                actions: [
                  PopupMenuButton<_MenuAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _MenuAction.delete:
                          _confirmDelete(context, character);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _MenuAction.delete,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AppColors.emberRed,
                            ),
                            SizedBox(width: 10),
                            Text('Delete character'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _DetailHeader(character: character),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (character.role.isNotEmpty) ...[
                        _SectionLabel(label: 'Role'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            character.role,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (character.description.isNotEmpty) ...[
                        _SectionLabel(label: 'Description'),
                        const SizedBox(height: 6),
                        _Panel(
                          child: Text(
                            character.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.55),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      _SectionLabel(label: 'Scribed'),
                      const SizedBox(height: 6),
                      _Panel(
                        child: Text(
                          _formatDate(character.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

enum _MenuAction { delete }

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.midnight, AppColors.ink],
        ),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldDeep, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(character.name),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.goldDeep,
            letterSpacing: 1.5,
          ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: child,
    );
  }
}
