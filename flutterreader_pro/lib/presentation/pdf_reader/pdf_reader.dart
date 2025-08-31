import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

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

class _PdfReaderState extends State<PdfReader>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _zoomController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;
  
  // PDF state
  int _currentPage = 1;
  final int _totalPages = 247;
  double _zoomLevel = 1.0;
  bool _isFullScreen = false;
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
  
  // Bookmarks and notes
  final List<Map<String, dynamic>> _bookmarks = [
{ 'id': 1,
'title': 'Introduction to Machine Learning',
'note': 'Key concepts and definitions',
'page': 15,
'icon': Icons.star.codePoint,
'color': AppTheme.accentColor.value,
'createdAt': '2025-08-05T10:30:00.000Z',
},
{ 'id': 2,
'title': 'Neural Network Architecture',
'note': 'Important diagram showing layer structure',
'page': 42,
'icon': Icons.lightbulb.codePoint,
'color': AppTheme.warningColor.value,
'createdAt': '2025-08-05T14:15:00.000Z',
},
{ 'id': 3,
'title': 'Training Algorithms',
'note': 'Backpropagation explanation',
'page': 78,
'icon': Icons.flag.codePoint,
'color': AppTheme.successColor.value,
'createdAt': '2025-08-05T16:45:00.000Z',
},
];
  
  final List<Map<String, dynamic>> _quickNotes = [];
  
  // Mock PDF document data
  final Map<String, dynamic> _documentData = {
    'title': 'Deep Learning Fundamentals',
    'author': 'Dr. Sarah Chen',
    'pages': 247,
    'fileSize': '12.4 MB',
    'lastOpened': '2025-08-05T20:33:46.059496',
    'readingProgress': 0.32,
    'totalReadingTime': '4h 23m',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAutoHideControls();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
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
    _fadeController.dispose();
    _zoomController.dispose();
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
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
    });
    HapticFeedback.lightImpact();
  }

  void _handleZoomChange(double zoom) {
    setState(() {
      _zoomLevel = zoom.clamp(0.5, 3.0);
    });
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
    setState(() {
      _isTextReflowMode = !_isTextReflowMode;
    });
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // PDF Content Area
            GestureDetector(
              onTap: _toggleControls,
              onDoubleTap: () {
                _zoomController.forward().then((_) {
                  _zoomController.reverse();
                });
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
      ),
    );
  }

  Widget _buildTopOverlay() {
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
                      _documentData['title'] as String,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by ${_documentData['author']} • ${((_documentData['readingProgress'] as double) * 100).round()}% complete',
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
    return AnimatedBuilder(
      animation: _zoomAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _zoomLevel * _zoomAnimation.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _isTextReflowMode ? AppTheme.primaryDark : Colors.white,
            ),
            child: _isTextReflowMode ? _buildTextReflowContent() : _buildPdfPageContent(),
          ),
        );
      },
    );
  }

  Widget _buildPdfPageContent() {
    return PageView.builder(
      onPageChanged: (page) => _handlePageNavigation(page + 1),
      itemCount: _totalPages,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Stack(
            children: [
              // Mock PDF page content
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.all(6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0) ...[
                      Text(
                        _documentData['title'] as String,
                        style: AppTheme.darkTheme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'by ${_documentData['author']}',
                        style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => _handleTextSelection(
                          'Machine learning is a subset of artificial intelligence (AI) that focuses on algorithms and statistical models that enable computer systems to improve their performance on a specific task through experience, without being explicitly programmed for that task.'
                        ),
                        child: Text(
                          _getMockPageContent(index + 1),
                          style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    // Page number
                    Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTheme.dataTextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search highlights overlay
              if (_searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: SearchHighlightPainter(
                      query: _searchQuery,
                      currentMatch: _currentSearchMatch,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextReflowContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _documentData['title'] as String,
            style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'by ${_documentData['author']}',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onLongPress: () => _handleTextSelection(
              'Machine learning is a subset of artificial intelligence that focuses on algorithms and statistical models.'
            ),
            child: Text(
              _getFullDocumentContent(),
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMockPageContent(int page) {
    final contents = [
      'Machine learning is a subset of artificial intelligence (AI) that focuses on algorithms and statistical models that enable computer systems to improve their performance on a specific task through experience, without being explicitly programmed for that task.\n\nThe field of machine learning emerged from the quest for artificial intelligence. In the early days of AI as an academic discipline, some researchers were interested in having machines learn from data. They attempted to approach the problem with various symbolic methods, as well as what were then termed "neural networks"; these were mostly perceptrons and other models that were later found to be reinventions of the generalized linear models of statistics.',
      'Deep learning is part of a broader family of machine learning methods based on artificial neural networks with representation learning. Learning can be supervised, semi-supervised or unsupervised.\n\nDeep learning architectures such as deep neural networks, deep belief networks, recurrent neural networks and convolutional neural networks have been applied to fields including computer vision, machine learning, natural language processing, machine translation, bioinformatics and drug design, where they have produced results comparable to and in some cases surpassing human expert performance.',
      'Neural networks are computing systems vaguely inspired by the biological neural networks that constitute animal brains. Such systems "learn" to perform tasks by considering examples, generally without being programmed with task-specific rules.\n\nFor example, in image recognition, they might learn to identify images that contain cats by analyzing example images that have been manually labeled as "cat" or "no cat" and using the results to identify cats in other images. They do this without any prior knowledge of cats, for example, that they have fur, tails, whiskers and cat-like faces.',
    ];
    
    return contents[(page - 1) % contents.length];
  }

  String _getFullDocumentContent() {
    return '''Machine learning is a subset of artificial intelligence (AI) that focuses on algorithms and statistical models that enable computer systems to improve their performance on a specific task through experience, without being explicitly programmed for that task.

The field of machine learning emerged from the quest for artificial intelligence. In the early days of AI as an academic discipline, some researchers were interested in having machines learn from data. They attempted to approach the problem with various symbolic methods, as well as what were then termed "neural networks"; these were mostly perceptrons and other models that were later found to be reinventions of the generalized linear models of statistics.

Deep learning is part of a broader family of machine learning methods based on artificial neural networks with representation learning. Learning can be supervised, semi-supervised or unsupervised.

Deep learning architectures such as deep neural networks, deep belief networks, recurrent neural networks and convolutional neural networks have been applied to fields including computer vision, machine learning, natural language processing, machine translation, bioinformatics and drug design, where they have produced results comparable to and in some cases surpassing human expert performance.

Neural networks are computing systems vaguely inspired by the biological neural networks that constitute animal brains. Such systems "learn" to perform tasks by considering examples, generally without being programmed with task-specific rules.

For example, in image recognition, they might learn to identify images that contain cats by analyzing example images that have been manually labeled as "cat" or "no cat" and using the results to identify cats in other images. They do this without any prior knowledge of cats, for example, that they have fur, tails, whiskers and cat-like faces.''';
  }
}

class SearchHighlightPainter extends CustomPainter {
  final String query;
  final int currentMatch;

  SearchHighlightPainter({
    required this.query,
    required this.currentMatch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (query.isEmpty) return;
    
    final paint = Paint()
      ..color = AppTheme.warningColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final currentPaint = Paint()
      ..color = AppTheme.accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    
    // Mock highlight rectangles
    final highlights = [
      Rect.fromLTWH(20, 100, 120, 20),
      Rect.fromLTWH(50, 200, 80, 20),
      Rect.fromLTWH(30, 300, 100, 20),
    ];
    
    for (int i = 0; i < highlights.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlights[i], const Radius.circular(4)),
        i == (currentMatch - 1) ? currentPaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}