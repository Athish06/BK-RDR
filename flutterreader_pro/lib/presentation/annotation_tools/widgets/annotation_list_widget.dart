import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AnnotationListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> annotations;
  final Function(Map<String, dynamic>) onAnnotationTap;
  final Function(Map<String, dynamic>) onAnnotationEdit;
  final Function(Map<String, dynamic>) onAnnotationDelete;
  final Function(Map<String, dynamic>) onAnnotationShare;
  final String searchQuery;

  const AnnotationListWidget({
    super.key,
    required this.annotations,
    required this.onAnnotationTap,
    required this.onAnnotationEdit,
    required this.onAnnotationDelete,
    required this.onAnnotationShare,
    this.searchQuery = '',
  });

  @override
  State<AnnotationListWidget> createState() => _AnnotationListWidgetState();
}

class _AnnotationListWidgetState extends State<AnnotationListWidget>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Highlights',
    'Notes',
    'Drawings',
    'Recent',
  ];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAnnotations {
    List<Map<String, dynamic>> filtered = widget.annotations;

    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((annotation) {
        final content = (annotation['content'] as String? ?? '').toLowerCase();
        final type = (annotation['type'] as String? ?? '').toLowerCase();
        final query = widget.searchQuery.toLowerCase();
        return content.contains(query) || type.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Highlights':
          filtered = filtered.where((a) => a['type'] == 'highlight').toList();
          break;
        case 'Notes':
          filtered = filtered.where((a) => a['type'] == 'note').toList();
          break;
        case 'Drawings':
          filtered = filtered.where((a) => a['type'] == 'draw').toList();
          break;
        case 'Recent':
          filtered.sort((a, b) => (b['timestamp'] as DateTime)
              .compareTo(a['timestamp'] as DateTime));
          filtered = filtered.take(10).toList();
          break;
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter tabs
        _buildFilterTabs(),

        // Annotations count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            '${filteredAnnotations.length} annotation${filteredAnnotations.length != 1 ? 's' : ''}',
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        // Annotations list
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildEmptyState()
              : AnimatedBuilder(
                  animation: _listController,
                  builder: (context, child) {
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: filteredAnnotations.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final annotation = filteredAnnotations[index];
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _listController,
                            curve: Interval(
                              index * 0.1,
                              (index * 0.1) + 0.3,
                              curve: Curves.easeOutCubic,
                            ),
                          )),
                          child: _buildAnnotationCard(annotation, index),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _filterOptions.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : AppTheme.surfaceColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.textSecondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                filter,
                style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnotationCard(Map<String, dynamic> annotation, int index) {
    final type = annotation['type'] as String;
    final content = annotation['content'] as String? ?? '';
    final timestamp = annotation['timestamp'] as DateTime;
    final page = annotation['page'] as int? ?? 1;
    final color = annotation['color'] as Color? ?? AppTheme.accentColor;

    return Dismissible(
      key: Key('annotation_${annotation['id']}'),
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          widget.onAnnotationEdit(annotation);
        } else {
          widget.onAnnotationDelete(annotation);
        }
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAnnotationTap(annotation);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showAnnotationMenu(annotation);
        },
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: _getTypeIcon(type),
                      size: 4.w,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeLabel(type),
                          style: AppTheme.darkTheme.textTheme.labelMedium
                              ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Page $page • ${_formatTimestamp(timestamp)}',
                          style:
                              AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAnnotationMenu(annotation),
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'more_vert',
                        size: 4.w,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              if (content.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    content,
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Page thumbnail (if available)
              if (annotation['thumbnail'] != null) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  height: 8.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: CustomImageWidget(
                    imageUrl: annotation['thumbnail'],
                    width: double.infinity,
                    height: 8.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isEdit) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      decoration: BoxDecoration(
        color: isEdit ? AppTheme.accentColor : AppTheme.errorColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: isEdit ? 'edit' : 'delete',
                size: 6.w,
                color: AppTheme.textPrimary,
              ),
              SizedBox(height: 0.5.h),
              Text(
                isEdit ? 'Edit' : 'Delete',
                style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'note_add',
              size: 10.w,
              color: AppTheme.accentColor,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No annotations found',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start highlighting and taking notes\nto see them here',
            textAlign: TextAlign.center,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnotationMenu(Map<String, dynamic> annotation) {
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
              _buildMenuOption(
                icon: 'edit',
                label: 'Edit Annotation',
                onTap: () {
                  Navigator.pop(context);
                  widget.onAnnotationEdit(annotation);
                },
              ),
              _buildMenuOption(
                icon: 'share',
                label: 'Share Annotation',
                onTap: () {
                  Navigator.pop(context);
                  widget.onAnnotationShare(annotation);
                },
              ),
              _buildMenuOption(
                icon: 'location_on',
                label: 'Jump to Location',
                onTap: () {
                  Navigator.pop(context);
                  widget.onAnnotationTap(annotation);
                },
              ),
              _buildMenuOption(
                icon: 'delete',
                label: 'Delete Annotation',
                color: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  widget.onAnnotationDelete(annotation);
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        size: 6.w,
        color: color ?? AppTheme.textPrimary,
      ),
      title: Text(
        label,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: color ?? AppTheme.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'highlight':
        return 'format_color_fill';
      case 'underline':
        return 'format_underlined';
      case 'strikethrough':
        return 'format_strikethrough';
      case 'draw':
        return 'brush';
      case 'note':
        return 'note_add';
      default:
        return 'note';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'highlight':
        return 'Highlight';
      case 'underline':
        return 'Underline';
      case 'strikethrough':
        return 'Strikethrough';
      case 'draw':
        return 'Drawing';
      case 'note':
        return 'Note';
      default:
        return 'Annotation';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
