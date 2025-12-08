import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sizer/sizer.dart';
import 'package:universal_io/io.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:async';
import 'models/pdf_annotation.dart';

import '../../core/app_export.dart';

import '../../core/app_export.dart';
import './widgets/pdf_annotation_toolbar.dart';
import './widgets/pdf_bookmark_panel.dart';
import './widgets/pdf_floating_controls.dart';
import './widgets/pdf_quick_note_bubble.dart';
import './widgets/pdf_search_overlay.dart';

class PdfReader extends StatefulWidget {
  const PdfReader({super.key});

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  // Services
  final AnnotationService _annotationService = AnnotationService();
  final DocumentService _documentService = DocumentService();
  bool _hasUnsavedAnnotations = false;
  
  // PDF state
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  String _selectedText = '';
  bool _isDarkMode = false;
  
  // UI state
  bool _showControls = true;
  bool _showAnnotationToolbar = false;
  bool _showBookmarkPanel = false;
  bool _showSearchOverlay = false;
  
  // Search state
  String _searchQuery = '';
  int _currentSearchMatch = 0;
  int _totalSearchMatches = 0;
  PdfTextSearcher? _textSearcher;

  DocumentModel? _document;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  // Loading state
  Uint8List? _pdfBytes;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  // Bookmarks and notes
  final List<Map<String, dynamic>> _bookmarks = [];
  final List<Map<String, dynamic>> _quickNotes = [];
  
  // Annotations
  final List<PdfAnnotation> _annotations = [];
  bool _isAnnotating = false; // True when actively drawing/highlighting
  bool _isDrawing = false; // True when drawing tool is in active use
  AnnotationType _currentTool = AnnotationType.drawing; // Default to drawing
  bool _isToolActive = false; // Whether a tool is actively being used
  String? _currentAnnotationId; // ID of annotation being created
  String? _currentDrawingAnnotationId; // ID of drawing annotation being created
  Offset? _annotationStartOffset; // Start position for rectangle-based annotations
  List<PdfPageTextRange> _selectedTextRanges = []; // For text selection (legacy)
  
  // Floating navbar state
  bool _showFloatingNavbar = true; // Show/hide the floating navbar
  bool _showNotesPanel = false; // Show/hide saved notes panel
  bool _isPanMode = false; // Pan/cursor mode for moving around when zoomed
  bool _useTextHighlight = false; // If true, use text-detection highlight; if false, use paint highlight
  bool _showZoomControls = true; // Show/hide zoom control bar
  
  // Page indicator auto-fade
  bool _showPageIndicator = true;
  Timer? _pageIndicatorTimer;
  int _pageIndicatorDuration = 3; // seconds, 0 = always visible
  final SettingsService _settingsService = SettingsService();
  
  // Selected annotation for showing comment
  String? _selectedAnnotationId; // Currently selected annotation for note viewing
  Offset? _annotationCommentPosition; // Position to show the annotation comment

  Color _selectedAnnotationColor = Colors.blue; // Default from settings
  
  // Scroll direction from settings
  Axis _scrollDirection = Axis.vertical;
  
  // Text detection for underline
  Map<int, PdfPageRawText?> _pageTextCache = {}; // Cache for page raw text data
  List<Rect> _detectedTextRects = []; // Detected text rectangles for current underline

  @override
  void initState() {
    super.initState();
    _loadPageIndicatorSettings();
    _setupAutoHideControls();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _loadPageIndicatorSettings() async {
    await _settingsService.init();
    final duration = await _settingsService.getPageNumberDuration();
    final highlightColor = _settingsService.defaultHighlightColorAsColor;
    final scrollDir = _settingsService.scrollDirection;
    if (mounted) {
      setState(() {
        _pageIndicatorDuration = duration;
        _selectedAnnotationColor = highlightColor;
        _scrollDirection = scrollDir == 'horizontal' ? Axis.horizontal : Axis.vertical;
      });
    }
  }

  void _startPageIndicatorTimer() {
    _pageIndicatorTimer?.cancel();
    
    // If duration is 0, always show
    if (_pageIndicatorDuration == 0) {
      setState(() => _showPageIndicator = true);
      return;
    }
    
    // Show indicator
    setState(() => _showPageIndicator = true);
    
    // Start timer to hide
    _pageIndicatorTimer = Timer(Duration(seconds: _pageIndicatorDuration), () {
      if (mounted) {
        setState(() => _showPageIndicator = false);
      }
    });
  }

  @override
  void dispose() {
    _pageIndicatorTimer?.cancel();
    _textSearcher?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DocumentModel && !_hasLoaded) {
      _document = args;
      _loadPdf();
      _loadAnnotationsFromService(); // Load saved annotations
      _updateDocumentStatus(); // Mark as in_progress when opened
      _hasLoaded = true;
    }
  }

  /// Update document status to in_progress and set last opened
  Future<void> _updateDocumentStatus() async {
    if (_document == null) return;
    
    try {
      // Update status to in_progress if it's new
      if (_document!.status == 'new') {
        await _documentService.updateDocument(_document!.copyWith(status: 'in_progress'));
        print('📖 Document status updated to in_progress');
      }
      
      // Update last opened time
      await _documentService.updateReadingProgress(
        _document!.id,
        _document!.readingProgress,
        _document!.lastPage,
      );
    } catch (e) {
      print('❌ Error updating document status: $e');
    }
  }

  Future<void> _loadPdf() async {
    if (_document == null) return;
    
    try {
      setState(() { _isLoading = true; _errorMessage = null; });
      print('📥 Starting PDF load for: ${_document!.title}');
      
      if (kIsWeb || _document!.filePath.startsWith('http')) {
         print('🌐 Downloading PDF from URL: ${_document!.filePath}');
         
         if (kIsWeb) {
           try {
             final request = await html.HttpRequest.request(
               _document!.filePath,
               responseType: 'arraybuffer',
             );
             
             if (request.status == 200) {
               final ByteBuffer buffer = request.response;
               final Uint8List bytes = buffer.asUint8List();
               
               print('✅ Web Download complete. Size: ${bytes.length} bytes');
               if (bytes.isNotEmpty) {
                 final header = String.fromCharCodes(bytes.take(5));
                 print('🔍 PDF Header: $header');
               }

               // Create a defensive copy of the bytes to ensure we own the memory
               // and it's not a view into a shared buffer (which can cause issues with Syncfusion)
               final cleanBytes = Uint8List.fromList(bytes);

               if (mounted) {
                 setState(() {
                   _pdfBytes = cleanBytes;
                   _isLoading = false;
                 });
               }
               return;
             }
           } catch (e) {
             print('⚠️ Web XHR failed, falling back to Dio: $e');
           }
         }

         final response = await Dio().get(
           _document!.filePath,
           options: Options(
             responseType: ResponseType.bytes,
             validateStatus: (status) => status! < 500,
           ),
         );
         
         if (response.statusCode == 200) {
           print('✅ Download complete. Size: ${response.data.length} bytes');
           print('🔍 Data Type: ${response.data.runtimeType}');
           
           List<int> bytesList;
           if (response.data is List<int>) {
             bytesList = response.data;
           } else if (response.data is List) {
             bytesList = List<int>.from(response.data);
           } else {
             throw Exception('Unexpected data type: ${response.data.runtimeType}');
           }

           if (bytesList.isNotEmpty) {
             final header = String.fromCharCodes(bytesList.take(5));
             print('🔍 PDF Header: $header'); // Should be %PDF-
             
             final len = bytesList.length;
             final tail = String.fromCharCodes(bytesList.sublist(len - 6, len));
             print('🔍 PDF Tail: $tail'); // Should be %%EOF
           }

           // Create a defensive copy
           final cleanBytes = Uint8List.fromList(bytesList);

           if (mounted) {
             setState(() {
               _pdfBytes = cleanBytes;
               _isLoading = false;
             });
           }
         } else {
           print('❌ Download failed with status: ${response.statusCode}');
           throw Exception('Failed to download PDF (Status: ${response.statusCode})');
         }
      } else {
         // Local file (not web)
         print('📂 Loading local file: ${_document!.filePath}');
         final file = File(_document!.filePath);
         if (await file.exists()) {
           final bytes = await file.readAsBytes();
           if (mounted) {
             setState(() {
               _pdfBytes = bytes;
               _isLoading = false;
             });
           }
         } else {
           throw Exception('Local file not found: ${_document!.filePath}');
         }
      }
    } catch (e) {
      print('❌ Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Load annotations from service after document is loaded
  Future<void> _loadAnnotationsFromService() async {
    if (_document == null) return;
    
    try {
      final annotations = await _annotationService.loadAnnotationsForDocument(
        _document!.id,
        _document!.title,
      );
      
      // Convert AnnotationData to PdfAnnotation for display
      final pdfAnnotations = annotations.map((a) => _convertToPdfAnnotation(a)).toList();
      
      if (mounted) {
        setState(() {
          _annotations.addAll(pdfAnnotations);
        });
        print('✅ Loaded ${pdfAnnotations.length} annotations from service');
      }
    } catch (e) {
      print('❌ Error loading annotations: $e');
    }
  }

  /// Convert AnnotationData to PdfAnnotation
  PdfAnnotation _convertToPdfAnnotation(AnnotationData data) {
    // Parse points from position data
    final points = <Offset>[];
    
    // Check position['points'] first
    if (data.position['points'] != null) {
      for (final p in data.position['points'] as List) {
        points.add(Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()));
      }
    } 
    // Fallback to strokePoints for drawings if points is empty
    else if (data.strokePoints != null && data.strokePoints!.isNotEmpty) {
      for (final p in data.strokePoints!) {
        points.add(Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()));
      }
    }
    
    // Parse annotation type
    AnnotationType type;
    switch (data.type) {
      case 'highlight':
        type = AnnotationType.highlight;
        break;
      case 'textHighlight':
        type = AnnotationType.textHighlight;
        break;
      case 'underline':
        type = AnnotationType.underline;
        break;
      case 'drawing':
        type = AnnotationType.drawing;
        break;
      case 'text':
        type = AnnotationType.text;
        break;
      case 'note':
        type = AnnotationType.text;
        break;
      default:
        type = AnnotationType.highlight;
    }
    
    return PdfAnnotation(
      id: data.id,
      pageNumber: data.pageNumber,
      type: type,
      color: _hexToColor(data.color),
      points: points,
      textRanges: [],
      linkedNote: data.content,
    );
  }

  /// Convert hex color string to Color
  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.yellow;
    }
  }

  /// Convert Color to hex string (preserves alpha)
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Save standalone note as annotation
  Future<void> _saveStandaloneNote(String note) async {
    if (_document == null) return;
    
    await _annotationService.addAnnotation(
      documentId: _document!.id,
      documentTitle: _document!.title,
      pageNumber: _currentPage,
      type: 'note',
      content: note,
      color: '#FFFF00', // Default note color
      position: {'points': []}, // No points for standalone note
      strokeWidth: 0,
    );
    
    setState(() {
      _hasUnsavedAnnotations = true;
    });
  }

  /// Save annotation to local storage via service
  Future<void> _saveAnnotationToLocal(PdfAnnotation annotation) async {
    if (_document == null) return;
    
    // Convert points to storable format
    final pointsList = annotation.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList();
    
    // For drawings, also save to strokePoints
    List<Map<String, dynamic>>? strokePoints;
    if (annotation.type == AnnotationType.drawing) {
      strokePoints = pointsList;
    }
    
    await _annotationService.addAnnotation(
      documentId: _document!.id,
      documentTitle: _document!.title,
      pageNumber: annotation.pageNumber,
      type: annotation.type.name,
      content: annotation.linkedNote,
      color: _colorToHex(annotation.color),
      position: {'points': pointsList},
      strokeWidth: 2.0,
      strokePoints: strokePoints,
    );
    
    setState(() {
      _hasUnsavedAnnotations = true;
    });
  }

  /// Save all annotations to Supabase and close
  Future<void> _saveAndClose() async {
    // First, check if user is on the last page - ask about marking as finished
    final bool isOnLastPage = _currentPage >= _totalPages && _totalPages > 0;
    
    if (isOnLastPage) {
      final shouldMarkFinished = await _showFinishedDialog();
      if (shouldMarkFinished == true) {
        await _markDocumentAsFinished();
      }
    }
    
    // Ask for the last page they've read
    final lastPageRead = await _showLastPageDialog();
    if (lastPageRead == null) return; // User cancelled
    
    // Update reading progress
    await _updateReadingProgress(lastPageRead);
    
    // If no annotations, just close
    if (_annotations.isEmpty) {
      Navigator.pop(context);
      return;
    }
    
    // Show saving dialog with better styling
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Saving your work...',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Syncing annotations to cloud',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
    
    try {
      // Sync all annotations to Supabase
      final success = await _annotationService.saveAndClose();
      
      if (mounted) {
        Navigator.pop(context); // Close saving dialog
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved successfully'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Close PDF reader
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save annotations'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close saving dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Show dialog asking about last page read
  Future<int?> _showLastPageDialog() async {
    final controller = TextEditingController(text: _currentPage.toString());
    
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bookmark_outline, color: AppTheme.accentColor, size: 32),
            ),
            SizedBox(height: 16),
            Text(
              'Save Reading Progress',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'What page did you finish reading?',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Page',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'of $_totalPages pages',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final page = int.tryParse(controller.text) ?? _currentPage;
                    final validPage = page.clamp(1, _totalPages > 0 ? _totalPages : page);
                    Navigator.pop(context, validPage);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show dialog asking if user wants to mark book as finished
  Future<bool?> _showFinishedDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text('🎉', style: TextStyle(fontSize: 48)),
            ),
            SizedBox(height: 24),
            Text(
              'Congratulations!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You\'ve reached the last page!',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Would you like to mark this book as finished?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Text('Not Yet', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Finished! ✓', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Mark document as finished
  Future<void> _markDocumentAsFinished() async {
    if (_document == null) return;
    
    try {
      await _documentService.updateDocument(_document!.copyWith(
        status: 'completed',
        readingProgress: 1.0,
        lastPage: _totalPages,
      ));
      print('✅ Document marked as finished');
    } catch (e) {
      print('❌ Error marking document as finished: $e');
    }
  }

  /// Update reading progress based on last page read
  Future<void> _updateReadingProgress(int lastPage) async {
    if (_document == null || _totalPages <= 0) return;
    
    final progress = lastPage / _totalPages;
    
    try {
      await _documentService.updateReadingProgress(
        _document!.id,
        progress,
        lastPage,
      );
      print('📊 Progress updated: ${(progress * 100).toInt()}% (page $lastPage of $_totalPages)');
    } catch (e) {
      print('❌ Error updating progress: $e');
    }
  }

  /// Show confirmation dialog when user tries to leave without saving
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedAnnotations || _annotations.isEmpty) {
      return true;
    }
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unsaved Annotations', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'You have unsaved annotations. What would you like to do?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (result == 'save') {
      await _saveAndClose();
      return false; // We handle navigation in _saveAndClose
    } else if (result == 'discard') {
      await _annotationService.clearLocalAnnotations();
      return true;
    }
    
    return false; // Cancel - stay on page
  }

  void _setupAutoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  // Handle text selection changes (legacy - for fallback text selection)
  void _handleTextSelectionChange(PdfTextSelection? selection) async {
    if (selection == null || !selection.hasSelectedText) {
      return;
    }
    
    final selectedText = await selection.getSelectedText();
    print('🔍 Text selection changed: $selectedText');
    
    // Store text ranges for potential annotation
    final ranges = await selection.getSelectedTextRanges();
    if (ranges.isNotEmpty) {
      setState(() {
        _selectedText = selectedText;
        _selectedTextRanges = ranges;
        _showAnnotationToolbar = true;
      });
    }
  }

  void _toggleControls() {
    // If tool is active, just minimize UI controls but keep tool working
    if (_isToolActive) {
      setState(() {
        _showFloatingNavbar = false;
        _showAnnotationToolbar = false;
        _showSearchOverlay = false;
        _showBookmarkPanel = false;
        _showNotesPanel = false;
        _showZoomControls = false;
        _selectedAnnotationId = null;
        _annotationCommentPosition = null;
        // Keep top controls visible even when tool is active
        _showControls = true;
      });
      return; // Don't toggle controls, keep tool active
    }
    
    // Toggle floating navbar and overlays, but ALWAYS keep top bar visible
    if (_showFloatingNavbar || _showSearchOverlay || _showBookmarkPanel || _showNotesPanel) {
      setState(() {
        // Always keep top controls (back, save) visible
        _showControls = true;
        _showFloatingNavbar = false;
        _showAnnotationToolbar = false;
        _showSearchOverlay = false;
        _showBookmarkPanel = false;
        _showNotesPanel = false;
        _showZoomControls = false;
        _selectedAnnotationId = null;
        _annotationCommentPosition = null;
      });
    } else {
      // Nothing visible, show all controls
      setState(() {
        _showControls = true;
        _showFloatingNavbar = true;
      });
      _setupAutoHideControls();
    }
  }
  
  // Load text data for a page (for underline text detection)
  Future<void> _loadPageText(int pageNumber) async {
    if (_pageTextCache.containsKey(pageNumber)) return;
    
    try {
      if (_pdfViewerController.isReady) {
        final document = _pdfViewerController.document;
        final page = document.pages[pageNumber - 1];
        final rawText = await page.loadText();
        if (rawText != null) {
          _pageTextCache[pageNumber] = rawText;
          print('📝 Loaded text for page $pageNumber: ${rawText.fullText.length} chars, ${rawText.charRects.length} rects');
        }
      }
    } catch (e) {
      print('❌ Error loading page text: $e');
    }
  }
  
  // Detect text at position and add to detected rects (word-level detection)
  void _detectTextAtPosition(Offset position, int pageNumber, Size pageSize) {
    final pageText = _pageTextCache[pageNumber];
    if (pageText == null || pageText.charRects.isEmpty) return;
    
    try {
      final page = _pdfViewerController.document.pages[pageNumber - 1];
      final scaleX = pageSize.width / page.width;
      final scaleY = pageSize.height / page.height;
      
      final fullText = pageText.fullText;
      final charRects = pageText.charRects;
      
      // Find the character at the cursor position
      for (int i = 0; i < charRects.length && i < fullText.length; i++) {
        final charRect = charRects[i];
        
        // Convert PDF coordinates to widget coordinates
        final widgetRect = Rect.fromLTRB(
          charRect.left * scaleX,
          pageSize.height - (charRect.top * scaleY),
          charRect.right * scaleX,
          pageSize.height - (charRect.bottom * scaleY),
        );
        
        // Check if cursor is near this character
        final expandedRect = widgetRect.inflate(8);
        if (expandedRect.contains(position)) {
          // Found a character at cursor - now find the whole word
          final wordBounds = _findWordBounds(fullText, charRects, i, scaleX, scaleY, pageSize.height);
          
          if (wordBounds != null) {
            // Check if this word is already detected
            bool alreadyDetected = _detectedTextRects.any((r) => 
              (r.left - wordBounds.left).abs() < 5 && 
              (r.right - wordBounds.right).abs() < 5 &&
              (r.top - wordBounds.top).abs() < 5
            );
            
            if (!alreadyDetected) {
              setState(() {
                _detectedTextRects.add(wordBounds);
              });
              // Extract the detected word for logging
              final wordStart = _findWordStart(fullText, i);
              final wordEnd = _findWordEnd(fullText, i);
              final word = fullText.substring(wordStart, wordEnd);
              print('📍 Detected word: "$word"');
            }
          }
          break; // Found a character, no need to continue
        }
      }
    } catch (e) {
      print('❌ Error detecting text: $e');
    }
  }
  
  // Find word start index
  int _findWordStart(String text, int index) {
    int start = index;
    while (start > 0 && !_isWordBoundary(text[start - 1])) {
      start--;
    }
    return start;
  }
  
  // Find word end index
  int _findWordEnd(String text, int index) {
    int end = index;
    while (end < text.length && !_isWordBoundary(text[end])) {
      end++;
    }
    return end;
  }
  
  // Check if character is a word boundary
  bool _isWordBoundary(String char) {
    return char == ' ' || char == '\n' || char == '\t' || char == '.' || 
           char == ',' || char == ':' || char == ';' || char == '!' || 
           char == '?' || char == '(' || char == ')' || char == '[' || 
           char == ']' || char == '{' || char == '}';
  }
  
  // Find the bounding rectangle for a word
  Rect? _findWordBounds(String text, List<PdfRect> charRects, int charIndex, 
                        double scaleX, double scaleY, double pageHeight) {
    final wordStart = _findWordStart(text, charIndex);
    final wordEnd = _findWordEnd(text, charIndex);
    
    if (wordStart >= wordEnd || wordStart >= charRects.length) return null;
    
    // Calculate bounding box for all characters in the word
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (int i = wordStart; i < wordEnd && i < charRects.length; i++) {
      final rect = charRects[i];
      final widgetRect = Rect.fromLTRB(
        rect.left * scaleX,
        pageHeight - (rect.top * scaleY),
        rect.right * scaleX,
        pageHeight - (rect.bottom * scaleY),
      );
      
      if (widgetRect.left < minX) minX = widgetRect.left;
      if (widgetRect.right > maxX) maxX = widgetRect.right;
      if (widgetRect.top < minY) minY = widgetRect.top;
      if (widgetRect.bottom > maxY) maxY = widgetRect.bottom;
    }
    
    if (minX == double.infinity) return null;
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // Handle starting an annotation (draw, highlight, or underline)
  void _startAnnotation(Offset localPosition, int pageNumber) async {
    if (!_isToolActive) return;
    
    // For underline, load page text first
    if (_currentTool == AnnotationType.underline) {
      await _loadPageText(pageNumber);
      _detectedTextRects = [];
    }
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    print('🎨 Starting ${_currentTool.name} annotation at $localPosition on page $pageNumber');
    
    setState(() {
      _isAnnotating = true;
      _currentAnnotationId = id;
      _annotationStartOffset = localPosition; // Store start position for rectangle bounds
      _annotations.add(PdfAnnotation(
        id: id,
        pageNumber: pageNumber,
        type: _currentTool,
        color: _currentTool == AnnotationType.highlight 
            ? _selectedAnnotationColor.withValues(alpha: 0.4)
            : _selectedAnnotationColor,
        points: [localPosition],
        textRanges: [],
      ));
    });
  }
  
  // Handle updating an annotation (adding points)
  void _updateAnnotation(Offset localPosition, {int? pageNumber, Size? pageSize}) {
    if (!_isAnnotating || _currentAnnotationId == null) return;
    
    final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
    if (index != -1) {
      setState(() {
        _annotations[index] = _annotations[index].copyWith(
          points: [..._annotations[index].points, localPosition],
        );
      });
    }
  }
  
  // Handle ending an annotation
  void _endAnnotation() {
    if (!_isAnnotating) return;
    
    // For underline, store the detected text rectangles
    if (_currentTool == AnnotationType.underline && _currentAnnotationId != null) {
      final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
      if (index != -1 && _detectedTextRects.isNotEmpty) {
        // Convert Rect list to points for storage
        final textPoints = <Offset>[];
        for (final rect in _detectedTextRects) {
          // Store bottom-left and bottom-right of each text rect for underline
          textPoints.add(Offset(rect.left, rect.bottom));
          textPoints.add(Offset(rect.right, rect.bottom));
        }
        
        setState(() {
          _annotations[index] = _annotations[index].copyWith(
            points: textPoints,
          );
        });
      }
    }
    
    // Save the completed annotation to local storage
    if (_currentAnnotationId != null) {
      final annotation = _annotations.where((a) => a.id == _currentAnnotationId).firstOrNull;
      if (annotation != null && annotation.points.length > 1) {
        _saveAnnotationToLocal(annotation);
      }
    }
    
    print('🎨 Ending annotation: $_currentAnnotationId');
    setState(() {
      _isAnnotating = false;
      _currentAnnotationId = null;
      _annotationStartOffset = null;
      _detectedTextRects = [];
    });
    HapticFeedback.lightImpact();
  }
  
  // Select a tool and activate it
  void _selectTool(AnnotationType tool) {
    print('🔧 Tool selected: ${tool.name}');
    setState(() {
      _currentTool = tool;
      _isToolActive = true;
      _showFloatingNavbar = false; // Auto-minimize navbar when tool is selected
      _showZoomControls = false; // Auto-minimize zoom controls
      _isPanMode = false; // Disable pan mode when tool is active
      _selectedAnnotationId = null; // Clear any selected annotation
    });
    HapticFeedback.selectionClick();
  }
  
  // Deactivate current tool
  void _deactivateTool() {
    setState(() {
      _isToolActive = false;
      _showAnnotationToolbar = false;
    });
  }
  
  // Close all overlays and minimize controls (one tool at a time)
  void _closeAllOverlays() {
    setState(() {
      _showAnnotationToolbar = false;
      _showSearchOverlay = false;
      _showBookmarkPanel = false;
      _showNotesPanel = false;
      _isToolActive = false;
      _selectedAnnotationId = null;
    });
  }
  
  // Minimize all UI controls but keep current mode active
  void _minimizeAllControls() {
    setState(() {
      _showFloatingNavbar = false;
      _showZoomControls = false;
      _showAnnotationToolbar = false;
      _showSearchOverlay = false;
      _showBookmarkPanel = false;
      _showNotesPanel = false;
      _selectedAnnotationId = null;
      _annotationCommentPosition = null;
    });
  }
  
  // Navigate to annotation and show its comment popup
  void _navigateToAnnotation(String annotationId) {
    final annotation = _annotations.where((a) => a.id == annotationId).firstOrNull;
    if (annotation == null) return;
    
    // Navigate to page
    _handlePageNavigation(annotation.pageNumber);
    
    // Select annotation - position will be calculated when page renders
    setState(() {
      _selectedAnnotationId = annotationId;
      // Set initial position, will be updated based on annotation bounds
      if (annotation.points.isNotEmpty) {
        // Use normalized position scaled to approximate widget size
        final firstPoint = annotation.points.first;
        _annotationCommentPosition = Offset(
          firstPoint.dx * 300, // Approximate page width
          (firstPoint.dy * 500) - 50, // Approximate page height, offset upward
        );
      } else {
        _annotationCommentPosition = const Offset(50, 100);
      }
    });
    
    HapticFeedback.selectionClick();
  }
  
  // Enable pan mode - allows panning and zooming PDF when activated
  void _togglePanMode() {
    setState(() {
      _isPanMode = !_isPanMode;
      if (_isPanMode) {
        // Entering pan mode - disable tool and show pan indicator
        _isToolActive = false;
        _showAnnotationToolbar = false;
        // Keep controls visible so user can see they're in pan mode
        _showControls = true;
        _showFloatingNavbar = true;
      } else {
        // Exiting pan mode - restore normal state
        _showFloatingNavbar = true;
        _showControls = true;
      }
    });
    HapticFeedback.lightImpact();
    
    // Show feedback toast
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPanMode ? 'Pan mode enabled - drag to move around' : 'Pan mode disabled'),
        duration: const Duration(seconds: 1),
        backgroundColor: _isPanMode ? AppTheme.accentColor : AppTheme.surfaceColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Show quick note dialog - can be linked to an annotation
  void _showQuickNoteDialog({String? annotationId}) {
    PdfQuickNoteBubble.showAsDialog(
      context: context,
      initialNote: '',
      onSave: (note) {
        if (note.isNotEmpty) {
          // Store the note
          final noteData = {
            'id': DateTime.now().millisecondsSinceEpoch,
            'note': note,
            'page': _currentPage,
            'timestamp': DateTime.now().toIso8601String(),
            'annotationId': annotationId, // Link to annotation if provided
          };
          setState(() {
            _quickNotes.add(noteData);
          });
          
          // If linked to an annotation, also update the annotation's linkedNote
          if (annotationId != null) {
            final index = _annotations.indexWhere((a) => a.id == annotationId);
            if (index != -1) {
              setState(() {
                _annotations[index] = _annotations[index].copyWith(
                  linkedNote: note,
                );
              });
              // Save updated annotation to local/Supabase
              _saveAnnotationToLocal(_annotations[index]);
            }
          } else {
            // Save standalone note as an annotation of type 'note'
            _saveStandaloneNote(note);
          }
          
          print('📝 Note saved: $note${annotationId != null ? ' (linked to annotation $annotationId)' : ''}');
        }
      },
      onDelete: () {
        // Nothing to delete for new notes
      },
    );
  }
  
  // Show note dialog for an existing annotation
  void _showAnnotationNoteDialog(PdfAnnotation annotation) {
    PdfQuickNoteBubble.showAsDialog(
      context: context,
      initialNote: annotation.linkedNote ?? '',
      onSave: (note) {
        if (note.isNotEmpty) {
          // Update the annotation's linked note
          final index = _annotations.indexWhere((a) => a.id == annotation.id);
          if (index != -1) {
            setState(() {
              _annotations[index] = _annotations[index].copyWith(
                linkedNote: note,
              );
            });
            // Save updated annotation to local/Supabase
            _saveAnnotationToLocal(_annotations[index]);
            
            // Also add to quick notes list if not already there
            final existingNoteIndex = _quickNotes.indexWhere(
              (n) => n['annotationId'] == annotation.id
            );
            if (existingNoteIndex == -1) {
              _quickNotes.add({
                'id': DateTime.now().millisecondsSinceEpoch,
                'note': note,
                'page': annotation.pageNumber,
                'timestamp': DateTime.now().toIso8601String(),
                'annotationId': annotation.id,
              });
            } else {
              _quickNotes[existingNoteIndex]['note'] = note;
              _quickNotes[existingNoteIndex]['timestamp'] = DateTime.now().toIso8601String();
            }
          }
          print('📝 Note updated for annotation ${annotation.id}: $note');
        }
      },
      onDelete: () {
        // Remove the note from annotation
        final index = _annotations.indexWhere((a) => a.id == annotation.id);
        if (index != -1) {
          setState(() {
            _annotations[index] = _annotations[index].copyWith(
              linkedNote: null,
            );
          });
          // Remove from quick notes list
          _quickNotes.removeWhere((n) => n['annotationId'] == annotation.id);
          print('🗑️ Note deleted for annotation ${annotation.id}');
        }
      },
    );
  }
  
  // Build compact annotation comment popup (modern minimal design)
  Widget _buildAnnotationCommentPopup(PdfAnnotation annotation) {
    final hasNote = annotation.linkedNote != null && annotation.linkedNote!.isNotEmpty;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 42.w, minWidth: 25.w),
        decoration: BoxDecoration(
          color: _isDarkMode 
              ? AppTheme.surfaceColor.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
              decoration: BoxDecoration(
                color: annotation.color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: annotation.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    _getAnnotationTypeName(annotation.type),
                    style: AppTheme.dataTextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? AppTheme.textPrimary : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnnotationId = null;
                        _annotationCommentPosition = null;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(0.5.w),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: _isDarkMode ? AppTheme.textSecondary : Colors.black45,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Compact note content or add note button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: hasNote
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            annotation.linkedNote!,
                            style: AppTheme.dataTextStyle(
                              fontSize: 9.sp,
                              color: _isDarkMode ? AppTheme.textPrimary : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAnnotationId = null;
                              _annotationCommentPosition = null;
                            });
                            _showAnnotationNoteDialog(annotation);
                          },
                          child: Container(
                            padding: EdgeInsets.all(1.w),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CustomIconWidget(
                              iconName: 'edit',
                              color: AppTheme.accentColor,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAnnotationId = null;
                          _annotationCommentPosition = null;
                        });
                        _showAnnotationNoteDialog(annotation);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.accentColor,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Add note',
                            style: AppTheme.dataTextStyle(
                              fontSize: 9.sp,
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getAnnotationIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.highlight:
      case AnnotationType.textHighlight:
        return 'highlight';
      case AnnotationType.underline:
        return 'format_underlined';
      case AnnotationType.drawing:
        return 'draw';
      case AnnotationType.text:
        return 'text_fields';
      case AnnotationType.eraser:
        return 'auto_fix_off';
    }
  }
  
  String _getAnnotationTypeName(AnnotationType type) {
    switch (type) {
      case AnnotationType.highlight:
        return 'Highlight';
      case AnnotationType.textHighlight:
        return 'Text Highlight';
      case AnnotationType.underline:
        return 'Underline';
      case AnnotationType.drawing:
        return 'Drawing';
      case AnnotationType.text:
        return 'Text';
      case AnnotationType.eraser:
        return 'Eraser';
    }
  }
  
  // Get short tool name for indicator
  String _getToolName(AnnotationType? tool) {
    if (tool == null) return 'None';
    switch (tool) {
      case AnnotationType.highlight:
        return 'Highlight';
      case AnnotationType.textHighlight:
        return 'Text HL';
      case AnnotationType.underline:
        return 'Underline';
      case AnnotationType.drawing:
        return 'Draw';
      case AnnotationType.text:
        return 'Text';
      case AnnotationType.eraser:
        return 'Eraser';
    }
  }

  void _handlePageNavigation(int page) {
    if (_totalPages == 0) return;
    // Clamp page to valid range
    final targetPage = page.clamp(1, _totalPages);
    if (targetPage == _currentPage) return;
    
    try {
      if (_pdfViewerController.isReady) {
        _pdfViewerController.goToPage(pageNumber: targetPage);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      print('❌ Page navigation error: $e');
    }
  }
  
  // Erase annotations at a given point
  void _eraseAtPoint(Offset point, int pageNumber, Size pageSize) {
    // Convert eraser position to normalized coordinates
    final normalizedPoint = PdfAnnotation.toNormalizedPoint(point, pageSize);
    // Normalize eraser radius relative to page size (use average of width/height)
    final normalizedRadius = 20.0 / ((pageSize.width + pageSize.height) / 2);
    
    // Collect annotations to remove
    final toRemove = _annotations.where((annotation) {
      if (annotation.pageNumber != pageNumber) return false;
      
      // Check if any normalized point of the annotation is within eraser radius
      for (final p in annotation.points) {
        if ((p - normalizedPoint).distance < normalizedRadius) {
          return true;
        }
      }
      return false;
    }).toList();
    
    // Remove from UI and database
    if (toRemove.isNotEmpty) {
      setState(() {
        for (final annotation in toRemove) {
          _annotations.remove(annotation);
          // Delete from database/storage
          _annotationService.deleteAnnotation(annotation.id);
        }
      });
      HapticFeedback.lightImpact();
    }
  }

  void _handleZoomChange(double zoom) {
    final newZoom = zoom.clamp(0.5, 3.0);
    setState(() {
      _zoomLevel = newZoom;
    });
    _pdfViewerController.setZoom(_pdfViewerController.centerPosition, newZoom);
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    if (query.isNotEmpty && _textSearcher != null) {
      _textSearcher!.startTextSearch(query, caseInsensitive: true);
    } else {
      setState(() {
        _totalSearchMatches = 0;
        _currentSearchMatch = 0;
      });
      _textSearcher?.resetTextSearch();
    }
  }

  void _navigateSearchMatch(bool next) {
    if (_totalSearchMatches > 0 && _textSearcher != null) {
      if (next) {
        _textSearcher!.goToNextMatch();
        setState(() {
          _currentSearchMatch = (_textSearcher!.currentIndex ?? 0) + 1;
        });
      } else {
        _textSearcher!.goToPrevMatch();
        setState(() {
          _currentSearchMatch = (_textSearcher!.currentIndex ?? 0) + 1;
        });
      }
    }
  }
  
  // Get rectangles for search matches on a page
  Future<List<List<PdfRect>>> _getSearchMatchRects(
    PdfPage page,
    List<PdfPageTextRange> matches,
  ) async {
    final result = <List<PdfRect>>[];
    try {
      for (final match in matches) {
        // Each match has pageText with charRects for the characters
        // Get rects from start to end index
        final rects = <PdfRect>[];
        final charRects = match.pageText.charRects;
        for (int i = match.start; i < match.end && i < charRects.length; i++) {
          rects.add(charRects[i]);
        }
        if (rects.isNotEmpty) {
          // Merge adjacent rects into lines
          result.add(_mergeRectsIntoLines(rects));
        }
      }
    } catch (e) {
      print('❌ Error getting search match rects: $e');
    }
    return result;
  }
  
  // Merge adjacent character rects into line rects
  List<PdfRect> _mergeRectsIntoLines(List<PdfRect> charRects) {
    if (charRects.isEmpty) return [];
    
    final lines = <PdfRect>[];
    var currentLine = charRects.first;
    
    for (int i = 1; i < charRects.length; i++) {
      final rect = charRects[i];
      // Check if on same line (similar y position)
      if ((rect.top - currentLine.top).abs() < (currentLine.bottom - currentLine.top) * 0.5) {
        // Same line - extend current rect
        currentLine = PdfRect(
          currentLine.left,
          currentLine.top,
          rect.right,
          currentLine.bottom,
        );
      } else {
        // New line
        lines.add(currentLine);
        currentLine = rect;
      }
    }
    lines.add(currentLine);
    return lines;
  }
  
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _addBookmark(Map<String, dynamic> bookmark) {
    setState(() {
      _bookmarks.add({
        ...bookmark,
        'page': _currentPage,
      });
    });
    HapticFeedback.lightImpact();
  }

  void _editBookmark(Map<String, dynamic> bookmark) {
    final index = _bookmarks.indexWhere((b) => b['id'] == bookmark['id']);
    if (index != -1) {
      setState(() {
        _bookmarks[index] = bookmark;
      });
    }
  }

  void _deleteBookmark(Map<String, dynamic> bookmark) {
    setState(() {
      _bookmarks.removeWhere((b) => b['id'] == bookmark['id']);
    });
    HapticFeedback.lightImpact();
  }

  void _addQuickNote(Offset position) {
    final note = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'position': position,
      'note': '',
      'page': _currentPage,
      'isEditing': true,
    };
    
    setState(() {
      _quickNotes.add(note);
    });
  }

  void _updateQuickNote(int id, String note) {
    final index = _quickNotes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      setState(() {
        _quickNotes[index]['note'] = note;
        _quickNotes[index]['isEditing'] = false;
      });
    }
  }

  void _deleteQuickNote(int id) {
    setState(() {
      _quickNotes.removeWhere((n) => n['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Stack(
          children: [
            // PDF Content Area
            GestureDetector(
              // Always allow tap to toggle controls (tool stays active via _toggleControls logic)
              onTap: _toggleControls,
              onDoubleTap: _isToolActive ? null : () {
                _handleZoomChange(_zoomLevel == 1.0 ? 2.0 : 1.0);
              },
              onLongPress: _isToolActive ? null : () {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final position = renderBox.globalToLocal(
                  Offset(50.w, 30.h),
                );
                _addQuickNote(position);
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: _buildPdfContent(),
              ),
            ),
            
            // Top overlay with document info - ALWAYS VISIBLE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopOverlay(),
            ),
            
            // Annotation toolbar
            if (_showAnnotationToolbar)
              Positioned(
                bottom: 18.h,
                left: 0,
                right: 0,
                child: PdfAnnotationToolbar(
                  selectedText: _isToolActive ? (_currentTool == AnnotationType.eraser ? 'Tap annotations to erase' : 'Drag to annotate') : _selectedText,
                  selectedColor: _selectedAnnotationColor,
                  activeTool: _currentTool,
                  useTextHighlight: _useTextHighlight,
                  onHighlightModeChanged: (useText) {
                    setState(() {
                      _useTextHighlight = useText;
                    });
                  },
                  onColorChanged: (color) {
                    setState(() {
                      _selectedAnnotationColor = color;
                    });
                    // Update current annotation color if one is being created
                    if (_currentAnnotationId != null) {
                      final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
                      if (index != -1) {
                        _annotations[index] = _annotations[index].copyWith(
                          color: _currentTool == AnnotationType.highlight 
                              ? color.withValues(alpha: 0.4) 
                              : color,
                        );
                      }
                    }
                  },
                  onHighlight: () => _selectTool(AnnotationType.highlight),
                  onTextHighlight: () => _selectTool(AnnotationType.textHighlight),
                  onUnderline: () => _selectTool(AnnotationType.underline),
                  onDraw: () => _selectTool(AnnotationType.drawing),
                  onEraser: () => _selectTool(AnnotationType.eraser),
                  onNote: () {
                    _closeAllOverlays();
                    _showQuickNoteDialog();
                  },
                  onClose: () {
                    _deactivateTool();
                    setState(() => _showAnnotationToolbar = false);
                    // Clear any text selection
                    try {
                      _pdfViewerController.textSelectionDelegate.clearTextSelection();
                    } catch (_) {}
                  },
                ),
              ),
            
            // Floating tool indicator (when tool is active but toolbar is hidden)
            if (_isToolActive && !_showAnnotationToolbar)
              Positioned(
                bottom: 3.h,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAnnotationToolbar = true;
                      });
                      HapticFeedback.lightImpact();
                    },
                    onLongPress: () {
                      // Long press to deactivate tool
                      _deactivateTool();
                      HapticFeedback.mediumImpact();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.accentColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _selectedAnnotationColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.5.w),
                          Text(
                            _getToolName(_currentTool),
                            style: AppTheme.dataTextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          CustomIconWidget(
                            iconName: 'expand_less',
                            color: AppTheme.textSecondary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            // Responsive floating navbar with pencil toggle button
            _buildResponsiveFloatingNavbar(),
            
            // Search overlay
            PdfSearchOverlay(
              isVisible: _showSearchOverlay,
              searchQuery: _searchQuery,
              currentMatch: _currentSearchMatch,
              totalMatches: _totalSearchMatches,
              onSearchChanged: _handleSearch,
              onPreviousMatch: () => _navigateSearchMatch(false),
              onNextMatch: () => _navigateSearchMatch(true),
              onClose: () => setState(() => _showSearchOverlay = false),
            ),
            
            // Bookmark panel
            PdfBookmarkPanel(
              isVisible: _showBookmarkPanel,
              bookmarks: _bookmarks,
              onBookmarkTap: (page) {
                _handlePageNavigation(page);
                setState(() => _showBookmarkPanel = false);
              },
              onBookmarkAdd: _addBookmark,
              onBookmarkEdit: _editBookmark,
              onBookmarkDelete: _deleteBookmark,
              onClose: () => setState(() => _showBookmarkPanel = false),
            ),
            
            // Notes panel
            if (_showNotesPanel)
              _buildNotesPanel(),
          ],
        ),
      ),
    );
  }
  
  // Build notes panel to show saved notes
  Widget _buildNotesPanel() {
    return Positioned(
      top: 12.h,
      left: 3.w,
      right: 3.w,
      bottom: 12.h,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Compact Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'note',
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Notes (${_quickNotes.length})',
                      style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _showNotesPanel = false);
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            
            // Notes list
            Expanded(
              child: _quickNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'note_add',
                            color: AppTheme.textSecondary,
                            size: 40,
                          ),
                          SizedBox(height: 1.5.h),
                          Text(
                            'No notes yet',
                            style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Tap on annotations or use the note tool to add notes',
                            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(2.w),
                      itemCount: _quickNotes.length,
                      itemBuilder: (context, index) {
                        final note = _quickNotes[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _showNotesPanel = false;
                            });
                            // If note has linked annotation, navigate and show comment
                            if (note['annotationId'] != null) {
                              _navigateToAnnotation(note['annotationId']);
                            } else {
                              // Just navigate to page
                              _handlePageNavigation(note['page'] ?? 1);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 1.5.w),
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'P${note['page'] ?? '?'}',
                                        style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9.sp,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        // Delete note
                                        setState(() {
                                          _quickNotes.removeAt(index);
                                        });
                                        HapticFeedback.mediumImpact();
                                      },
                                      child: CustomIconWidget(
                                        iconName: 'delete',
                                        color: AppTheme.errorColor,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 0.6.h),
                                Text(
                                  note['note'] ?? '',
                                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (note['annotationId'] != null) ...[
                                  SizedBox(height: 0.3.h),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        'Linked',
                                        style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 8.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Compact add note button
            Padding(
              padding: EdgeInsets.all(2.5.w),
              child: GestureDetector(
                onTap: () {
                  setState(() => _showNotesPanel = false);
                  _showQuickNoteDialog();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'add',
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        'Add Note',
                        style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build floating navbar - matches image design
  Widget _buildResponsiveFloatingNavbar() {
    return Stack(
      children: [
        // Slide-out zoom controls at top-right
        Positioned(
          top: 25.h,
          right: 0,
          child: _buildSlideOutZoomControls(),
        ),
        
        // Page indicator - auto-fading
        Positioned(
          bottom: _showFloatingNavbar ? 9.h : 2.h,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _showPageIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: () {
                  // Tapping shows/resets the timer
                  _startPageIndicatorTimer();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Page $_currentPage of $_totalPages',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Main horizontal navbar at bottom center
        if (_showFloatingNavbar)
          Positioned(
            bottom: 2.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavbarButton(
                      icon: 'bookmark',
                      isActive: _showBookmarkPanel,
                      onTap: () {
                        setState(() {
                          _showSearchOverlay = false;
                          _showAnnotationToolbar = false;
                          _showNotesPanel = false;
                          _isToolActive = false;
                          _showBookmarkPanel = !_showBookmarkPanel;
                        });
                      },
                    ),
                    SizedBox(width: 1.5.w),
                    _buildNavbarButton(
                      icon: 'note',
                      isActive: _showNotesPanel,
                      onTap: () {
                        setState(() {
                          _showSearchOverlay = false;
                          _showAnnotationToolbar = false;
                          _showBookmarkPanel = false;
                          _isToolActive = false;
                          _showNotesPanel = !_showNotesPanel;
                        });
                      },
                    ),
                    SizedBox(width: 1.5.w),
                    _buildNavbarButton(
                      icon: 'search',
                      isActive: _showSearchOverlay,
                      onTap: () {
                        setState(() {
                          _showBookmarkPanel = false;
                          _showAnnotationToolbar = false;
                          _showNotesPanel = false;
                          _isToolActive = false;
                          _showSearchOverlay = !_showSearchOverlay;
                        });
                      },
                    ),
                    SizedBox(width: 1.5.w),
                    _buildNavbarButton(
                      icon: 'edit',
                      isActive: _showAnnotationToolbar,
                      onTap: () {
                        setState(() {
                          _showBookmarkPanel = false;
                          _showSearchOverlay = false;
                          _showNotesPanel = false;
                          _showAnnotationToolbar = !_showAnnotationToolbar;
                          if (_showAnnotationToolbar) {
                            _currentTool = AnnotationType.drawing;
                          } else {
                            _isToolActive = false;
                          }
                        });
                      },
                    ),
                    SizedBox(width: 1.5.w),
                    _buildNavbarButton(
                      icon: _isDarkMode ? 'light_mode' : 'dark_mode',
                      onTap: _toggleDarkMode,
                    ),
                    SizedBox(width: 1.5.w),
                    _buildNavbarButton(
                      icon: 'chevron_left',
                      onTap: () => _handlePageNavigation(_currentPage - 1),
                    ),
                    SizedBox(width: 1.5.w),
                    _buildNavbarButton(
                      icon: 'chevron_right',
                      onTap: () => _handlePageNavigation(_currentPage + 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Compact floating toggle button
        Positioned(
          bottom: 11.h,
          right: 3.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showFloatingNavbar = !_showFloatingNavbar;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.all(2.8.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomIconWidget(
                iconName: _showFloatingNavbar ? 'expand_more' : 'menu',
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Build slim slide-out zoom controls (Android-style minimal sidebar)
  Widget _buildSlideOutZoomControls() {
    // Calculate the width of the zoom panel (without handle)
    final panelWidth = 42.0; // Approximate width of zoom controls
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visible slide handle - ALWAYS visible, never moves
        GestureDetector(
          onTap: () {
            setState(() {
              _showZoomControls = !_showZoomControls;
            });
            HapticFeedback.lightImpact();
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 0) {
                setState(() => _showZoomControls = false);
              } else {
                setState(() => _showZoomControls = true);
              }
            }
          },
          child: Container(
            width: 8,
            height: 55,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Animated zoom controls panel - slides in/out
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _showZoomControls ? panelWidth : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _showZoomControls ? 1.0 : 0.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                width: panelWidth,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(-1, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pan/cursor mode button (toggle)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _togglePanMode();
                      },
                      child: Container(
                    padding: EdgeInsets.all(1.8.w),
                    decoration: BoxDecoration(
                      color: _isPanMode ? AppTheme.accentColor.withValues(alpha: 0.25) : Colors.transparent,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(11)),
                    ),
                    child: CustomIconWidget(
                      iconName: 'pan_tool',
                      color: _isPanMode ? AppTheme.accentColor : AppTheme.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleZoomChange((_zoomLevel + 0.25).clamp(0.5, 4.0));
                  },
                  child: Container(
                    padding: EdgeInsets.all(1.8.w),
                    child: CustomIconWidget(
                      iconName: 'add',
                      color: AppTheme.textPrimary,
                      size: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                  child: Text(
                    '${(_zoomLevel * 100).round()}',
                    style: AppTheme.dataTextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleZoomChange((_zoomLevel - 0.25).clamp(0.5, 4.0));
                  },
                  child: Container(
                    padding: EdgeInsets.all(1.8.w),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(11)),
                    ),
                    child: CustomIconWidget(
                      iconName: 'remove',
                      color: AppTheme.textPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Legacy zoom controls (kept for reference)
  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pan/cursor mode button (toggle)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _togglePanMode();
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _isPanMode ? AppTheme.accentColor.withValues(alpha: 0.3) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: CustomIconWidget(
                iconName: 'pan_tool',
                color: _isPanMode ? AppTheme.accentColor : AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 30,
            height: 1,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _handleZoomChange((_zoomLevel + 0.25).clamp(0.5, 4.0));
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'zoom_in',
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            child: Text(
              '${(_zoomLevel * 100).round()}%',
              style: AppTheme.dataTextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _handleZoomChange((_zoomLevel - 0.25).clamp(0.5, 4.0));
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'zoom_out',
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build floating action button (for zoom controls)
  Widget _buildFloatingButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientDecoration().gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: AppTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }
  
  // Build individual navbar button (compact design)
  Widget _buildNavbarButton({
    required String icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    // Ensure icons are visible in dark mode by using white color
    final iconColor = isActive 
        ? AppTheme.accentColor 
        : (_isDarkMode ? Colors.white : AppTheme.textPrimary);
    
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.accentColor.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    if (_document == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark.withValues(alpha: 0.9),
            AppTheme.primaryDark.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _document!.title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(_document!.readingProgress * 100).round()}% complete',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Save button - always visible
              GestureDetector(
                onTap: _saveAndClose,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  margin: EdgeInsets.only(right: 2.w),
                  decoration: BoxDecoration(
                    gradient: (_hasUnsavedAnnotations || _annotations.isNotEmpty)
                        ? AppTheme.gradientDecoration().gradient
                        : null,
                    color: (_hasUnsavedAnnotations || _annotations.isNotEmpty)
                        ? null
                        : AppTheme.surfaceColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'save',
                        color: (_hasUnsavedAnnotations || _annotations.isNotEmpty)
                            ? Colors.white
                            : AppTheme.textPrimary,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Save',
                        style: TextStyle(
                          color: (_hasUnsavedAnnotations || _annotations.isNotEmpty)
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'more_vert',
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading PDF...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPdf,
                child: const Text('Retry'),
              ),
              if (kIsWeb && _document != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    html.window.open(_document!.filePath, '_blank');
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in New Tab'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_pdfBytes != null) {
      Widget viewer = PdfViewer.data(
        _pdfBytes!,
        sourceName: _document?.title ?? 'document.pdf',
        controller: _pdfViewerController,
          params: PdfViewerParams(
          layoutPages: _scrollDirection == Axis.horizontal
              ? (pages, params) {
                  // Horizontal layout - pages side by side
                  final height = pages.fold(0.0, (prev, page) => prev > page.height ? prev : page.height) + params.margin * 2;
                  final pageLayouts = <Rect>[];
                  double x = params.margin;
                  for (final page in pages) {
                    pageLayouts.add(
                      Rect.fromLTWH(
                        x,
                        (height - page.height) / 2, // center vertically
                        page.width,
                        page.height,
                      ),
                    );
                    x += page.width + params.margin;
                  }
                  return PdfPageLayout(pageLayouts: pageLayouts, documentSize: Size(x, height));
                }
              : null, // null = default vertical layout
          panEnabled: _isPanMode || !_isToolActive, // Enable pan in pan mode or when no tool active
          scaleEnabled: _isPanMode || !_isToolActive, // Enable scale in pan mode or when no tool active
          textSelectionParams: PdfTextSelectionParams(
            enabled: !_isToolActive && !_isPanMode,
            onTextSelectionChange: (selection) {
              print('🔍 Text selection callback triggered!');
              _handleTextSelectionChange(selection);
            },
          ),
          onGeneralTap: (context, controller, details) {
            print('👆 General tap: ${details.type} at ${details.localPosition}');
            return false; // Don't consume the event
          },
          pageOverlaysBuilder: (context, pageRect, page) {
            return [_buildPageOverlay(context, pageRect, page)];
          },
          onViewerReady: (document, controller) {
            print('✅ PDF Loaded. Pages: ${document.pages.length}');
            setState(() {
               _totalPages = document.pages.length;
            });
            
            // Update page count in database if not set
            if (_document != null && (_document!.pageCount == null || _document!.pageCount == 0)) {
              _documentService.updateReadingProgress(
                _document!.id,
                _document!.readingProgress,
                _document!.lastPage,
                pageCount: document.pages.length,
              );
            }
            
            // Resume from last page if available
            if (_document != null && _document!.lastPage > 1 && _document!.lastPage <= document.pages.length) {
              Future.microtask(() {
                if (controller.isReady) {
                  controller.goToPage(pageNumber: _document!.lastPage);
                  print('📖 Resuming from page ${_document!.lastPage}');
                }
              });
            }
            
            // Initialize searcher after a frame to ensure controller is ready
            Future.microtask(() {
              if (mounted && controller.isReady) {
                try {
                  _textSearcher = PdfTextSearcher(controller)..addListener(() {
                    if (mounted) {
                      setState(() {
                        _totalSearchMatches = _textSearcher!.matches.length;
                        _currentSearchMatch = (_textSearcher!.currentIndex ?? -1) + 1;
                      });
                    }
                  });
                } catch (e) {
                  print('❌ Failed to initialize PdfTextSearcher: $e');
                }
              }
            });
          },
          onPageChanged: (pageNumber) {
            setState(() {
              _currentPage = pageNumber ?? 1;
            });
            _startPageIndicatorTimer(); // Show and auto-fade page indicator
            
            // Update reading progress
            if (pageNumber != null) {
              _updateReadingProgress(pageNumber);
            }
          },
          errorBannerBuilder: (context, error, stackTrace, documentRef) {
             print('❌ PDF Load Failed: $error');
             return Center(
               child: Text('Error opening PDF: $error'),
             );
          },
        ),
      );

      if (_isDarkMode) {
        // High-quality dark mode with color matrix filter
        // Creates soft dark grey background (easier on eyes than pure black)
        // Preserves annotation colors better than BlendMode.difference
        const ColorFilter darkModeFilter = ColorFilter.matrix([
          -0.8, 0, 0, 0, 255, // Red channel - inverted with grey background
          0, -0.8, 0, 0, 255, // Green channel - inverted with grey background
          0, 0, -0.8, 0, 255, // Blue channel - inverted with grey background
          0, 0, 0, 1, 0,      // Alpha channel - unchanged
        ]);

        viewer = ColorFiltered(
          colorFilter: darkModeFilter,
          child: viewer,
        );
      }
      
      return viewer;
    }

    return const Center(child: Text('No document loaded'));
  }

  Widget _buildPageOverlay(BuildContext context, Rect pageRect, PdfPage page) {
    final pageAnnotations = _annotations.where((a) => a.pageNumber == page.pageNumber).toList();
    
    // Find selected annotation for this page
    final selectedAnnotation = _selectedAnnotationId != null
        ? pageAnnotations.where((a) => a.id == _selectedAnnotationId).firstOrNull
        : null;
    
    // Get search matches for this page
    final searchMatches = _textSearcher?.matches
        .where((m) => m.pageNumber == page.pageNumber)
        .toList() ?? [];
    final currentMatchIndex = _textSearcher?.currentIndex;
    
    return Stack(
      children: [
        // Search results highlighting layer
        if (searchMatches.isNotEmpty)
          FutureBuilder<List<List<PdfRect>>>(
            future: _getSearchMatchRects(page, searchMatches),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final matchRects = snapshot.data!;
              return CustomPaint(
                size: pageRect.size,
                painter: SearchHighlightPainter(
                  matchRects: matchRects,
                  pageRect: pageRect,
                  page: page,
                  currentMatchIndex: currentMatchIndex,
                  searchMatches: searchMatches,
                  totalMatches: _textSearcher?.matches ?? [],
                ),
              );
            },
          ),
        
        // Render existing annotations - pan mode uses IgnorePointer to allow PDF pan/zoom
        // When not in pan mode, allow taps for annotation selection
        _isPanMode 
          ? IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return CustomPaint(
                    size: pageRect.size,
                    painter: AnnotationPainter(
                      annotations: pageAnnotations, 
                      scale: 1.0, 
                      page: page, 
                      pageRect: pageRect,
                      selectedAnnotationId: _selectedAnnotationId,
                    ),
                  );
                },
              ),
            )
          : LayoutBuilder(
          builder: (context, constraints) {
            final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _isToolActive ? null : (details) {
                // Allow taps for annotation selection
                  
                  final tapPos = details.localPosition;
                  final normalizedTapPos = PdfAnnotation.toNormalizedPoint(tapPos, pageSize);
                  final hitRadius = 0.03; // 3% of page size for easier tapping
                  
                  for (final annotation in pageAnnotations) {
                    // Check if any point is near the tap
                    for (final point in annotation.points) {
                      if ((point - normalizedTapPos).distance < hitRadius) {
                        // Found annotation - select it and show comment
                        final scaledPoint = PdfAnnotation.toWidgetPoint(point, pageSize);
                        setState(() {
                          _selectedAnnotationId = annotation.id;
                          _annotationCommentPosition = Offset(
                            scaledPoint.dx,
                            scaledPoint.dy - 50, // Position above the annotation
                          );
                        });
                        HapticFeedback.selectionClick();
                        return;
                      }
                    }
                  }
                  
                  // Tapped empty area - clear selection
                if (_selectedAnnotationId != null) {
                  setState(() {
                    _selectedAnnotationId = null;
                    _annotationCommentPosition = null;
                  });
                }
              },
              child: CustomPaint(
                size: pageRect.size,
                painter: AnnotationPainter(
                  annotations: pageAnnotations, 
                  scale: 1.0, 
                  page: page, 
                  pageRect: pageRect,
                  selectedAnnotationId: _selectedAnnotationId,
                ),
              ),
            );
          },
        ),
        
        // Show comment popup for selected annotation
        if (selectedAnnotation != null && _annotationCommentPosition != null)
          Positioned(
            left: _annotationCommentPosition!.dx.clamp(10, pageRect.width - 200),
            top: _annotationCommentPosition!.dy.clamp(10, pageRect.height - 100),
            child: _buildAnnotationCommentPopup(selectedAnnotation),
          ),
        
        // Drawing layer (if drawing tool is active)
        if (_currentTool == AnnotationType.drawing && _isToolActive)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    final localPos = details.localPosition;
                    final normalizedPos = PdfAnnotation.toNormalizedPoint(localPos, pageSize);
                    print('🖊️ Draw start at local: $localPos, normalized: $normalizedPos');
                    setState(() {
                      _isDrawing = true;
                      _currentDrawingAnnotationId = DateTime.now().millisecondsSinceEpoch.toString();
                      _annotations.add(PdfAnnotation(
                        id: _currentDrawingAnnotationId!,
                        pageNumber: page.pageNumber,
                        type: AnnotationType.drawing,
                        color: _selectedAnnotationColor,
                        points: [normalizedPos],
                        textRanges: [],
                        originalPageSize: pageSize,
                      ));

                    });
                  },
                  onPanUpdate: (details) {
                    if (_isDrawing && _currentDrawingAnnotationId != null) {
                      final localPos = details.localPosition;
                      final normalizedPos = PdfAnnotation.toNormalizedPoint(localPos, pageSize);
                      final index = _annotations.indexWhere((a) => a.id == _currentDrawingAnnotationId);
                      if (index != -1) {
                        setState(() {
                          _annotations[index] = _annotations[index].copyWith(
                            points: [..._annotations[index].points, normalizedPos],
                          );
                        });
                      }
                    }
                  },
                  onPanEnd: (details) {
                    print('🖊️ Draw end');
                    
                    // Save the drawing annotation
                    if (_currentDrawingAnnotationId != null) {
                      final index = _annotations.indexWhere((a) => a.id == _currentDrawingAnnotationId);
                      if (index != -1 && _annotations[index].points.isNotEmpty) {
                        _saveAnnotationToLocal(_annotations[index]);
                      }
                    }
                    
                    setState(() {
                      _isDrawing = false;
                      _currentDrawingAnnotationId = null;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(color: Colors.transparent),
                );
              },
            ),
          ),
          
        // Highlight layer - paint style (continuous stroke as you drag)
        if (_currentTool == AnnotationType.highlight && _isToolActive)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    final localPos = details.localPosition;
                    final normalizedPos = PdfAnnotation.toNormalizedPoint(localPos, pageSize);
                    print('📝 Paint-style highlight start at: $localPos, normalized: $normalizedPos');
                    
                    // Create annotation with initial point
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    setState(() {
                      _isAnnotating = true;
                      _currentAnnotationId = id;
                      _annotationStartOffset = localPos;
                      _annotations.add(PdfAnnotation(
                        id: id,
                        pageNumber: page.pageNumber,
                        type: AnnotationType.highlight,
                        color: _selectedAnnotationColor.withValues(alpha: 0.4),
                        points: [normalizedPos],
                        textRanges: [],
                        originalPageSize: pageSize,
                      ));
                    });
                  },
                  onPanUpdate: (details) {
                    if (_isAnnotating && _currentAnnotationId != null) {
                      final localPos = details.localPosition;
                      final normalizedPos = PdfAnnotation.toNormalizedPoint(localPos, pageSize);
                      final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
                      if (index != -1) {
                        setState(() {
                          _annotations[index] = _annotations[index].copyWith(
                            points: [..._annotations[index].points, normalizedPos],
                          );
                        });
                      }
                    }
                  },
                  onPanEnd: (details) {
                    print('📝 Highlight end');
                    
                    // Save the highlight annotation
                    if (_currentAnnotationId != null) {
                      final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
                      if (index != -1 && _annotations[index].points.isNotEmpty) {
                        _saveAnnotationToLocal(_annotations[index]);
                      }
                    }
                    
                    setState(() {
                      _isAnnotating = false;
                      _currentAnnotationId = null;
                      _annotationStartOffset = null;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(color: Colors.transparent),
                );
              },
            ),
          ),
          
        // Text Highlight layer - text detection (like underline but fills text background)
        if (_currentTool == AnnotationType.textHighlight && _isToolActive)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) async {
                    final localPos = details.localPosition;
                    print('📝 Text highlight start at: $localPos');
                    
                    // Load page text for detection
                    await _loadPageText(page.pageNumber);
                    _detectedTextRects = [];
                    
                    // Create annotation
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    setState(() {
                      _isAnnotating = true;
                      _currentAnnotationId = id;
                      _annotationStartOffset = localPos;
                      _annotations.add(PdfAnnotation(
                        id: id,
                        pageNumber: page.pageNumber,
                        type: AnnotationType.textHighlight,
                        color: _selectedAnnotationColor.withValues(alpha: 0.4),
                        points: [],
                        textRanges: [],
                        originalPageSize: pageSize,
                      ));
                    });
                    
                    // Check for text at start position
                    _detectTextAtPosition(localPos, page.pageNumber, pageSize);
                  },
                  onPanUpdate: (details) {
                    if (_isAnnotating && _currentAnnotationId != null) {
                      final localPos = details.localPosition;
                      _detectTextAtPosition(localPos, page.pageNumber, pageSize);
                    }
                  },
                  onPanEnd: (details) {
                    print('📝 Text highlight end - detected ${_detectedTextRects.length} text regions');
                    
                    // Store detected text rectangles as normalized highlight rectangles
                    if (_currentAnnotationId != null && _detectedTextRects.isNotEmpty) {
                      final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
                      if (index != -1) {
                        // Convert detected rects to normalized highlight points (all 4 corners)
                        final highlightPoints = <Offset>[];
                        for (final rect in _detectedTextRects) {
                          // Store all 4 corners of each rect for proper highlighting
                          highlightPoints.add(PdfAnnotation.toNormalizedPoint(
                            rect.topLeft, pageSize));
                          highlightPoints.add(PdfAnnotation.toNormalizedPoint(
                            rect.topRight, pageSize));
                          highlightPoints.add(PdfAnnotation.toNormalizedPoint(
                            rect.bottomRight, pageSize));
                          highlightPoints.add(PdfAnnotation.toNormalizedPoint(
                            rect.bottomLeft, pageSize));
                        }
                        setState(() {
                          _annotations[index] = _annotations[index].copyWith(
                            points: highlightPoints,
                          );
                        });
                        
                        // Save to annotation service for sync
                        if (highlightPoints.isNotEmpty) {
                          _saveAnnotationToLocal(_annotations[index]);
                        }
                      }
                    }
                    
                    setState(() {
                      _isAnnotating = false;
                      _currentAnnotationId = null;
                      _annotationStartOffset = null;
                      _detectedTextRects = [];
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(color: Colors.transparent),
                );
              },
            ),
          ),
          
        // Underline layer - text detection (detects text as you drag)
        if (_currentTool == AnnotationType.underline && _isToolActive)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) async {
                    final localPos = details.localPosition;
                    print('📝 Underline start at: $localPos');
                    
                    // Load page text for detection
                    await _loadPageText(page.pageNumber);
                    _detectedTextRects = [];
                    
                    // Create annotation
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    setState(() {
                      _isAnnotating = true;
                      _currentAnnotationId = id;
                      _annotationStartOffset = localPos;
                      _annotations.add(PdfAnnotation(
                        id: id,
                        pageNumber: page.pageNumber,
                        type: AnnotationType.underline,
                        color: _selectedAnnotationColor,
                        points: [],
                        textRanges: [],
                        originalPageSize: pageSize,
                      ));
                    });
                    
                    // Check for text at start position
                    _detectTextAtPosition(localPos, page.pageNumber, pageSize);
                  },
                  onPanUpdate: (details) {
                    if (_isAnnotating && _currentAnnotationId != null) {
                      final localPos = details.localPosition;
                      _detectTextAtPosition(localPos, page.pageNumber, pageSize);
                    }
                  },
                  onPanEnd: (details) {
                    print('📝 Underline end - detected ${_detectedTextRects.length} text regions');
                    
                    // Store detected text rectangles as normalized underline points
                    if (_currentAnnotationId != null && _detectedTextRects.isNotEmpty) {
                      final index = _annotations.indexWhere((a) => a.id == _currentAnnotationId);
                      if (index != -1) {
                        // Convert detected rects to normalized underline points (bottom edge of each rect)
                        final underlinePoints = <Offset>[];
                        for (final rect in _detectedTextRects) {
                          // Normalize coordinates (0-1 range)
                          underlinePoints.add(PdfAnnotation.toNormalizedPoint(
                            Offset(rect.left, rect.bottom + 2), pageSize));
                          underlinePoints.add(PdfAnnotation.toNormalizedPoint(
                            Offset(rect.right, rect.bottom + 2), pageSize));
                        }
                        setState(() {
                          _annotations[index] = _annotations[index].copyWith(
                            points: underlinePoints,
                          );
                        });
                        
                        // Save to annotation service for sync
                        if (underlinePoints.isNotEmpty) {
                          _saveAnnotationToLocal(_annotations[index]);
                        }
                      }
                    }
                    
                    setState(() {
                      _isAnnotating = false;
                      _currentAnnotationId = null;
                      _annotationStartOffset = null;
                      _detectedTextRects = [];
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(color: Colors.transparent),
                );
              },
            ),
          ),
          
        // Eraser layer
        if (_currentTool == AnnotationType.eraser && _isToolActive)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    _eraseAtPoint(details.localPosition, page.pageNumber, pageSize);
                  },
                  onPanUpdate: (details) {
                    _eraseAtPoint(details.localPosition, page.pageNumber, pageSize);
                  },
                  onPanEnd: (details) {
                    HapticFeedback.lightImpact();
                  },
                  child: Container(color: Colors.transparent),
                );
              },
            ),
          ),
      ],
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<PdfAnnotation> annotations;
  final double scale;
  final PdfPage page;
  final Rect pageRect;
  final String? selectedAnnotationId;

  AnnotationPainter({
    required this.annotations,
    required this.scale,
    required this.page,
    required this.pageRect,
    this.selectedAnnotationId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      // Get scaled points based on current page size
      final scaledPoints = annotation.getScaledPoints(size);
      final isSelected = annotation.id == selectedAnnotationId;
      
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (annotation.type == AnnotationType.drawing && scaledPoints.isNotEmpty) {
        final path = Path();
        path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
        for (int i = 1; i < scaledPoints.length; i++) {
          path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
        }
        canvas.drawPath(path, paint);
        
        // Draw selection indicator
        if (isSelected) {
          _drawSelectionIndicator(canvas, scaledPoints);
        }
      } else if (annotation.type == AnnotationType.highlight && scaledPoints.isNotEmpty) {
        // Paint-style highlight - draw semi-transparent highlight with smoother appearance
        final highlightPaint = Paint()
          ..color = annotation.color.withValues(alpha: 0.35) // More transparent for natural look
          ..strokeWidth = 16.0 // Fixed width for consistency
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.multiply; // Better blending with text
        
        if (scaledPoints.length >= 2) {
          final path = Path();
          path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
          for (int i = 1; i < scaledPoints.length; i++) {
            path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
          }
          canvas.drawPath(path, highlightPaint);
          
          // Draw selection indicator
          if (isSelected) {
            _drawSelectionIndicator(canvas, scaledPoints);
          }
        } else if (scaledPoints.length == 1) {
          // Single point - draw a circle
          canvas.drawCircle(scaledPoints.first, 8, highlightPaint..style = PaintingStyle.fill);
        }
      } else if (annotation.type == AnnotationType.textHighlight && scaledPoints.isNotEmpty) {
        // Text-detected highlight - draw semi-transparent filled rectangles behind text
        final textHighlightPaint = Paint()
          ..color = annotation.color.withValues(alpha: 0.3) // 30% opacity for readability
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.multiply; // Better blending with text
        
        // Points are stored as groups of 4: [topLeft, topRight, bottomRight, bottomLeft] for each text rect
        if (scaledPoints.length >= 4) {
          for (int i = 0; i < scaledPoints.length - 3; i += 4) {
            final topLeft = scaledPoints[i];
            final topRight = scaledPoints[i + 1];
            final bottomRight = scaledPoints[i + 2];
            final bottomLeft = scaledPoints[i + 3];
            
            final path = Path()
              ..moveTo(topLeft.dx, topLeft.dy)
              ..lineTo(topRight.dx, topRight.dy)
              ..lineTo(bottomRight.dx, bottomRight.dy)
              ..lineTo(bottomLeft.dx, bottomLeft.dy)
              ..close();
            
            canvas.drawPath(path, textHighlightPaint);
          }
          
          // Draw selection indicator
          if (isSelected) {
            _drawSelectionIndicator(canvas, scaledPoints);
          }
        }
      } else if (annotation.type == AnnotationType.underline && scaledPoints.isNotEmpty) {
        // Text-detected underline - draw line below each detected text fragment
        final underlinePaint = Paint()
          ..color = annotation.color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        
        // Points are stored as pairs: [left, right] for each text fragment
        if (scaledPoints.length >= 2) {
          for (int i = 0; i < scaledPoints.length - 1; i += 2) {
            final left = scaledPoints[i];
            final right = scaledPoints[i + 1];
            // Draw underline at the Y position (which is already set to bottom of text + offset)
            canvas.drawLine(left, right, underlinePaint);
          }
          
          // Draw selection indicator
          if (isSelected) {
            _drawSelectionIndicator(canvas, scaledPoints);
          }
        }
      }
    }
  }
  
  void _drawSelectionIndicator(Canvas canvas, List<Offset> points) {
    if (points.isEmpty) return;
    
    // Calculate bounding box
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    
    for (final point in points) {
      minX = minX > point.dx ? point.dx : minX;
      minY = minY > point.dy ? point.dy : minY;
      maxX = maxX < point.dx ? point.dx : maxX;
      maxY = maxY < point.dy ? point.dy : maxY;
    }
    
    // Add padding
    const padding = 4.0;
    final rect = Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
    
    // Draw selection border
    final selectionPaint = Paint()
      ..color = const Color(0xFF2196F3)  // Blue selection color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      selectionPaint,
    );
    
    // Draw corner handles
    const handleSize = 6.0;
    final handlePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    
    final corners = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];
    
    for (final corner in corners) {
      canvas.drawCircle(corner, handleSize / 2, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
           oldDelegate.selectedAnnotationId != selectedAnnotationId;
  }
}

// Painter for search result highlighting
class SearchHighlightPainter extends CustomPainter {
  final List<List<PdfRect>> matchRects;
  final Rect pageRect;
  final PdfPage page;
  final int? currentMatchIndex;
  final List<PdfPageTextRange> searchMatches;
  final List<PdfPageTextRange> totalMatches;

  SearchHighlightPainter({
    required this.matchRects,
    required this.pageRect,
    required this.page,
    this.currentMatchIndex,
    required this.searchMatches,
    required this.totalMatches,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (matchRects.isEmpty) return;

    final normalPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final currentPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw all matches
    for (int i = 0; i < matchRects.length; i++) {
      final rects = matchRects[i];
      final isCurrentMatch = _isCurrentMatch(i);
      final paint = isCurrentMatch ? currentPaint : normalPaint;

      for (final pdfRect in rects) {
        // Convert PDF coordinates to widget coordinates
        final rect = _convertPdfRectToWidget(pdfRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
        if (isCurrentMatch) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            borderPaint,
          );
        }
      }
    }
  }

  bool _isCurrentMatch(int localIndex) {
    if (currentMatchIndex == null || totalMatches.isEmpty) return false;
    
    // Find the global index of this local match
    int globalIndex = 0;
    for (final match in totalMatches) {
      if (match.pageNumber == page.pageNumber) {
        if (searchMatches.indexOf(match) == localIndex) {
          return globalIndex == currentMatchIndex;
        }
      }
      globalIndex++;
    }
    return false;
  }

  Rect _convertPdfRectToWidget(PdfRect pdfRect) {
    // PDF coordinates have origin at bottom-left, widget at top-left
    // Scale from PDF page size to widget size
    final scaleX = pageRect.width / page.width;
    final scaleY = pageRect.height / page.height;

    final left = pdfRect.left * scaleX;
    final top = (page.height - pdfRect.top) * scaleY;
    final right = pdfRect.right * scaleX;
    final bottom = (page.height - pdfRect.bottom) * scaleY;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldRepaint(covariant SearchHighlightPainter oldDelegate) {
    return oldDelegate.matchRects != matchRects ||
           oldDelegate.currentMatchIndex != currentMatchIndex;
  }
}