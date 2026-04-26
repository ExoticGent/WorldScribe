import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'entity_picker_sheet.dart';

/// Detail-screen section that lists the entities linked to the current
/// page (e.g. "Linked locations" on a character detail screen) and gives
/// the user one-tap navigation, one-tap unlink, and an action button to
/// open an [EntityPickerSheet] and link a new one.
///
/// The widget is deliberately presentational: the parent owns the data
/// service calls and just passes already-prepared [EntityPickOption]s,
/// plus callbacks for tap / unlink / add. That keeps the widget reusable
/// across character_detail and location_detail screens (and later
/// factions / lore).
class LinkedEntitiesSection extends StatelessWidget {
  const LinkedEntitiesSection({
    super.key,
    required this.label,
    required this.linked,
    required this.onTap,
    required this.onUnlink,
    required this.onAdd,
    required this.addLabel,
    required this.emptyHint,
    required this.unlinkTooltip,
    this.defaultIcon = Icons.link,
  });

  final String label;
  final List<EntityPickOption> linked;
  final void Function(String id) onTap;
  final Future<void> Function(String id) onUnlink;
  final VoidCallback onAdd;
  final String addLabel;
  final String emptyHint;
  final String unlinkTooltip;
  final IconData defaultIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.goldDeep,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        if (linked.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: Text(
              emptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.parchmentDim,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < linked.length; i++) ...[
                _LinkedRow(
                  option: linked[i],
                  defaultIcon: defaultIcon,
                  unlinkTooltip: unlinkTooltip,
                  onTap: () => onTap(linked[i].id),
                  onUnlink: () => onUnlink(linked[i].id),
                ),
                if (i != linked.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_link, size: 18),
            label: Text(addLabel),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkedRow extends StatelessWidget {
  const _LinkedRow({
    required this.option,
    required this.defaultIcon,
    required this.unlinkTooltip,
    required this.onTap,
    required this.onUnlink,
  });

  final EntityPickOption option;
  final IconData defaultIcon;
  final String unlinkTooltip;
  final VoidCallback onTap;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineSoft),
                ),
                child: Icon(
                  option.icon ?? defaultIcon,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.subtitle != null &&
                        option.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.parchmentDim,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: unlinkTooltip,
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                icon: const Icon(
                  Icons.link_off,
                  color: AppColors.goldDeep,
                  size: 20,
                ),
                onPressed: onUnlink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
