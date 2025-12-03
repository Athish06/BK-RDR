import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder_model.dart';

/// Service for managing folders in Supabase
class FolderService {
  static FolderService? _instance;
  FolderService._internal();
  factory FolderService() => _instance ??= FolderService._internal();

  final _supabase = Supabase.instance.client;

  // ==================== CREATE FOLDER ====================

  /// Create a new folder
  Future<FolderModel?> createFolder({
    required String name,
    String? parentId,
  }) async {
    try {
      final folderData = {
        'name': name,
        'parent_id': parentId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('folders')
          .insert(folderData)
          .select()
          .single();

      print('✅ Created folder: $name');
      return FolderModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating folder: $e');
      return null;
    }
  }

  // ==================== GET FOLDERS ====================

  /// Get all folders
  Future<List<FolderModel>> getAllFolders() async {
    try {
      final response = await _supabase
          .from('folders')
          .select()
          .order('name');
      
      return (response as List).map((json) => FolderModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting folders: $e');
      return [];
    }
  }

  /// Get folders by parent (null for root folders)
  Future<List<FolderModel>> getFolders({String? parentId}) async {
    try {
      var query = _supabase.from('folders').select();

      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      } else {
        query = query.isFilter('parent_id', null);
      }

      final response = await query.order('name');
      return (response as List).map((json) => FolderModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting folders: $e');
      return [];
    }
  }

  /// Get a single folder by ID
  Future<FolderModel?> getFolder(String folderId) async {
    try {
      final response = await _supabase
          .from('folders')
          .select()
          .eq('id', folderId)
          .single();
      
      return FolderModel.fromJson(response);
    } catch (e) {
      print('❌ Error getting folder: $e');
      return null;
    }
  }

  /// Get child folders
  Future<List<FolderModel>> getChildFolders(String parentId) async {
    try {
      final response = await _supabase
          .from('folders')
          .select()
          .eq('parent_id', parentId)
          .order('name');
      
      return (response as List).map((json) => FolderModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting child folders: $e');
      return [];
    }
  }

  // ==================== UPDATE FOLDER ====================

  /// Rename a folder
  Future<bool> renameFolder(String folderId, String newName) async {
    try {
      await _supabase.from('folders').update({
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', folderId);
      
      print('✅ Renamed folder to: $newName');
      return true;
    } catch (e) {
      print('❌ Error renaming folder: $e');
      return false;
    }
  }

  /// Move folder to a new parent
  Future<bool> moveFolder(String folderId, String? newParentId) async {
    try {
      await _supabase.from('folders').update({
        'parent_id': newParentId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', folderId);
      
      print('✅ Moved folder');
      return true;
    } catch (e) {
      print('❌ Error moving folder: $e');
      return false;
    }
  }

  // ==================== DELETE FOLDER ====================

  /// Delete a folder (and optionally its contents)
  Future<bool> deleteFolder(String folderId) async {
    try {
      // Delete all documents in this folder
      await _supabase.from('documents').delete().eq('folder_id', folderId);
      
      // Delete all subfolders recursively
      final subfolders = await getChildFolders(folderId);
      for (final subfolder in subfolders) {
        await deleteFolder(subfolder.id);
      }
      
      // Delete the folder itself
      await _supabase.from('folders').delete().eq('id', folderId);
      
      print('✅ Deleted folder: $folderId');
      return true;
    } catch (e) {
      print('❌ Error deleting folder: $e');
      return false;
    }
  }

  // ==================== UTILITY ====================

  /// Get folder path (breadcrumbs)
  Future<List<FolderModel>> getFolderPath(String folderId) async {
    List<FolderModel> path = [];
    String? currentId = folderId;
    
    while (currentId != null) {
      final folder = await getFolder(currentId);
      if (folder != null) {
        path.insert(0, folder);
        currentId = folder.parentId;
      } else {
        break;
      }
    }
    
    return path;
  }
}
