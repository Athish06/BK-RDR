import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PdfBookmarkPanel extends StatefulWidget {
  final bool isVisible;
  final List<Map<String, dynamic>> bookmarks;
  final ValueChanged<int>? onBookmarkTap;
  final ValueChanged<Map<String, dynamic>>? onBookmarkAdd;
  final ValueChanged<Map<String, dynamic>>? onBookmarkEdit;
  final ValueChanged<Map<String, dynamic>>? onBookmarkDelete;
  final VoidCallback? onClose;

  const PdfBookmarkPanel({
    super.key,
    required this.isVisible,
    required this.bookmarks,
    this.onBookmarkTap,
    this.onBookmarkAdd,
    this.onBookmarkEdit,
    this.onBookmarkDelete,
    this.onClose,
  });

  @override
  State<PdfBookmarkPanel> createState() => _PdfBookmarkPanelState();
}

class _PdfBookmarkPanelState extends State<PdfBookmarkPanel>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _showAddBookmark = false;
  int? _editingIndex;

  final List<IconData> _bookmarkIcons = [
    Icons.bookmark,
    Icons.star,
    Icons.favorite,
    Icons.lightbulb,
    Icons.flag,
    Icons.label,
    Icons.push_pin,
    Icons.highlight,
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _slideController.forward();
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(PdfBookmarkPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
        _fadeController.forward();
      } else {
        _slideController.reverse();
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleBookmarkTap(int index) {
    HapticFeedback.lightImpact();
    final bookmark = widget.bookmarks[index];
    widget.onBookmarkTap?.call(bookmark['page'] as int);
  }

  void _showAddBookmarkForm() {
    setState(() {
      _showAddBookmark = true;
      _editingIndex = null;
      _titleController.clear();
      _noteController.clear();
    });
  }

  void _showEditBookmarkForm(int index) {
    final bookmark = widget.bookmarks[index];
    setState(() {
      _showAddBookmark = true;
      _editingIndex = index;
      _titleController.text = bookmark['title'] as String;
      _noteController.text = bookmark['note'] as String? ?? '';
    });
  }

  void _saveBookmark() {
    if (_titleController.text.trim().isEmpty) return;

    final bookmarkData = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': _titleController.text.trim(),
      'note': _noteController.text.trim(),
      'page': 1, // Current page would be passed from parent
      'icon': _bookmarkIcons[0].codePoint,
      'color': AppTheme.accentColor.toARGB32(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (_editingIndex != null) {
      widget.onBookmarkEdit?.call(bookmarkData);
    } else {
      widget.onBookmarkAdd?.call(bookmarkData);
    }

    setState(() {
      _showAddBookmark = false;
      _editingIndex = null;
    });

    HapticFeedback.lightImpact();
  }

  void _deleteBookmark(int index) {
    HapticFeedback.lightImpact();
    final bookmark = widget.bookmarks[index];
    widget.onBookmarkDelete?.call(bookmark);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: Colors.transparent),
              ),
            ),
            Expanded(
              flex: 3,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: _showAddBookmark
                        ? _buildAddBookmarkForm()
                        : _buildBookmarkList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkList() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: AppTheme.gradientDecoration().gradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bookmarks',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showAddBookmarkForm,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bookmarks list
        Expanded(
          child: widget.bookmarks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(2.w),
                  itemCount: widget.bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = widget.bookmarks[index];
                    return _buildBookmarkItem(bookmark, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookmarkItem(Map<String, dynamic> bookmark, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleBookmarkTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Color(bookmark['color'] as int? ??
                            AppTheme.accentColor.toARGB32())
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconData(
                      bookmark['icon'] as int? ?? Icons.bookmark.codePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: Color(bookmark['color'] as int? ??
                        AppTheme.accentColor.toARGB32()),
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookmark['title'] as String,
                        style:
                            AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bookmark['note'] != null &&
                          (bookmark['note'] as String).isNotEmpty) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          bookmark['note'] as String,
                          style:
                              AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 1.h),
                      Text(
                        'Page ${bookmark['page']}',
                        style: AppTheme.dataTextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  color: AppTheme.surfaceColor,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBookmarkForm(index);
                    } else if (value == 'delete') {
                      _deleteBookmark(index);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'edit',
                            color: AppTheme.textPrimary,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Edit',
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'delete',
                            color: AppTheme.errorColor,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Delete',
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: CustomIconWidget(
              iconName: 'bookmark_border',
              color: AppTheme.accentColor,
              size: 48,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Bookmarks Yet',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add bookmarks to quickly\njump to important pages',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _showAddBookmarkForm,
            child: Text('Add Bookmark'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBookmarkForm() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: AppTheme.gradientDecoration().gradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showAddBookmark = false),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
                child: Text(
                  _editingIndex != null ? 'Edit Bookmark' : 'Add Bookmark',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Form
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _titleController,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter bookmark title',
                    filled: true,
                    fillColor: AppTheme.primaryDark,
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  'Note (Optional)',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a note about this bookmark',
                    filled: true,
                    fillColor: AppTheme.primaryDark,
                  ),
                ),

                const Spacer(),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveBookmark,
                    child: Text(_editingIndex != null
                        ? 'Update Bookmark'
                        : 'Save Bookmark'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
