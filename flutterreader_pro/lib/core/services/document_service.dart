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

  // Pick files and upload to Supabase
  Future<List<DocumentModel>?> pickAndImportDocuments() async {
    try {
      print('📂 Picking files...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true, // Important for Web
      );

      if (result != null && result.files.isNotEmpty) {
        print('✅ Files picked: ${result.files.length}');
        List<DocumentModel> importedDocs = [];

        for (PlatformFile file in result.files) {
          // Sanitize filename
          final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
          final filePath = 'uploads/$fileName';
          
          print('🚀 Uploading $fileName...');

          // Upload to Supabase Storage
          try {
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
          } catch (uploadError) {
            print('❌ Upload failed: $uploadError');
            throw Exception('Failed to upload file: $uploadError');
          }

          // Get Public URL
          final publicUrl = _supabase.storage.from('document_files').getPublicUrl(filePath);
          print('🔗 Public URL: $publicUrl');

          // Create document record in DB
          final docData = {
            'title': path.basenameWithoutExtension(file.name),
            'file_path': publicUrl,
            'storage_path': filePath,
            'original_name': file.name,
            'file_size': file.size,
            'created_at': DateTime.now().toIso8601String(),
            'last_opened': DateTime.now().toIso8601String(),
            'reading_progress': 0.0,
            'is_favorite': false,
            'status': 'new',
          };

          print('📝 Inserting into DB...');
          final response = await _supabase
              .from('documents')
              .insert(docData)
              .select()
              .single();
          
          print('✅ DB Insert successful');
          importedDocs.add(DocumentModel.fromJson(response));
        }

        return importedDocs;
      } else {
        print('⚠️ No files picked');
      }
    } catch (e) {
      print('❌ Error importing documents: $e');
      rethrow; // Let the UI handle the error
    }
    return null;
  }

  // Get all documents from Supabase
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

  // Get recent documents
  Future<List<DocumentModel>> getRecentDocuments() async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .order('last_opened', ascending: false)
          .limit(5);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting recent documents: $e');
      return [];
    }
  }

  // Get continue reading documents
  Future<List<DocumentModel>> getContinueReadingDocuments() async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .gt('reading_progress', 0.0)
          .lt('reading_progress', 1.0)
          .order('last_opened', ascending: false)
          .limit(5);
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting continue reading documents: $e');
      return [];
    }
  }
  
  // Update document progress
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

  // Update document details (status, favorite, etc.)
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

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      // Get storage path first
      final doc = await _supabase
          .from('documents')
          .select('storage_path')
          .eq('id', documentId)
          .single();
      
      if (doc['storage_path'] != null) {
        await _supabase.storage.from('document_files').remove([doc['storage_path']]);
      }

      await _supabase.from('documents').delete().eq('id', documentId);
    } catch (e) {
      if (kDebugMode) print('Error deleting document: $e');
    }
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments(String query) async {
    if (query.isEmpty) return getAllDocuments();
    
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .ilike('title', '%$query%');
      
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching documents: $e');
      return [];
    }
  }
}
