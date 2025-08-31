import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/document_model.dart';

class DocumentService {
  static DocumentService? _instance;
  DocumentService._internal();
  factory DocumentService() => _instance ??= DocumentService._internal();

  static const String _documentsKey = 'user_documents';

  // Get app documents directory
  Future<Directory> getAppDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(appDir.path, 'pdf_documents'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  // Pick files from device storage
  Future<List<DocumentModel>?> pickAndImportDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<DocumentModel> importedDocs = [];
        final appDir = await getAppDocumentsDirectory();

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            // Copy file to app directory
            final originalFile = File(file.path!);
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final newPath = path.join(appDir.path, fileName);
            final copiedFile = await originalFile.copy(newPath);

            // Create document model
            final document = DocumentModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: path.basenameWithoutExtension(file.name),
              filePath: copiedFile.path,
              originalName: file.name,
              fileSize: file.size,
              dateAdded: DateTime.now(),
              lastOpened: DateTime.now(),
            );

            importedDocs.add(document);
          }
        }

        // Save to storage
        await _saveDocuments(importedDocs);
        return importedDocs;
      }
    } catch (e) {
      if (kDebugMode) print('Error picking files: $e');
    }
    return null;
  }

  // Save documents to local storage
  Future<void> _saveDocuments(List<DocumentModel> newDocuments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingDocs = await getAllDocuments();
      
      final allDocs = [...existingDocs, ...newDocuments];
      final jsonList = allDocs.map((doc) => doc.toJson()).toList();
      
      await prefs.setString(_documentsKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) print('Error saving documents: $e');
    }
  }

  // Get all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_documentsKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Error getting documents: $e');
    }
    return [];
  }

  // Update document
  Future<void> updateDocument(DocumentModel updatedDocument) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allDocs = await getAllDocuments();
      
      final index = allDocs.indexWhere((doc) => doc.id == updatedDocument.id);
      if (index != -1) {
        allDocs[index] = updatedDocument;
        final jsonList = allDocs.map((doc) => doc.toJson()).toList();
        await prefs.setString(_documentsKey, jsonEncode(jsonList));
      }
    } catch (e) {
      if (kDebugMode) print('Error updating document: $e');
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allDocs = await getAllDocuments();
      
      final docToDelete = allDocs.firstWhere((doc) => doc.id == documentId);
      
      // Delete physical file
      final file = File(docToDelete.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from list
      allDocs.removeWhere((doc) => doc.id == documentId);
      final jsonList = allDocs.map((doc) => doc.toJson()).toList();
      await prefs.setString(_documentsKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) print('Error deleting document: $e');
    }
  }

  // Get documents by category
  Future<Map<String, List<DocumentModel>>> getDocumentsByCategory() async {
    final allDocs = await getAllDocuments();
    
    return {
      'Favorites': allDocs.where((doc) => doc.isFavorite).toList(),
      'In Progress': allDocs.where((doc) => doc.progressStatus == 'in_progress').toList(),
      'Completed': allDocs.where((doc) => doc.progressStatus == 'completed').toList(),
      'Recent': allDocs.where((doc) => doc.progressStatus == 'new').take(10).toList(),
    };
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments(String query) async {
    final allDocs = await getAllDocuments();
    if (query.isEmpty) return allDocs;
    
    return allDocs.where((doc) => 
      doc.title.toLowerCase().contains(query.toLowerCase()) ||
      doc.originalName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get library statistics
  Future<Map<String, dynamic>> getLibraryStats() async {
    final allDocs = await getAllDocuments();
    final totalSize = allDocs.fold<int>(0, (sum, doc) => sum + doc.fileSize);
    
    return {
      'totalDocuments': allDocs.length,
      'totalSize': totalSize,
      'favorites': allDocs.where((doc) => doc.isFavorite).length,
      'inProgress': allDocs.where((doc) => doc.progressStatus == 'in_progress').length,
      'completed': allDocs.where((doc) => doc.progressStatus == 'completed').length,
    };
  }
}
