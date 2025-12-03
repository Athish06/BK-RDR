import 'package:flutter/material.dart';

class DocumentModel {
  final String id;
  final String title;
  final String filePath; // Public URL for the PDF
  final String? supabasePath; // Storage path in Supabase bucket
  final String originalName;
  final int fileSize;
  final DateTime dateAdded;
  final DateTime lastOpened;
  final double readingProgress;
  final bool isFavorite;
  final String status; // 'new', 'in_progress', 'completed'
  final String mimeType;
  final int? pageCount;
  final int lastPage;
  final String? folderId;

  DocumentModel({
    required this.id,
    required this.title,
    required this.filePath,
    this.supabasePath,
    required this.originalName,
    required this.fileSize,
    required this.dateAdded,
    required this.lastOpened,
    this.readingProgress = 0.0,
    this.isFavorite = false,
    this.status = 'new',
    this.mimeType = 'application/pdf',
    this.pageCount,
    this.lastPage = 1,
    this.folderId,
  });

  // Convenience getters
  bool get isNew => status == 'new';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get hasProgress => readingProgress > 0 && readingProgress < 1;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'supabase_path': supabasePath,
      'original_name': originalName,
      'file_size': fileSize,
      'created_at': dateAdded.toIso8601String(),
      'last_opened': lastOpened.toIso8601String(),
      'reading_progress': readingProgress,
      'is_favorite': isFavorite,
      'status': status,
      'mime_type': mimeType,
      'page_count': pageCount,
      'last_page': lastPage,
      'folder_id': folderId,
    };
  }

  static DocumentModel fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      filePath: json['file_path'] ?? json['filePath'] ?? '',
      supabasePath: json['supabase_path'] ?? json['storage_path'],
      originalName: json['original_name'] ?? json['originalName'] ?? '',
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      dateAdded: DateTime.tryParse(json['created_at'] ?? json['dateAdded'] ?? '') ?? DateTime.now(),
      lastOpened: DateTime.tryParse(json['last_opened'] ?? json['last_opened_at'] ?? json['lastOpened'] ?? '') ?? DateTime.now(),
      readingProgress: (json['reading_progress'] ?? json['readingProgress'] ?? 0.0).toDouble(),
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      status: json['status'] ?? 'new',
      mimeType: json['mime_type'] ?? 'application/pdf',
      pageCount: json['page_count'],
      lastPage: json['last_page'] ?? 1,
      folderId: json['folder_id'],
    );
  }

  DocumentModel copyWith({
    String? id,
    String? title,
    String? filePath,
    String? supabasePath,
    String? originalName,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? lastOpened,
    double? readingProgress,
    bool? isFavorite,
    String? status,
    String? mimeType,
    int? pageCount,
    int? lastPage,
    String? folderId,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      supabasePath: supabasePath ?? this.supabasePath,
      originalName: originalName ?? this.originalName,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      readingProgress: readingProgress ?? this.readingProgress,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
      mimeType: mimeType ?? this.mimeType,
      pageCount: pageCount ?? this.pageCount,
      lastPage: lastPage ?? this.lastPage,
      folderId: folderId ?? this.folderId,
    );
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, title: $title, progress: ${(readingProgress * 100).toInt()}%)';
  }
}

