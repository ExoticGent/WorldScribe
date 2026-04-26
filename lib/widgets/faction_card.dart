import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/faction.dart';

/// Row-style card for a faction in the factions list.
class FactionCard extends StatelessWidget {
  const FactionCard({super.key, required this.faction, this.onTap});

  final Faction faction;
  final VoidCallback? onTap;

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Sigil(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faction.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (faction.ideology.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          faction.ideology,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.goldDeep,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (faction.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          faction.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.parchmentFaint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sigil extends StatelessWidget {
  const _Sigil();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.midnight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldDeep),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.shield_outlined, color: AppColors.gold),
    );
  }
}
