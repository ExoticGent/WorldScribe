import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../services/service_locator.dart';

/// Bottom sheet used on the Characters screen to add a new character.
/// A dedicated sheet (rather than a full screen) keeps the MVP screen
/// count tight and lets creation feel inline.
class AddCharacterSheet extends StatefulWidget {
  const AddCharacterSheet({super.key, required this.worldId});

  final String worldId;

  /// Helper to show the sheet. Returns the created character's id
  /// (or null if the user dismissed without saving).
  static Future<String?> show(BuildContext context, String worldId) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.midnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AddCharacterSheet(worldId: worldId),
    );
  }

  @override
  State<AddCharacterSheet> createState() => _AddCharacterSheetState();
}

class _AddCharacterSheetState extends State<AddCharacterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final character = dataService.addCharacter(
      worldId: widget.worldId,
      name: _nameController.text,
      role: _roleController.text,
      description: _descriptionController.text,
    );
    Navigator.of(context).pop(character.id);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Text(
                  AppStrings.newCharacter,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: AppStrings.characterNameLabel,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.characterRoleLabel,
                    hintText: AppStrings.characterRoleHint,
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: AppStrings.characterDescriptionLabel,
                    hintText: AppStrings.characterDescriptionHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text(AppStrings.saveCharacter),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
