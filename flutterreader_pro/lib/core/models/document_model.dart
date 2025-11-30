class DocumentModel {
  final String id;
  final String title;
  final String filePath;
  final String originalName;
  final int fileSize;
  final DateTime dateAdded;
  final DateTime lastOpened;
  final double readingProgress;
  final bool isFavorite;
  final String status; // 'new', 'in_progress', 'completed'

  DocumentModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.originalName,
    required this.fileSize,
    required this.dateAdded,
    required this.lastOpened,
    this.readingProgress = 0.0,
    this.isFavorite = false,
    this.status = 'new',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'originalName': originalName,
      'fileSize': fileSize,
      'dateAdded': dateAdded.toIso8601String(),
      'lastOpened': lastOpenedFormatted, // Use formatted string for UI
      'readingProgress': readingProgress,
      'isFavorite': isFavorite,
      'status': status,
    };
  }

  static DocumentModel fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      filePath: json['file_path'] ?? json['filePath'] ?? '',
      originalName: json['original_name'] ?? json['originalName'] ?? '',
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      dateAdded: DateTime.tryParse(json['created_at'] ?? json['dateAdded'] ?? '') ?? DateTime.now(),
      lastOpened: DateTime.tryParse(json['last_opened'] ?? json['lastOpened'] ?? '') ?? DateTime.now(),
      readingProgress: (json['reading_progress'] ?? json['readingProgress'] ?? 0.0).toDouble(),
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      status: json['status'] ?? 'new',
    );
  }

  DocumentModel copyWith({
    String? id,
    String? title,
    String? filePath,
    String? originalName,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? lastOpened,
    double? readingProgress,
    bool? isFavorite,
    String? status,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      originalName: originalName ?? this.originalName,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      readingProgress: readingProgress ?? this.readingProgress,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
    );
  }

  // Helper methods
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get lastOpenedFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastOpened);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${(difference.inDays / 7).floor()} weeks ago';
  }

  String get progressStatus {
    if (readingProgress == 0) return 'new';
    if (readingProgress >= 100) return 'completed';
    return 'in_progress';
  }
}
