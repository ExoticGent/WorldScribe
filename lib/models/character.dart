import 'package:flutter/foundation.dart';

/// A single character belonging to a world.
///
/// [locationIds] and [factionIds] hold ids of entities this character is
/// associated with. Both sides of each relationship are stored, and the
/// data service is responsible for keeping the lists in sync.
@immutable
class Character {
  const Character({
    required this.id,
    required this.worldId,
    required this.name,
    required this.role,
    required this.description,
    required this.createdAt,
    this.locationIds = const [],
    this.factionIds = const [],
  });

  final String id;
  final String worldId;
  final String name;
  final String role;
  final String description;
  final DateTime createdAt;
  final List<String> locationIds;
  final List<String> factionIds;

  Character copyWith({
    String? name,
    String? role,
    String? description,
    List<String>? locationIds,
    List<String>? factionIds,
  }) {
    return Character(
      id: id,
      worldId: worldId,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      createdAt: createdAt,
      locationIds: locationIds ?? this.locationIds,
      factionIds: factionIds ?? this.factionIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'role': role,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'locationIds': locationIds,
    'factionIds': factionIds,
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    name: json['name'] as String,
    role: json['role'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    locationIds:
        (json['locationIds'] as List?)?.cast<String>() ?? const <String>[],
    factionIds:
        (json['factionIds'] as List?)?.cast<String>() ?? const <String>[],
  );

  @override
  bool operator ==(Object other) =>
      other is Character &&
      other.id == id &&
      other.worldId == worldId &&
      other.name == name &&
      other.role == role &&
      other.description == description &&
      other.createdAt == createdAt &&
      listEquals(other.locationIds, locationIds) &&
      listEquals(other.factionIds, factionIds);

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    name,
    role,
    description,
    createdAt,
    Object.hashAll(locationIds),
    Object.hashAll(factionIds),
  );
}
