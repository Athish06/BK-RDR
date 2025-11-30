import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sizer/sizer.dart';
import 'package:universal_io/io.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/app_export.dart';
import './widgets/pdf_annotation_toolbar.dart';
import './widgets/pdf_bookmark_panel.dart';
import './widgets/pdf_floating_controls.dart';
import './widgets/pdf_quick_note_bubble.dart';
import './widgets/pdf_search_overlay.dart';
import './widgets/pdf_tts_player.dart';

class PdfReader extends StatefulWidget {
  const PdfReader({super.key});

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  // PDF state
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _isTextReflowMode = false;
  String _selectedText = '';
  
  // UI state
  bool _showControls = true;
  bool _showAnnotationToolbar = false;
  bool _showBookmarkPanel = false;
  bool _showSearchOverlay = false;
  bool _showTTSPlayer = false;
  
  // Auto-scroll state
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 1.0;
  
  // Search state
  String _searchQuery = '';
  int _currentSearchMatch = 0;
  int _totalSearchMatches = 0;
  
  // TTS state
  bool _isTTSPlaying = false;
  bool _isTTSPaused = false;
  double _ttsProgress = 0.0;
  String _currentSentence = '';
  double _ttsPlaybackSpeed = 1.0;

  DocumentModel? _document;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  // Bookmarks and notes
  final List<Map<String, dynamic>> _bookmarks = [];
  
  final List<Map<String, dynamic>> _quickNotes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DocumentModel) {
      _document = args;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAutoHideControls();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _setupAutoHideControls();
    }
  }

  void _handleTextSelection(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _selectedText = text;
        _showAnnotationToolbar = true;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _handlePageNavigation(int page) {
    if (_totalPages == 0) return;
    _pdfViewerController.jumpToPage(page);
    HapticFeedback.lightImpact();
  }

  void _handleZoomChange(double zoom) {
    final newZoom = zoom.clamp(0.5, 3.0);
    setState(() {
      _zoomLevel = newZoom;
    });
    _pdfViewerController.zoomLevel = newZoom;
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    HapticFeedback.lightImpact();
  }

  void _handleAutoScrollSpeedChange(double speed) {
    setState(() {
      _autoScrollSpeed = speed;
    });
  }

  void _toggleTextReflow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text reflow is not supported for PDF files')),
    );
    HapticFeedback.mediumImpact();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        // Mock search results
        _totalSearchMatches = 23;
        _currentSearchMatch = 1;
      } else {
        _totalSearchMatches = 0;
        _currentSearchMatch = 0;
      }
    });
  }

  void _navigateSearchMatch(bool next) {
    if (_totalSearchMatches > 0) {
      setState(() {
        if (next) {
          _currentSearchMatch = (_currentSearchMatch % _totalSearchMatches) + 1;
        } else {
          _currentSearchMatch = _currentSearchMatch > 1 
              ? _currentSearchMatch - 1 
              : _totalSearchMatches;
        }
      });
    }
  }

  void _toggleTTS() {
    setState(() {
      _showTTSPlayer = !_showTTSPlayer;
      if (_showTTSPlayer) {
        _currentSentence = _selectedText.isNotEmpty 
            ? _selectedText 
            : 'Machine learning is a subset of artificial intelligence that focuses on algorithms and statistical models.';
      }
    });
  }

  void _handleTTSPlayPause() {
    setState(() {
      _isTTSPlaying = !_isTTSPlaying;
      _isTTSPaused = !_isTTSPlaying;
    });
  }

  void _handleTTSSpeedChange(double speed) {
    setState(() {
      _ttsPlaybackSpeed = speed;
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
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // PDF Content Area
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: () {
              _handleZoomChange(_zoomLevel == 1.0 ? 2.0 : 1.0);
            },
            onLongPress: () {
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
            
            // Top overlay with document info
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(),
              ),
            
            // Quick note bubbles
            ..._quickNotes.map((note) {
              return PdfQuickNoteBubble(
                position: note['position'] as Offset,
                note: note['note'] as String,
                isEditing: note['isEditing'] as bool,
                onNoteChanged: (newNote) => _updateQuickNote(note['id'] as int, newNote),
                onSave: () => _updateQuickNote(note['id'] as int, note['note'] as String),
                onDelete: () => _deleteQuickNote(note['id'] as int),
                onClose: () => _deleteQuickNote(note['id'] as int),
              );
            }).toList(),
            
            // Annotation toolbar
            if (_showAnnotationToolbar)
              Positioned(
                bottom: 25.h,
                left: 0,
                right: 0,
                child: PdfAnnotationToolbar(
                  selectedText: _selectedText,
                  onHighlight: () {
                    setState(() => _showAnnotationToolbar = false);
                    HapticFeedback.lightImpact();
                  },
                  onUnderline: () {
                    setState(() => _showAnnotationToolbar = false);
                    HapticFeedback.lightImpact();
                  },
                  onDraw: () {
                    setState(() => _showAnnotationToolbar = false);
                    Navigator.pushNamed(context, '/annotation-tools');
                  },
                  onNote: () {
                    setState(() => _showAnnotationToolbar = false);
                    final position = Offset(50.w, 40.h);
                    _addQuickNote(position);
                  },
                  onClose: () => setState(() => _showAnnotationToolbar = false),
                ),
              ),
            
            // Floating controls
            PdfFloatingControls(
              isVisible: _showControls,
              currentPage: _currentPage,
              totalPages: _totalPages,
              zoomLevel: _zoomLevel,
              isAutoScrolling: _isAutoScrolling,
              autoScrollSpeed: _autoScrollSpeed,
              isTextReflowMode: _isTextReflowMode,
              onBookmarkTap: () => setState(() => _showBookmarkPanel = true),
              onSearchTap: () => setState(() => _showSearchOverlay = true),
              onAnnotationTap: () => Navigator.pushNamed(context, '/annotation-tools'),
              onTTSTap: _toggleTTS,
              onSettingsTap: () => Navigator.pushNamed(context, '/settings'),
              onAutoScrollToggle: _toggleAutoScroll,
              onAutoScrollSpeedChanged: _handleAutoScrollSpeedChange,
              onTextReflowToggle: _toggleTextReflow,
              onZoomChanged: _handleZoomChange,
            ),
            
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
            
            // TTS Player
            PdfTtsPlayer(
              isVisible: _showTTSPlayer,
              isPlaying: _isTTSPlaying,
              isPaused: _isTTSPaused,
              progress: _ttsProgress,
              currentSentence: _currentSentence,
              playbackSpeed: _ttsPlaybackSpeed,
              onPlayPause: _handleTTSPlayPause,
              onStop: () => setState(() {
                _isTTSPlaying = false;
                _ttsProgress = 0.0;
              }),
              onPrevious: () => setState(() => _currentSentence = 'Previous sentence content...'),
              onNext: () => setState(() => _currentSentence = 'Next sentence content...'),
              onSpeedChanged: _handleTTSSpeedChange,
              onClose: () => setState(() => _showTTSPlayer = false),
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
          ],
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
                onTap: () => Navigator.pop(context),
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
    if (_document == null) {
      return const Center(child: Text('No document loaded'));
    }

    if (_isTextReflowMode) {
       return const Center(child: Text('Text reflow not supported for this document'));
    }

    final isNetworkUrl = _document!.filePath.startsWith('http') || _document!.filePath.startsWith('https');

    if (isNetworkUrl) {
      return SfPdfViewer.network(
        _document!.filePath,
        controller: _pdfViewerController,
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
             _totalPages = details.document.pages.count;
          });
        },
      );
    } else if (!kIsWeb) {
      return SfPdfViewer.file(
        File(_document!.filePath),
        controller: _pdfViewerController,
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
             _totalPages = details.document.pages.count;
          });
        },
      );
    } else {
      return const Center(child: Text('Local file access is not supported on Web'));
    }
  }
}

