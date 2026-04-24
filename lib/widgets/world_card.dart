import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/world.dart';

/// Card used on the Home screen to summarise a [World].
class WorldCard extends StatelessWidget {
  const WorldCard({
    super.key,
    required this.world,
    required this.characterCount,
    required this.onTap,
  });

  final World world;
  final int characterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public, color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        world.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.parchmentFaint,
                    ),
                  ],
                ),
                if (world.genre.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    world.genre,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.goldDeep,
                    ),
                  ),
                ],
                if (world.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    world.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Pill(
                      icon: Icons.person_outline,
                      label: _charactersLabel(characterCount),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _charactersLabel(int count) {
    if (count == 0) return 'No characters';
    if (count == 1) return '1 character';
    return '$count characters';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.midnight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.parchmentDim),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.parchmentDim,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
