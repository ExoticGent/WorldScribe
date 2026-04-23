import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Square-ish tile used on the World Dashboard to gateway into each
/// worldbuilding section. Disabled tiles show a "coming soon" overlay
/// but remain visible so the user has a sense of what's ahead.
class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = !comingSoon && onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: comingSoon ? AppColors.midnight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: comingSoon ? AppColors.outlineSoft : AppColors.outline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.midnight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outlineSoft),
                      ),
                      child: Icon(
                        icon,
                        color: comingSoon
                            ? AppColors.parchmentFaint
                            : AppColors.gold,
                        size: 20,
                      ),
                    ),
                    if (count != null)
                      Text(
                        '$count',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: comingSoon
                        ? AppColors.parchmentDim
                        : AppColors.parchment,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (comingSoon) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Coming soon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.parchmentFaint,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
