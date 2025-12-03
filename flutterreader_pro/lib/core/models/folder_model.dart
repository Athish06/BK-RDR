class FolderModel {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int documentCount; // For UI display

  FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.documentCount = 0,
  });

  bool get isRootFolder => parentId == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static FolderModel fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parentId: json['parent_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      documentCount: json['document_count'] ?? 0,
    );
  }

  FolderModel copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? documentCount,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentCount: documentCount ?? this.documentCount,
    );
  }

  @override
  String toString() {
    return 'FolderModel(id: $id, name: $name, parentId: $parentId)';
  }
}
