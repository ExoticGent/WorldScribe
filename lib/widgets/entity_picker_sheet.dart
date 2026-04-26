import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/empty_state.dart';

/// One row of choices in [EntityPickerSheet]. Designed to be agnostic of
/// the underlying entity type so the same sheet can pick a location, a
/// character, a faction, or a lore note without inventing a new widget.
class EntityPickOption {
  const EntityPickOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
}

/// Modal bottom sheet that asks the user to pick one entity from a
/// pre-filtered list. Returns the chosen [EntityPickOption.id] (or
/// `null` if the user dismissed the sheet without picking).
///
/// The caller is responsible for filtering [options] (for example,
/// excluding entities that are already linked) so the sheet only shows
/// valid choices. When [options] is empty the sheet shows [emptyHint]
/// inside an [EmptyState] panel and waits for the user to dismiss it.
class EntityPickerSheet extends StatelessWidget {
  const EntityPickerSheet({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.emptyIcon,
    required this.options,
    this.defaultIcon = Icons.link,
  });

  final String title;
  final String emptyHint;
  final IconData emptyIcon;
  final List<EntityPickOption> options;
  final IconData defaultIcon;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String emptyHint,
    required IconData emptyIcon,
    required List<EntityPickOption> options,
    IconData defaultIcon = Icons.link,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.midnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => EntityPickerSheet(
        title: title,
        emptyHint: emptyHint,
        emptyIcon: emptyIcon,
        options: options,
        defaultIcon: defaultIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: EmptyState(
                          icon: emptyIcon,
                          title: 'Nothing to link',
                          hint: emptyHint,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: options.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final option = options[i];
                          return _PickerRow(
                            option: option,
                            defaultIcon: defaultIcon,
                            onTap: () =>
                                Navigator.of(context).pop(option.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.option,
    required this.defaultIcon,
    required this.onTap,
  });

  final EntityPickOption option;
  final IconData defaultIcon;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              const SizedBox(width: 8),
              const Icon(
                Icons.add_link,
                color: AppColors.goldDeep,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
