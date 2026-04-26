import 'package:flutter/foundation.dart';

/// A faction belonging to a world: house, guild, cult, syndicate, court,
/// crew, or any other organized group whose members and territory shape
/// the story.
///
/// [characterIds] and [locationIds] hold inverse ids for characters and
/// locations tied to this faction. Both sides of each relationship are
/// stored, and the data service is responsible for keeping the lists in
/// sync.
@immutable
class Faction {
  const Faction({
    required this.id,
    required this.worldId,
    required this.name,
    required this.ideology,
    required this.description,
    required this.createdAt,
    this.characterIds = const [],
    this.locationIds = const [],
  });

  final String id;
  final String worldId;
  final String name;
  final String ideology;
  final String description;
  final DateTime createdAt;
  final List<String> characterIds;
  final List<String> locationIds;

  Faction copyWith({
    String? name,
    String? ideology,
    String? description,
    List<String>? characterIds,
    List<String>? locationIds,
  }) {
    return Faction(
      id: id,
      worldId: worldId,
      name: name ?? this.name,
      ideology: ideology ?? this.ideology,
      description: description ?? this.description,
      createdAt: createdAt,
      characterIds: characterIds ?? this.characterIds,
      locationIds: locationIds ?? this.locationIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'ideology': ideology,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'characterIds': characterIds,
    'locationIds': locationIds,
  };

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    name: json['name'] as String,
    ideology: json['ideology'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    characterIds:
        (json['characterIds'] as List?)?.cast<String>() ?? const <String>[],
    locationIds:
        (json['locationIds'] as List?)?.cast<String>() ?? const <String>[],
  );

  @override
  bool operator ==(Object other) =>
      other is Faction &&
      other.id == id &&
      other.worldId == worldId &&
      other.name == name &&
      other.ideology == ideology &&
      other.description == description &&
      other.createdAt == createdAt &&
      listEquals(other.characterIds, characterIds) &&
      listEquals(other.locationIds, locationIds);

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    name,
    ideology,
    description,
    createdAt,
    Object.hashAll(characterIds),
    Object.hashAll(locationIds),
  );
}
