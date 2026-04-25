import 'package:flutter/material.dart';

import '../core/constants/app_input.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../core/forms/discard_changes_guard.dart';
import '../core/forms/form_validators.dart';
import '../models/world.dart';
import '../services/service_locator.dart';
import '../widgets/empty_state.dart';

/// Form for creating or editing a [World].
class CreateWorldScreen extends StatefulWidget {
  const CreateWorldScreen({super.key, this.worldId});

  final String? worldId;

  @override
  State<CreateWorldScreen> createState() => _CreateWorldScreenState();
}

class _CreateWorldScreenState extends State<CreateWorldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _isDirty = false;
  World? _existingWorld;
  bool _worldMissing = false;

  bool get _isEditing => widget.worldId != null;

  @override
  void initState() {
    super.initState();
    final worldId = widget.worldId;
    if (worldId == null) {
      _nameController.addListener(_onChanged);
      _genreController.addListener(_onChanged);
      _descriptionController.addListener(_onChanged);
      return;
    }

    final world = dataService.worldById(worldId);
    if (world == null) {
      _worldMissing = true;
      return;
    }

    _existingWorld = world;
    _nameController.text = world.name;
    _genreController.text = world.genre;
    _descriptionController.text = world.description;

    _nameController.addListener(_onChanged);
    _genreController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genreController.dispose();
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
    final existing = _existingWorld;
    if (existing == null) {
      // Create mode: any non-blank field counts as work in progress.
      return _nameController.text.trim().isNotEmpty ||
          _genreController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty;
    }
    // Edit mode: dirty iff any field diverged from the loaded world.
    return _nameController.text.trim() != existing.name ||
        _genreController.text.trim() != existing.genre ||
        _descriptionController.text.trim() != existing.description;
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

    try {
      if (_isEditing) {
        final existingWorld = _existingWorld;
        if (existingWorld == null) {
          throw StateError('Cannot edit a world that does not exist.');
        }

        await dataService.updateWorld(
          existingWorld.copyWith(
            name: _nameController.text.trim(),
            genre: _genreController.text.trim(),
            description: _descriptionController.text.trim(),
          ),
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      final world = await dataService.addWorld(
        name: _nameController.text,
        genre: _genreController.text,
        description: _descriptionController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.worldDashboard,
        arguments: WorldRouteArgs(worldId: world.id),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? AppStrings.updateWorldFailed
                : AppStrings.createWorldFailed,
          ),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_worldMissing) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editWorldTitle)),
        body: const EmptyState(
          icon: Icons.public_off_outlined,
          title: 'World not found',
          hint: 'This world may have been removed before it could be edited.',
        ),
      );
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopRequested,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? AppStrings.editWorldTitle
                : AppStrings.createWorldTitle,
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  maxLength: AppInput.maxNameLength,
                  validator: FormValidators.requiredWithMaxLength(
                    AppInput.maxNameLength,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.worldNameLabel,
                    hintText: AppStrings.worldNameHint,
                    prefixIcon: Icon(Icons.public),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _genreController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: AppInput.maxTaglineLength,
                  validator: FormValidators.maxLength(
                    AppInput.maxTaglineLength,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.worldGenreLabel,
                    hintText: AppStrings.worldGenreHint,
                    prefixIcon: Icon(Icons.local_fire_department_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: AppInput.maxDescriptionLength,
                  validator: FormValidators.maxLength(
                    AppInput.maxDescriptionLength,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.worldDescriptionLabel,
                    hintText: AppStrings.worldDescriptionHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    _isEditing
                        ? AppStrings.saveWorldChanges
                        : AppStrings.createAction,
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
