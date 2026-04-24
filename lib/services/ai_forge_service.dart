import 'package:cloud_functions/cloud_functions.dart';

import '../models/generated_character.dart';
import '../models/world.dart';

/// App-facing contract for AI-assisted generation features.
abstract class AiForgeService {
  const AiForgeService();

  bool get isAvailable;

  String? get unavailableReason;

  Future<GeneratedCharacter> forgeCharacter({
    required World world,
    required String prompt,
  });
}

/// Callable-function implementation that delegates generation to the
/// Firebase backend so Gemini credentials stay server-side.
class FirebaseAiForgeService extends AiForgeService {
  FirebaseAiForgeService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  bool get isAvailable => true;

  @override
  String? get unavailableReason => null;

  @override
  Future<GeneratedCharacter> forgeCharacter({
    required World world,
    required String prompt,
  }) async {
    final result = await _functions.httpsCallable('generateCharacter').call({
      'worldId': world.id,
      'prompt': prompt.trim(),
    });

    final payload = result.data;
    if (payload is! Map) {
      throw StateError('AI Forge returned an unexpected response payload.');
    }

    final data = Map<String, dynamic>.from(payload);
    final character = data['character'];
    if (character is! Map) {
      throw StateError('AI Forge did not return a character payload.');
    }

    return GeneratedCharacter.fromJson(Map<String, dynamic>.from(character));
  }
}

/// Placeholder implementation used when Firebase or Cloud Functions are
/// unavailable. It lets the UI explain the limitation cleanly.
class UnavailableAiForgeService extends AiForgeService {
  const UnavailableAiForgeService({this.reason});

  final String? reason;

  @override
  bool get isAvailable => false;

  @override
  String? get unavailableReason => reason;

  @override
  Future<GeneratedCharacter> forgeCharacter({
    required World world,
    required String prompt,
  }) {
    throw StateError(reason ?? 'AI Forge is unavailable.');
  }
}
