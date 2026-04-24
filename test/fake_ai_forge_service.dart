import 'package:worldscribe/models/generated_character.dart';
import 'package:worldscribe/models/world.dart';
import 'package:worldscribe/services/ai_forge_service.dart';
import 'package:worldscribe/services/service_locator.dart';

class FakeAiForgeService extends AiForgeService {
  const FakeAiForgeService();

  @override
  bool get isAvailable => true;

  @override
  String? get unavailableReason => null;

  @override
  Future<GeneratedCharacter> forgeCharacter({
    required World world,
    required String prompt,
  }) async {
    final character = await dataService.addCharacter(
      worldId: world.id,
      name: 'The Glass Archivist',
      role: 'AI-forged chronicler',
      description:
          'Forged from "$prompt", this keeper of brittle prophecies catalogues every omen that ripples across ${world.name}.',
    );

    return GeneratedCharacter(
      id: character.id,
      worldId: character.worldId,
      name: character.name,
      role: character.role,
      description: character.description,
    );
  }
}
