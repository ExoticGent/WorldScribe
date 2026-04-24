import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../models/generated_character.dart';
import '../models/world.dart';
import '../services/service_locator.dart';

/// Bottom sheet for AI-assisted character generation.
class AiForgeSheet extends StatefulWidget {
  const AiForgeSheet({super.key, required this.world});

  final World world;

  static Future<GeneratedCharacter?> show(BuildContext context, World world) {
    return showModalBottomSheet<GeneratedCharacter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.midnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AiForgeSheet(world: world),
    );
  }

  @override
  State<AiForgeSheet> createState() => _AiForgeSheetState();
}

class _AiForgeSheetState extends State<AiForgeSheet> {
  final _promptController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prompt = _promptController.text.trim();
    if (_isGenerating) return;
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.aiForgePromptEmptyHint)),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final character = await aiForgeService.forgeCharacter(
        world: widget.world,
        prompt: prompt,
      );
      if (!mounted) return;
      Navigator.of(context).pop(character);
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        StateError(:final message) when message.isNotEmpty => message,
        _ => AppStrings.aiForgeFailed,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isAvailable = aiForgeService.isAvailable;
    final unavailableReason =
        aiForgeService.unavailableReason ?? AppStrings.aiForgeUnavailableHint;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
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
                AppStrings.aiForgeTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.world.name,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.goldDeep),
              ),
              const SizedBox(height: 14),
              if (!isAvailable) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.aiForgeUnavailableTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        unavailableReason,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ] else ...[
                Text(
                  AppStrings.aiForgeIntro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: AppStrings.aiForgePromptLabel,
                    hintText: AppStrings.aiForgePromptHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _submit,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text(AppStrings.aiForgeGenerateCharacter),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
