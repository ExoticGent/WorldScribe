import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Modal yes/no confirmation prompt used everywhere we need the user
/// to acknowledge a destructive (or otherwise irreversible) action
/// before we go ahead and run it.
///
/// Returns `true` if the user picked the confirm action, `false` if
/// they cancelled, and `false` if they dismissed the dialog by
/// tapping the scrim (we treat dismissal as cancel).
class ConfirmDialog {
  ConfirmDialog._();

  /// Shows the confirmation dialog. [confirmLabel] is the text on the
  /// confirm button (e.g. "Delete", "Discard"); [cancelLabel] defaults
  /// to "Cancel". When [isDestructive] is true the confirm button is
  /// painted in [AppColors.emberRed] to signal the action can't be
  /// undone.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.emberRed)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
