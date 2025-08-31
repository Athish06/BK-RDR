import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/annotation_list_widget.dart';
import './widgets/annotation_toolbar_widget.dart';
import './widgets/drawing_canvas_widget.dart';
import './widgets/export_options_widget.dart';
import './widgets/note_editor_widget.dart';

class AnnotationTools extends StatefulWidget {
  const AnnotationTools({super.key});

  @override
  State<AnnotationTools> createState() => _AnnotationToolsState();
}

class _AnnotationToolsState extends State<AnnotationTools>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TextEditingController _searchController;

  String _selectedTool = 'highlight';
  Color _selectedColor = AppTheme.warningColor;
  String _searchQuery = '';
  bool _showToolbar = true;
  bool _showDrawingCanvas = false;
  bool _showNoteEditor = false;
  bool _showExportOptions = false;

  // Undo/Redo stacks
  List<Map<String, dynamic>> _undoStack = [];
  List<Map<String, dynamic>> _redoStack = [];

  // Mock annotations data
  final List<Map<String, dynamic>> _mockAnnotations = [
    {
      'id': 'ann_001',
      'type': 'highlight',
      'content':
          'Flutter is Google\'s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.',
      'page': 1,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'color': AppTheme.warningColor,
      'thumbnail':
          'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=300&fit=crop',
    },
    {
      'id': 'ann_002',
      'type': 'note',
      'content':
          'Remember to implement proper state management using Provider or Riverpod for complex applications.',
      'page': 3,
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'color': AppTheme.accentColor,
    },
    {
      'id': 'ann_003',
      'type': 'underline',
      'content':
          'Widget composition is preferred over inheritance in Flutter development.',
      'page': 2,
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'color': AppTheme.accentColor,
    },
    {
      'id': 'ann_004',
      'type': 'draw',
      'content': 'Custom drawing showing app architecture flow',
      'page': 5,
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'color': AppTheme.successColor,
      'thumbnail':
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=300&fit=crop',
    },
    {
      'id': 'ann_005',
      'type': 'highlight',
      'content':
          'Performance optimization is crucial for smooth animations and user experience.',
      'page': 7,
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'color': AppTheme.errorColor,
    },
    {
      'id': 'ann_006',
      'type': 'note',
      'content':
          'Consider using const constructors to improve performance and reduce widget rebuilds.',
      'page': 4,
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'color': AppTheme.successColor,
    },
    {
      'id': 'ann_007',
      'type': 'strikethrough',
      'content': 'Old approach: Using setState for everything',
      'page': 6,
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
      'color': AppTheme.errorColor,
    },
    {
      'id': 'ann_008',
      'type': 'highlight',
      'content':
          'Hot reload and hot restart are powerful development features that speed up the development process.',
      'page': 8,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'color': AppTheme.accentColor,
      'thumbnail':
          'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=400&h=300&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Search bar
                  _buildSearchBar(),

                  // Annotations list
                  Expanded(
                    child: AnnotationListWidget(
                      annotations: _mockAnnotations,
                      searchQuery: _searchQuery,
                      onAnnotationTap: _jumpToAnnotation,
                      onAnnotationEdit: _editAnnotation,
                      onAnnotationDelete: _deleteAnnotation,
                      onAnnotationShare: _shareAnnotation,
                    ),
                  ),
                ],
              ),

              // Floating toolbar
              if (_showToolbar)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnnotationToolbarWidget(
                    selectedTool: _selectedTool,
                    selectedColor: _selectedColor,
                    canUndo: _undoStack.isNotEmpty,
                    canRedo: _redoStack.isNotEmpty,
                    onToolSelected: _onToolSelected,
                    onColorSelected: _onColorSelected,
                    onUndo: _performUndo,
                    onRedo: _performRedo,
                  ),
                ),

              // Drawing canvas overlay
              if (_showDrawingCanvas)
                DrawingCanvasWidget(
                  selectedColor: _selectedColor,
                  strokeWidth: 3.0,
                  onDrawingComplete: _saveDrawing,
                  onClose: () {
                    setState(() {
                      _showDrawingCanvas = false;
                    });
                  },
                ),

              // Note editor overlay
              if (_showNoteEditor)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: NoteEditorWidget(
                    title: 'Add Note',
                    maxLength: 500,
                    onSave: _saveNote,
                    onCancel: () {
                      setState(() {
                        _showNoteEditor = false;
                      });
                    },
                  ),
                ),

              // Export options overlay
              if (_showExportOptions)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ExportOptionsWidget(
                    annotations: _mockAnnotations,
                    documentTitle: 'Flutter Development Guide',
                    onClose: () {
                      setState(() {
                        _showExportOptions = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'arrow_back_ios',
                size: 5.w,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annotation Tools',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_mockAnnotations.length} annotations • Flutter Guide',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showExportOptions = true;
              });
            },
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientDecoration().gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'file_download',
                size: 5.w,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/settings');
            },
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'more_vert',
                size: 5.w,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'search',
            size: 5.w,
            color: AppTheme.textSecondary,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search annotations, notes, or content...',
                hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _searchController.clear();
              },
              child: CustomIconWidget(
                iconName: 'clear',
                size: 5.w,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  void _onToolSelected(String tool) {
    setState(() {
      _selectedTool = tool;
    });

    switch (tool) {
      case 'draw':
        setState(() {
          _showDrawingCanvas = true;
          _showToolbar = false;
        });
        break;
      case 'note':
        setState(() {
          _showNoteEditor = true;
          _showToolbar = false;
        });
        break;
      default:
        // For highlight, underline, strikethrough - would integrate with PDF viewer
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${tool.toUpperCase()} tool selected. Select text in PDF to apply.'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  void _onColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _jumpToAnnotation(Map<String, dynamic> annotation) {
    HapticFeedback.lightImpact();

    // Navigate to PDF reader with specific page
    Navigator.pushNamed(
      context,
      '/pdf-reader',
      arguments: {
        'page': annotation['page'],
        'annotationId': annotation['id'],
      },
    );
  }

  void _editAnnotation(Map<String, dynamic> annotation) {
    HapticFeedback.lightImpact();

    if (annotation['type'] == 'note') {
      setState(() {
        _showNoteEditor = true;
        _showToolbar = false;
      });
    } else {
      // Show edit options for other annotation types
      _showEditOptions(annotation);
    }
  }

  void _deleteAnnotation(Map<String, dynamic> annotation) {
    HapticFeedback.mediumImpact();

    // Add to undo stack before deletion
    _undoStack.add({
      'action': 'delete',
      'annotation': Map.from(annotation),
      'timestamp': DateTime.now(),
    });

    setState(() {
      _mockAnnotations.removeWhere((a) => a['id'] == annotation['id']);
      _redoStack.clear(); // Clear redo stack on new action
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Annotation deleted'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.textPrimary,
          onPressed: _performUndo,
        ),
      ),
    );
  }

  void _shareAnnotation(Map<String, dynamic> annotation) {
    HapticFeedback.lightImpact();

    final content = '''
Annotation from Flutter Development Guide
Page ${annotation['page']} • ${annotation['type'].toUpperCase()}

${annotation['content']}

Created: ${annotation['timestamp']}
Shared via FlutterReader Pro
''';

    // In a real app, this would use the share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Annotation copied to clipboard'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Clipboard.setData(ClipboardData(text: content));
  }

  void _saveDrawing(List<Offset> points) {
    HapticFeedback.mediumImpact();

    final newAnnotation = {
      'id': 'ann_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'draw',
      'content': 'Custom drawing with ${points.length} points',
      'page': 1, // Current page in PDF
      'timestamp': DateTime.now(),
      'color': _selectedColor,
      'drawingPoints': points,
    };

    setState(() {
      _mockAnnotations.insert(0, newAnnotation);
      _showDrawingCanvas = false;
      _showToolbar = true;
    });

    // Add to undo stack
    _undoStack.add({
      'action': 'add',
      'annotation': Map.from(newAnnotation),
      'timestamp': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Drawing saved successfully'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveNote(String noteText) {
    HapticFeedback.mediumImpact();

    final newAnnotation = {
      'id': 'ann_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'note',
      'content': noteText,
      'page': 1, // Current page in PDF
      'timestamp': DateTime.now(),
      'color': _selectedColor,
    };

    setState(() {
      _mockAnnotations.insert(0, newAnnotation);
      _showNoteEditor = false;
      _showToolbar = true;
    });

    // Add to undo stack
    _undoStack.add({
      'action': 'add',
      'annotation': Map.from(newAnnotation),
      'timestamp': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note saved successfully'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _performUndo() {
    if (_undoStack.isEmpty) return;

    HapticFeedback.lightImpact();
    final lastAction = _undoStack.removeLast();

    switch (lastAction['action']) {
      case 'add':
        // Remove the added annotation
        final annotation = lastAction['annotation'];
        setState(() {
          _mockAnnotations.removeWhere((a) => a['id'] == annotation['id']);
        });
        break;
      case 'delete':
        // Restore the deleted annotation
        final annotation = lastAction['annotation'];
        setState(() {
          _mockAnnotations.insert(0, annotation);
        });
        break;
      case 'edit':
        // Restore previous version
        final annotation = lastAction['annotation'];
        final index =
            _mockAnnotations.indexWhere((a) => a['id'] == annotation['id']);
        if (index != -1) {
          setState(() {
            _mockAnnotations[index] = annotation;
          });
        }
        break;
    }

    // Move to redo stack
    _redoStack.add(lastAction);
  }

  void _performRedo() {
    if (_redoStack.isEmpty) return;

    HapticFeedback.lightImpact();
    final action = _redoStack.removeLast();

    switch (action['action']) {
      case 'add':
        // Re-add the annotation
        final annotation = action['annotation'];
        setState(() {
          _mockAnnotations.insert(0, annotation);
        });
        break;
      case 'delete':
        // Re-delete the annotation
        final annotation = action['annotation'];
        setState(() {
          _mockAnnotations.removeWhere((a) => a['id'] == annotation['id']);
        });
        break;
      case 'edit':
        // Re-apply the edit
        final annotation = action['annotation'];
        final index =
            _mockAnnotations.indexWhere((a) => a['id'] == annotation['id']);
        if (index != -1) {
          setState(() {
            _mockAnnotations[index] = annotation;
          });
        }
        break;
    }

    // Move back to undo stack
    _undoStack.add(action);
  }

  void _showEditOptions(Map<String, dynamic> annotation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 0.5.h,
                margin: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'palette',
                  size: 6.w,
                  color: AppTheme.accentColor,
                ),
                title: Text(
                  'Change Color',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show color picker
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'edit',
                  size: 6.w,
                  color: AppTheme.successColor,
                ),
                title: Text(
                  'Edit Content',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show edit dialog
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
