import 'dart:typed_data';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

class DocumentService {
  static DocumentService? _instance;
  DocumentService._internal();
  factory DocumentService() => _instance ??= DocumentService._internal();

  final _supabase = Supabase.instance.client;

  // ==================== FILE PICKING ====================

  /// Pick PDF files from device
  Future<List<PlatformFile>?> pickFiles() async {
    try {
      print('📂 Picking files...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        print('✅ Files picked: ${result.files.length}');
        return result.files;
      }
      
      print('⚠️ No files picked');
      return null;
    } catch (e) {
      print('❌ Error picking files: $e');
      return null;
    }
  }

  // ==================== IMPORT DOCUMENTS ====================

  /// Import files to Supabase Storage
  Future<List<DocumentModel>?> importDocuments(List<PlatformFile> files, {String? folderId}) async {
    try {
      List<DocumentModel> importedDocs = [];

      for (PlatformFile file in files) {
        final doc = await _uploadToSupabase(file, folderId: folderId);
        if (doc != null) {
          importedDocs.add(doc);
        }
      }

      return importedDocs.isNotEmpty ? importedDocs : null;
    } catch (e) {
      print('❌ Error importing documents: $e');
      return null;
    }
  }

  /// Upload a single file to Supabase
  Future<DocumentModel?> _uploadToSupabase(PlatformFile file, {String? folderId}) async {
    try {
      // Sanitize filename
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final filePath = 'uploads/$fileName';

      print('🚀 Uploading $fileName to Supabase...');

      // Upload to Supabase Storage
      if (kIsWeb) {
        if (file.bytes != null) {
          await _supabase.storage.from('document_files').uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
        } else {
          throw Exception('File bytes are null on Web');
        }
      } else {
        if (file.path != null) {
          await _supabase.storage.from('document_files').upload(
            filePath,
            File(file.path!),
            fileOptions: const FileOptions(upsert: true),
          );
        } else if (file.bytes != null) {
          await _supabase.storage.from('document_files').uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
        } else {
          throw Exception('File path and bytes are null');
        }
      }

      print('✅ Upload successful');

      // Get Public URL
      final publicUrl = _supabase.storage.from('document_files').getPublicUrl(filePath);

      // Create document record in DB
      final docData = {
        'title': path.basenameWithoutExtension(file.name),
        'file_path': publicUrl,
        'supabase_path': filePath,
        'original_name': file.name,
        'file_size': file.size,
        'folder_id': folderId,
        'created_at': DateTime.now().toIso8601String(),
        'last_opened': DateTime.now().toIso8601String(),
        'reading_progress': 0.0,
        'is_favorite': false,
        'status': 'new',
      };

      final response = await _supabase
          .from('documents')
          .insert(docData)
          .select()
          .single();

      print('✅ Document record created');
      return DocumentModel.fromJson(response);
    } catch (e) {
      print('❌ Error uploading to Supabase: $e');
      return null;
    }
  }

  // ==================== LEGACY METHOD (BACKWARD COMPATIBLE) ====================

  /// Pick files and upload to Supabase (convenience method)
  Future<List<DocumentModel>?> pickAndImportDocuments({String? folderId}) async {
    final files = await pickFiles();
    if (files == null) return null;
    return importDocuments(files, folderId: folderId);
  }

  // ==================== GET DOCUMENTS ====================

  /// Get all documents from Supabase
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .order('last_opened', ascending: false);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting documents: $e');
      return [];
    }
  }

  /// Get documents in a specific folder
  Future<List<DocumentModel>> getDocumentsInFolder(String? folderId) async {
    try {
      var query = _supabase.from('documents').select();
      
      if (folderId != null) {
        query = query.eq('folder_id', folderId);
      } else {
        query = query.isFilter('folder_id', null);
      }
      
      final response = await query.order('last_opened', ascending: false);
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting documents in folder: $e');
      return [];
    }
  }

  /// Get recent documents
  Future<List<DocumentModel>> getRecentDocuments({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .order('last_opened', ascending: false)
          .limit(limit);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting recent documents: $e');
      return [];
    }
  }

  /// Get continue reading documents (in progress)
  Future<List<DocumentModel>> getContinueReadingDocuments({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .gt('reading_progress', 0.0)
          .lt('reading_progress', 1.0)
          .order('last_opened', ascending: false)
          .limit(limit);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting continue reading documents: $e');
      return [];
    }
  }

  /// Get favorite documents
  Future<List<DocumentModel>> getFavoriteDocuments() async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('is_favorite', true)
          .order('last_opened', ascending: false);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting favorite documents: $e');
      return [];
    }
  }

  // ==================== UPDATE DOCUMENTS ====================
  
  /// Update document reading progress
  Future<void> updateProgress(String id, double progress) async {
    try {
      await _supabase.from('documents').update({
        'reading_progress': progress,
        'last_opened': DateTime.now().toIso8601String(),
        'status': progress >= 1.0 ? 'completed' : 'in_progress',
      }).eq('id', id);
    } catch (e) {
      if (kDebugMode) print('Error updating progress: $e');
    }
  }

  /// Update reading progress with last page and page count
  Future<void> updateReadingProgress(String id, double progress, int lastPage, {int? pageCount}) async {
    try {
      final updateData = {
        'reading_progress': progress,
        'last_page': lastPage,
        'last_opened': DateTime.now().toIso8601String(),
        'status': progress >= 1.0 ? 'completed' : 'in_progress',
      };
      
      if (pageCount != null) {
        updateData['page_count'] = pageCount;
      }
      
      await _supabase.from('documents').update(updateData).eq('id', id);
      if (kDebugMode) print('Progress updated: ${(progress * 100).toInt()}%, page $lastPage');
    } catch (e) {
      if (kDebugMode) print('Error updating reading progress: $e');
    }
  }

  /// Update document details
  Future<void> updateDocument(DocumentModel document) async {
    try {
      await _supabase.from('documents').update({
        'title': document.title,
        'is_favorite': document.isFavorite,
        'status': document.status,
        'last_opened': DateTime.now().toIso8601String(),
      }).eq('id', document.id);
    } catch (e) {
      if (kDebugMode) print('Error updating document: $e');
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String documentId, bool isFavorite) async {
    try {
      await _supabase.from('documents').update({
        'is_favorite': isFavorite,
      }).eq('id', documentId);
      return true;
    } catch (e) {
      if (kDebugMode) print('Error toggling favorite: $e');
      return false;
    }
  }

  /// Move document to folder
  Future<bool> moveToFolder(String documentId, String? folderId) async {
    try {
      await _supabase.from('documents').update({
        'folder_id': folderId,
      }).eq('id', documentId);
      return true;
    } catch (e) {
      if (kDebugMode) print('Error moving document: $e');
      return false;
    }
  }

  /// Rename document
  Future<bool> renameDocument(String documentId, String newTitle) async {
    try {
      await _supabase.from('documents').update({
        'title': newTitle,
      }).eq('id', documentId);
      return true;
    } catch (e) {
      if (kDebugMode) print('Error renaming document: $e');
      return false;
    }
  }

  // ==================== DELETE DOCUMENTS ====================

  /// Delete document (from storage and database)
  Future<bool> deleteDocument(String documentId) async {
    try {
      // Get document details first
      final doc = await _supabase
          .from('documents')
          .select()
          .eq('id', documentId)
          .single();
      
      // Delete from Supabase Storage
      final storagePath = doc['supabase_path'];
      if (storagePath != null) {
        try {
          await _supabase.storage.from('document_files').remove([storagePath]);
          print('✅ File deleted from storage');
        } catch (e) {
          print('⚠️ Could not delete from storage: $e');
        }
      }

      // Delete from database
      await _supabase.from('documents').delete().eq('id', documentId);
      
      print('✅ Document deleted: $documentId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting document: $e');
      return false;
    }
  }

  // ==================== SEARCH ====================

  /// Search documents by title
  Future<List<DocumentModel>> searchDocuments(String query) async {
    if (query.isEmpty) {
      return getAllDocuments();
    }
    
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .ilike('title', '%$query%')
          .order('last_opened', ascending: false);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching documents: $e');
      return [];
    }
  }
}
