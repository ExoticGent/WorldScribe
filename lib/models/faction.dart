import 'package:flutter/foundation.dart';

/// A faction belonging to a world: house, guild, cult, syndicate, court,
/// crew, or any other organized group whose members and territory shape
/// the story.
///
/// Relationships to [Character]s and [Location]s land in M8b — for now
/// the model is a standalone CRUD entity that mirrors [Character] and
/// [Location] in shape so the existing form / detail patterns drop
/// straight in.
@immutable
class Faction {
  const Faction({
    required this.id,
    required this.worldId,
    required this.name,
    required this.ideology,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String worldId;
  final String name;
  final String ideology;
  final String description;
  final DateTime createdAt;

  Faction copyWith({String? name, String? ideology, String? description}) {
    return Faction(
      id: id,
      worldId: worldId,
      name: name ?? this.name,
      ideology: ideology ?? this.ideology,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'ideology': ideology,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    name: json['name'] as String,
    ideology: json['ideology'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is Faction &&
      other.id == id &&
      other.worldId == worldId &&
      other.name == name &&
      other.ideology == ideology &&
      other.description == description &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, worldId, name, ideology, description, createdAt);
}
