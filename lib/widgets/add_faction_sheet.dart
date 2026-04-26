import 'package:flutter/material.dart';

import '../core/constants/app_input.dart';
import '../core/constants/app_strings.dart';
import '../core/forms/discard_changes_guard.dart';
import '../core/forms/form_validators.dart';
import '../core/theme/app_colors.dart';
import '../models/faction.dart';
import '../services/service_locator.dart';

/// Bottom sheet used to add a new faction or edit an existing one.
class AddFactionSheet extends StatefulWidget {
  const AddFactionSheet({super.key, required this.worldId, this.initial});

  final String worldId;
  final Faction? initial;

  bool get isEditing => initial != null;

  static Future<String?> show(
    BuildContext context,
    String worldId, {
    Faction? initial,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.midnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AddFactionSheet(worldId: worldId, initial: initial),
    );
  }

  @override
  State<AddFactionSheet> createState() => _AddFactionSheetState();
}

class _AddFactionSheetState extends State<AddFactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ideologyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _ideologyController.text = initial.ideology;
      _descriptionController.text = initial.description;
    }
    _nameController.addListener(_onChanged);
    _ideologyController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ideologyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final dirty = _computeDirty();
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  bool _computeDirty() {
    final initial = widget.initial;
    if (initial == null) {
      return _nameController.text.trim().isNotEmpty ||
          _ideologyController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty;
    }
    return _nameController.text.trim() != initial.name ||
        _ideologyController.text.trim() != initial.ideology ||
        _descriptionController.text.trim() != initial.description;
  }

  Future<void> _onPopRequested(bool didPop, Object? result) async {
    if (didPop || _isSaving) return;
    final navigator = Navigator.of(context);
    final shouldDiscard = await confirmDiscardChanges(context);
    if (!mounted || !shouldDiscard) return;
    navigator.pop();
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final initial = widget.initial;
    try {
      final String resultId;
      if (initial == null) {
        final faction = await dataService.addFaction(
          worldId: widget.worldId,
          name: _nameController.text,
          ideology: _ideologyController.text,
          description: _descriptionController.text,
        );
        resultId = faction.id;
      } else {
        await dataService.updateFaction(
          initial.copyWith(
            name: _nameController.text.trim(),
            ideology: _ideologyController.text.trim(),
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
          ? AppStrings.saveFactionFailed
          : AppStrings.updateFactionFailed;
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

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopRequested,
      child: Padding(
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
                        ? AppStrings.editFactionTitle
                        : AppStrings.newFaction,
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
                      labelText: AppStrings.factionNameLabel,
                      prefixIcon: Icon(Icons.shield_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ideologyController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: AppInput.maxTaglineLength,
                    validator: FormValidators.maxLength(
                      AppInput.maxTaglineLength,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.factionIdeologyLabel,
                      hintText: AppStrings.factionIdeologyHint,
                      prefixIcon: Icon(Icons.flag_outlined),
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
                      labelText: AppStrings.factionDescriptionLabel,
                      hintText: AppStrings.factionDescriptionHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: const Icon(Icons.check),
                    label: Text(
                      isEditing
                          ? AppStrings.saveFactionChanges
                          : AppStrings.saveFaction,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
