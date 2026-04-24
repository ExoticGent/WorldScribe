import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/route_args.dart';
import '../services/service_locator.dart';

/// Form for creating a new [World]. On save, inserts into [DataService]
/// and replaces this route with the new world's dashboard so the user
/// lands inside the thing they just made rather than bouncing back to
/// the empty home list.
class CreateWorldScreen extends StatefulWidget {
  const CreateWorldScreen({super.key});

  @override
  State<CreateWorldScreen> createState() => _CreateWorldScreenState();
}

class _CreateWorldScreenState extends State<CreateWorldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
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
        const SnackBar(content: Text(AppStrings.createWorldFailed)),
      );
      setState(() => _isSaving = false);
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createWorldTitle)),
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
                validator: _requiredValidator,
                decoration: const InputDecoration(
                  labelText: AppStrings.worldNameLabel,
                  hintText: AppStrings.worldNameHint,
                  prefixIcon: Icon(Icons.public),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: AppStrings.worldGenreLabel,
                  hintText: AppStrings.worldGenreHint,
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 8,
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
                label: const Text(AppStrings.createAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
