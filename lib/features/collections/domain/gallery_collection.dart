import 'package:flutter/foundation.dart';

/// A user-curated group of screenshots — "why this matters to me" (Apartment
/// hunting, Wedding stuff, Send to Sarah), distinct from AI tags, which
/// answer "what this is" (Receipts, Finance, Memes). A screenshot can belong
/// to any number of collections and keep its tags too — the two systems are
/// orthogonal, not competing.
@immutable
class GalleryCollection {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  const GalleryCollection({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  GalleryCollection copyWith({String? name, int? colorValue}) =>
      GalleryCollection(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GalleryCollection.fromJson(Map<String, dynamic> json) =>
      GalleryCollection(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Untitled',
        colorValue: json['color'] as int? ?? 0xFF2F6FED,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
