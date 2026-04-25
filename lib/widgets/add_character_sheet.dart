import 'package:flutter/material.dart';

import '../core/constants/app_input.dart';
import '../core/constants/app_strings.dart';
import '../core/forms/form_validators.dart';
import '../core/theme/app_colors.dart';
import '../models/character.dart';
import '../services/service_locator.dart';

/// Bottom sheet used to add a new character or edit an existing one.
///
/// When [initial] is `null` the sheet operates in add mode and writes a
/// fresh character into the world. When [initial] is supplied the sheet
/// pre-fills its fields and saves through `updateCharacter` instead so
/// the same form serves both create and edit flows. This mirrors the
/// dual-mode contract on [AddLocationSheet].
class AddCharacterSheet extends StatefulWidget {
  const AddCharacterSheet({super.key, required this.worldId, this.initial});

  final String worldId;
  final Character? initial;

  bool get isEditing => initial != null;

  /// Helper to show the sheet. Returns the saved character's id (or null
  /// if the user dismissed without saving). When [initial] is supplied
  /// the sheet opens in edit mode and the returned id matches it.
  static Future<String?> show(
    BuildContext context,
    String worldId, {
    Character? initial,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.midnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AddCharacterSheet(worldId: worldId, initial: initial),
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _roleController.text = initial.role;
      _descriptionController.text = initial.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final initial = widget.initial;
    try {
      final String resultId;
      if (initial == null) {
        final character = await dataService.addCharacter(
          worldId: widget.worldId,
          name: _nameController.text,
          role: _roleController.text,
          description: _descriptionController.text,
        );
        resultId = character.id;
      } else {
        await dataService.updateCharacter(
          initial.copyWith(
            name: _nameController.text.trim(),
            role: _roleController.text.trim(),
            description: _descriptionController.text.trim(),
          ),
        );
        resultId = initial.id;
      }
      if (!mounted) return;
      Navigator.of(context).pop(resultId);
    } catch (_) {
      if (!mounted) return;
      final message = initial == null
          ? AppStrings.saveCharacterFailed
          : AppStrings.updateCharacterFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isEditing = widget.isEditing;

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
                  isEditing
                      ? AppStrings.editCharacterTitle
                      : AppStrings.newCharacter,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autofocus: !isEditing,
                  textInputAction: TextInputAction.next,
                  maxLength: AppInput.maxNameLength,
                  validator: FormValidators.requiredWithMaxLength(
                    AppInput.maxNameLength,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.characterNameLabel,
                    prefixIcon: Icon(Icons.person_outline),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: AppInput.maxTaglineLength,
                  validator: FormValidators.maxLength(
                    AppInput.maxTaglineLength,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.characterRoleLabel,
                    hintText: AppStrings.characterRoleHint,
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: AppInput.maxDescriptionLength,
                  validator: FormValidators.maxLength(
                    AppInput.maxDescriptionLength,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.characterDescriptionLabel,
                    hintText: AppStrings.characterDescriptionHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: Text(
                    isEditing
                        ? AppStrings.saveCharacterChanges
                        : AppStrings.saveCharacter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
