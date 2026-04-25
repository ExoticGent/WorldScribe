import 'package:flutter/material.dart';

import '../core/constants/app_input.dart';
import '../core/constants/app_strings.dart';
import '../core/forms/discard_changes_guard.dart';
import '../core/forms/form_validators.dart';
import '../core/theme/app_colors.dart';
import '../models/location.dart';
import '../services/service_locator.dart';

/// Bottom sheet used to add a new location or edit an existing one.
///
/// When [initial] is `null` the sheet operates in add mode and writes a
/// fresh location into the world. When [initial] is supplied the sheet
/// pre-fills its fields and saves through `updateLocation` instead so
/// the same form serves both create and edit flows.
class AddLocationSheet extends StatefulWidget {
  const AddLocationSheet({super.key, required this.worldId, this.initial});

  final String worldId;
  final Location? initial;

  bool get isEditing => initial != null;

  static Future<String?> show(
    BuildContext context,
    String worldId, {
    Location? initial,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.midnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AddLocationSheet(worldId: worldId, initial: initial),
    );
  }

  @override
  State<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<AddLocationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _typeController.text = initial.type;
      _descriptionController.text = initial.description;
    }
    _nameController.addListener(_onChanged);
    _typeController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
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
      // Add mode: any non-blank field counts as work in progress.
      return _nameController.text.trim().isNotEmpty ||
          _typeController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty;
    }
    // Edit mode: dirty iff any field diverged from the initial location.
    return _nameController.text.trim() != initial.name ||
        _typeController.text.trim() != initial.type ||
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
        final location = await dataService.addLocation(
          worldId: widget.worldId,
          name: _nameController.text,
          type: _typeController.text,
          description: _descriptionController.text,
        );
        resultId = location.id;
      } else {
        await dataService.updateLocation(
          initial.copyWith(
            name: _nameController.text.trim(),
            type: _typeController.text.trim(),
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
          ? AppStrings.saveLocationFailed
          : AppStrings.updateLocationFailed;
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
                        ? AppStrings.editLocationTitle
                        : AppStrings.newLocation,
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
                      labelText: AppStrings.locationNameLabel,
                      prefixIcon: Icon(Icons.place_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _typeController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: AppInput.maxTaglineLength,
                    validator: FormValidators.maxLength(
                      AppInput.maxTaglineLength,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.locationTypeLabel,
                      hintText: AppStrings.locationTypeHint,
                      prefixIcon: Icon(Icons.terrain_outlined),
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
                      labelText: AppStrings.locationDescriptionLabel,
                      hintText: AppStrings.locationDescriptionHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: const Icon(Icons.check),
                    label: Text(
                      isEditing
                          ? AppStrings.saveLocationChanges
                          : AppStrings.saveLocation,
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
