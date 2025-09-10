class VisionBoardItem {
  final String id;
  final String imageUrl;
  final String title;
  final double aspectRatio; // Width/Height ratio for staggered layout
  final String? description;
  final DateTime? createdAt;
  final List<String>? tags;

  VisionBoardItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.aspectRatio = 1.0,
    this.description,
    this.createdAt,
    this.tags,
  });

  VisionBoardItem copyWith({
    String? id,
    String? imageUrl,
    String? title,
    double? aspectRatio,
    String? description,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return VisionBoardItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'aspectRatio': aspectRatio,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'tags': tags,
    };
  }

  factory VisionBoardItem.fromJson(Map<String, dynamic> json) {
    return VisionBoardItem(
      id: json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      aspectRatio: json['aspectRatio']?.toDouble() ?? 1.0,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      tags: json['tags']?.cast<String>(),
    );
  }
}
