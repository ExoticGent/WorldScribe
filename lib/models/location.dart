import 'package:flutter/foundation.dart';

/// A place within a world: city, ruin, region, landmark, or hideout.
///
/// [characterIds] and [factionIds] hold ids of entities tied to this
/// location. Both sides of each relationship are stored, and the data
/// service is responsible for keeping the lists in sync.
@immutable
class Location {
  const Location({
    required this.id,
    required this.worldId,
    required this.name,
    required this.type,
    required this.description,
    required this.createdAt,
    this.characterIds = const [],
    this.factionIds = const [],
  });

  final String id;
  final String worldId;
  final String name;
  final String type;
  final String description;
  final DateTime createdAt;
  final List<String> characterIds;
  final List<String> factionIds;

  Location copyWith({
    String? name,
    String? type,
    String? description,
    List<String>? characterIds,
    List<String>? factionIds,
  }) {
    return Location(
      id: id,
      worldId: worldId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt,
      characterIds: characterIds ?? this.characterIds,
      factionIds: factionIds ?? this.factionIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'type': type,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'characterIds': characterIds,
    'factionIds': factionIds,
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    name: json['name'] as String,
    type: json['type'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    characterIds:
        (json['characterIds'] as List?)?.cast<String>() ?? const <String>[],
    factionIds:
        (json['factionIds'] as List?)?.cast<String>() ?? const <String>[],
  );

  @override
  bool operator ==(Object other) =>
      other is Location &&
      other.id == id &&
      other.worldId == worldId &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      other.createdAt == createdAt &&
      listEquals(other.characterIds, characterIds) &&
      listEquals(other.factionIds, factionIds);

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    name,
    type,
    description,
    createdAt,
    Object.hashAll(characterIds),
    Object.hashAll(factionIds),
  );
}
