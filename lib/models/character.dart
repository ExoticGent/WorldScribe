import 'package:flutter/foundation.dart';

/// A single character belonging to a world.
@immutable
class Character {
  const Character({
    required this.id,
    required this.worldId,
    required this.name,
    required this.role,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String worldId;
  final String name;
  final String role;
  final String description;
  final DateTime createdAt;

  Character copyWith({String? name, String? role, String? description}) {
    return Character(
      id: id,
      worldId: worldId,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'role': role,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    name: json['name'] as String,
    role: json['role'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is Character &&
      other.id == id &&
      other.worldId == worldId &&
      other.name == name &&
      other.role == role &&
      other.description == description &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, worldId, name, role, description, createdAt);
}
