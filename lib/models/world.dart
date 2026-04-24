import 'package:flutter/foundation.dart';

/// A top-level worldbuilding container. Characters, locations, factions,
/// and lore will all hang off a [World].
@immutable
class World {
  const World({
    required this.id,
    required this.name,
    required this.genre,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String genre;
  final String description;
  final DateTime createdAt;

  World copyWith({String? name, String? genre, String? description}) {
    return World(
      id: id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'genre': genre,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory World.fromJson(Map<String, dynamic> json) => World(
    id: json['id'] as String,
    name: json['name'] as String,
    genre: json['genre'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is World &&
      other.id == id &&
      other.name == name &&
      other.genre == genre &&
      other.description == description &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, genre, description, createdAt);
}
