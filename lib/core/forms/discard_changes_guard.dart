import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../../widgets/confirm_dialog.dart';

/// Helper that shows the standard "Discard changes?" prompt.
///
/// Returns `true` if the user confirmed they want to discard, `false` if
/// they chose to keep editing. Centralized here so every form route asks
/// the same question with the same wording (and the destructive button
/// painted in [emberRed] via [ConfirmDialog]).
Future<bool> confirmDiscardChanges(BuildContext context) {
  return ConfirmDialog.show(
    context,
    title: AppStrings.discardChangesTitle,
    message: AppStrings.discardChangesMessage,
    confirmLabel: AppStrings.discardChangesConfirm,
    cancelLabel: AppStrings.keepEditing,
    isDestructive: true,
  );
}
