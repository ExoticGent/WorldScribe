import 'package:flutter/foundation.dart';

/// A place within a world: city, ruin, region, landmark, or hideout.
@immutable
class Location {
  const Location({
    required this.id,
    required this.worldId,
    required this.name,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String worldId;
  final String name;
  final String type;
  final String description;
  final DateTime createdAt;

  Location copyWith({String? name, String? type, String? description}) {
    return Location(
      id: id,
      worldId: worldId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'name': name,
    'type': type,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    name: json['name'] as String,
    type: json['type'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is Location &&
      other.id == id &&
      other.worldId == worldId &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, worldId, name, type, description, createdAt);
}
