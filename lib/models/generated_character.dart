import 'package:flutter/foundation.dart';

/// Structured character payload returned by the AI Forge backend.
@immutable
class GeneratedCharacter {
  const GeneratedCharacter({
    required this.id,
    required this.worldId,
    required this.name,
    required this.role,
    required this.description,
  });

  final String id;
  final String worldId;
  final String name;
  final String role;
  final String description;

  factory GeneratedCharacter.fromJson(Map<String, dynamic> json) {
    return GeneratedCharacter(
      id: json['id'] as String,
      worldId: json['worldId'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'role': role,
    'description': description,
  };
}
