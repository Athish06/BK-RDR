import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for storing annotation data
class AnnotationData {
  final String id;
  final String documentId;
  final String documentTitle;
  final int pageNumber;
  final String type; // highlight, underline, drawing, note, text
  final String? content;
  final String color;
  final Map<String, dynamic> position; // Stores points/coordinates
  final double strokeWidth;
  final List<Map<String, dynamic>>? strokePoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFromSupabase; // Track if annotation was loaded from Supabase

  AnnotationData({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.pageNumber,
    required this.type,
    this.content,
    this.color = '#FFFF00',
    required this.position,
    this.strokeWidth = 2.0,
    this.strokePoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFromSupabase = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'document_id': documentId,
        'document_title': documentTitle,
        'page_number': pageNumber,
        'type': type,
        'content': content,
        'color': color,
        'position': position,
        'stroke_width': strokeWidth,
        'stroke_points': strokePoints,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_from_supabase': isFromSupabase,
      };

  factory AnnotationData.fromJson(Map<String, dynamic> json) => AnnotationData(
        id: json['id'] as String,
        documentId: json['document_id'] as String,
        documentTitle: json['document_title'] as String? ?? 'Unknown',
        pageNumber: json['page_number'] as int,
        type: json['type'] as String,
        content: json['content'] as String?,
        color: json['color'] as String? ?? '#FFFF00',
        position: json['position'] as Map<String, dynamic>? ?? {},
        strokeWidth: (json['stroke_width'] as num?)?.toDouble() ?? 2.0,
        strokePoints: (json['stroke_points'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        isFromSupabase: json['is_from_supabase'] as bool? ?? false,
      );
  
  AnnotationData copyWith({
    String? id,
    String? documentId,
    String? documentTitle,
    int? pageNumber,
    String? type,
    String? content,
    String? color,
    Map<String, dynamic>? position,
    double? strokeWidth,
    List<Map<String, dynamic>>? strokePoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFromSupabase,
  }) {
    return AnnotationData(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      content: content ?? this.content,
      color: color ?? this.color,
      position: position ?? this.position,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokePoints: strokePoints ?? this.strokePoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFromSupabase: isFromSupabase ?? this.isFromSupabase,
    );
  }
}

/// Service for managing annotations with local storage and Supabase sync
class AnnotationService {
  static AnnotationService? _instance;
  AnnotationService._internal();
  factory AnnotationService() => _instance ??= AnnotationService._internal();

  static const String _localStorageKey = 'local_annotations';
  static const String _currentDocumentKey = 'current_document_id';
  
  final _supabase = Supabase.instance.client;
  
  // In-memory cache of current document's annotations
  List<AnnotationData> _currentAnnotations = [];
  String? _currentDocumentId;

  // ==================== LOCAL STORAGE ====================

  /// Get local annotations from SharedPreferences
  Future<List<AnnotationData>> getLocalAnnotations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localStorageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((e) => AnnotationData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting local annotations: $e');
      return [];
    }
  }

  /// Save annotations to local storage
  Future<bool> saveToLocalStorage(List<AnnotationData> annotations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(annotations.map((a) => a.toJson()).toList());
      await prefs.setString(_localStorageKey, jsonString);
      print('✅ Saved ${annotations.length} annotations to local storage');
      return true;
    } catch (e) {
      print('❌ Error saving to local storage: $e');
      return false;
    }
  }

  /// Clear local annotations
  Future<bool> clearLocalAnnotations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
      await prefs.remove(_currentDocumentKey);
      _currentAnnotations = [];
      _currentDocumentId = null;
      print('✅ Cleared local annotations');
      return true;
    } catch (e) {
      print('❌ Error clearing local annotations: $e');
      return false;
    }
  }

  /// Check if there are unsaved local annotations
  Future<bool> hasUnsavedAnnotations() async {
    final annotations = await getLocalAnnotations();
    return annotations.isNotEmpty;
  }

  /// Get the document ID of unsaved annotations
  Future<String?> getUnsavedDocumentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentDocumentKey);
    } catch (e) {
      return null;
    }
  }

  /// Set current document being annotated
  Future<void> setCurrentDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentDocumentKey, documentId);
      _currentDocumentId = documentId;
    } catch (e) {
      print('❌ Error setting current document: $e');
    }
  }

  // ==================== IN-MEMORY OPERATIONS ====================

  /// Initialize annotations for a document (load from Supabase)
  Future<List<AnnotationData>> loadAnnotationsForDocument(String documentId, String documentTitle) async {
    _currentDocumentId = documentId;
    await setCurrentDocument(documentId);
    
    // First check local storage for this document (unsaved new annotations)
    final localAnnotations = await getLocalAnnotations();
    final docLocalAnnotations = localAnnotations
        .where((a) => a.documentId == documentId && !a.isFromSupabase)
        .toList();
    
    // Load from Supabase
    try {
      final response = await _supabase
          .from('annotations')
          .select()
          .eq('document_id', documentId)
          .order('page_number')
          .order('created_at');
      
      final supabaseAnnotations = (response as List).map((json) {
        // Add document_title and mark as from Supabase
        json['document_title'] = documentTitle;
        json['is_from_supabase'] = true;
        return AnnotationData.fromJson(json);
      }).toList();
      
      // Combine Supabase annotations with any local unsaved annotations
      _currentAnnotations = [...supabaseAnnotations, ...docLocalAnnotations];
      
      print('✅ Loaded ${supabaseAnnotations.length} from Supabase + ${docLocalAnnotations.length} local annotations');
      return _currentAnnotations;
    } catch (e) {
      print('❌ Error loading annotations from Supabase: $e');
      // Fall back to local only
      _currentAnnotations = docLocalAnnotations;
      return _currentAnnotations;
    }
  }

  /// Add annotation to current session (in-memory + local storage)
  Future<AnnotationData> addAnnotation({
    required String documentId,
    required String documentTitle,
    required int pageNumber,
    required String type,
    String? content,
    String color = '#FFFF00',
    required Map<String, dynamic> position,
    double strokeWidth = 2.0,
    List<Map<String, dynamic>>? strokePoints,
  }) async {
    final annotation = AnnotationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: documentId,
      documentTitle: documentTitle,
      pageNumber: pageNumber,
      type: type,
      content: content,
      color: color,
      position: position,
      strokeWidth: strokeWidth,
      strokePoints: strokePoints,
    );
    
    _currentAnnotations.add(annotation);
    await _saveCurrentToLocal();
    
    print('✅ Added annotation: ${annotation.type} on page ${annotation.pageNumber}');
    return annotation;
  }

  /// Update an annotation
  Future<void> updateAnnotation(AnnotationData annotation) async {
    final index = _currentAnnotations.indexWhere((a) => a.id == annotation.id);
    if (index != -1) {
      _currentAnnotations[index] = annotation.copyWith(updatedAt: DateTime.now());
      await _saveCurrentToLocal();
      print('✅ Updated annotation: ${annotation.id}');
    }
  }

  /// Delete an annotation
  Future<void> deleteAnnotation(String annotationId) async {
    _currentAnnotations.removeWhere((a) => a.id == annotationId);
    await _saveCurrentToLocal();
    print('✅ Deleted annotation: $annotationId');
  }

  /// Get current document's annotations
  List<AnnotationData> getCurrentAnnotations() {
    return List.unmodifiable(_currentAnnotations);
  }

  /// Get annotations for a specific page
  List<AnnotationData> getAnnotationsForPage(int pageNumber) {
    return _currentAnnotations
        .where((a) => a.pageNumber == pageNumber)
        .toList();
  }

  /// Save current annotations to local storage
  Future<void> _saveCurrentToLocal() async {
    // Get existing annotations for other documents
    final allLocal = await getLocalAnnotations();
    final otherDocs = allLocal
        .where((a) => a.documentId != _currentDocumentId)
        .toList();
    
    // Combine with current document's annotations
    final combined = [...otherDocs, ..._currentAnnotations];
    await saveToLocalStorage(combined);
  }

  // ==================== SUPABASE SYNC ====================

  /// Save only NEW local annotations to Supabase (not ones already from Supabase)
  Future<bool> syncToSupabase() async {
    // Filter to only sync new annotations (not from Supabase)
    final newAnnotations = _currentAnnotations.where((a) => !a.isFromSupabase).toList();
    
    if (newAnnotations.isEmpty) {
      print('⚠️ No new annotations to sync (${_currentAnnotations.length} already synced)');
      return true;
    }
    
    print('📤 Syncing ${newAnnotations.length} NEW annotations to Supabase...');
    
    try {
      for (final annotation in newAnnotations) {
        // Map textHighlight to highlight for Supabase constraint compatibility
        String dbType = annotation.type;
        if (dbType == 'textHighlight') {
          dbType = 'highlight';
        }
        
        final annotationData = {
          'document_id': annotation.documentId,
          'page_number': annotation.pageNumber,
          'type': dbType,
          'content': annotation.content,
          'color': annotation.color,
          'position': annotation.position,
          'stroke_width': annotation.strokeWidth,
          'stroke_points': annotation.strokePoints,
          'created_at': annotation.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Insert new annotation
        await _supabase.from('annotations').insert(annotationData);
      }
      
      print('✅ Synced ${newAnnotations.length} NEW annotations to Supabase');
      return true;
    } catch (e) {
      print('❌ Error syncing to Supabase: $e');
      return false;
    }
  }

  /// Save and close - sync to Supabase and clear local storage
  Future<bool> saveAndClose() async {
    final success = await syncToSupabase();
    if (success) {
      await clearLocalAnnotations();
    }
    return success;
  }

  // ==================== FETCH ALL ANNOTATIONS ====================

  /// Get all annotations from Supabase (for annotation tools page)
  Future<List<AnnotationData>> getAllAnnotations() async {
    try {
      // First get all documents to map IDs to titles
      final docsResponse = await _supabase
          .from('documents')
          .select('id, title');
      
      final docMap = <String, String>{};
      for (final doc in docsResponse as List) {
        docMap[doc['id']] = doc['title'] ?? 'Unknown';
      }
      
      // Get all annotations
      final response = await _supabase
          .from('annotations')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) {
        json['document_title'] = docMap[json['document_id']] ?? 'Unknown';
        return AnnotationData.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Error getting all annotations: $e');
      return [];
    }
  }

  /// Get annotations grouped by document
  Future<Map<String, List<AnnotationData>>> getAnnotationsGroupedByDocument() async {
    final annotations = await getAllAnnotations();
    final grouped = <String, List<AnnotationData>>{};
    
    for (final annotation in annotations) {
      final key = '${annotation.documentId}|${annotation.documentTitle}';
      grouped.putIfAbsent(key, () => []).add(annotation);
    }
    
    return grouped;
  }

  /// Get annotations for a specific document from Supabase
  Future<List<AnnotationData>> getAnnotationsForDocument(String documentId) async {
    try {
      // Get document title
      final docResponse = await _supabase
          .from('documents')
          .select('title')
          .eq('id', documentId)
          .single();
      
      final docTitle = docResponse['title'] ?? 'Unknown';
      
      final response = await _supabase
          .from('annotations')
          .select()
          .eq('document_id', documentId)
          .order('page_number')
          .order('created_at');
      
      return (response as List).map((json) {
        json['document_title'] = docTitle;
        return AnnotationData.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Error getting annotations for document: $e');
      return [];
    }
  }

  /// Delete annotation from Supabase
  Future<bool> deleteAnnotationFromSupabase(String annotationId) async {
    try {
      await _supabase.from('annotations').delete().eq('id', annotationId);
      print('✅ Deleted annotation from Supabase: $annotationId');
      return true;
    } catch (e) {
      print('❌ Error deleting annotation: $e');
      return false;
    }
  }
}
