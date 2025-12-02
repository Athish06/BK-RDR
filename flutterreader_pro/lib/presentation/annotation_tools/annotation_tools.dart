import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

/// Annotation Notes page - shows all annotations and notes from documents
class AnnotationTools extends StatefulWidget {
  const AnnotationTools({super.key});

  @override
  State<AnnotationTools> createState() => _AnnotationToolsState();
}

class _AnnotationToolsState extends State<AnnotationTools> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;
  
  // Saved annotations from documents
  List<Map<String, dynamic>> _annotations = [];
  List<Map<String, dynamic>> _quickNotes = [];

  final List<String> _filterOptions = ['All', 'Highlights', 'Underlines', 'Drawings', 'Notes'];

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnotations() async {
    setState(() => _isLoading = true);
    
    // In a real app, this would load from a database/storage
    // For now, we'll show empty state since annotations are stored per-document
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _annotations = [];
        _quickNotes = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAnnotations {
    var filtered = [..._annotations, ..._quickNotes];
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final content = (a['content'] ?? a['note'] ?? '').toString().toLowerCase();
        final docTitle = (a['documentTitle'] ?? '').toString().toLowerCase();
        return content.contains(_searchQuery.toLowerCase()) ||
               docTitle.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((a) {
        final type = a['type']?.toString().toLowerCase() ?? '';
        switch (_selectedFilter) {
          case 'Highlights':
            return type.contains('highlight');
          case 'Underlines':
            return type == 'underline';
          case 'Drawings':
            return type == 'drawing';
          case 'Notes':
            return type == 'note' || a['note'] != null;
          default:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredAnnotations.isEmpty
                      ? _buildEmptyState()
                      : _buildAnnotationsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        variant: CustomBottomBarVariant.magnetic,
        currentIndex: 2,
        enableHapticFeedback: true,
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
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes & Annotations',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_filteredAnnotations.length} items',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search annotations...',
                hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.clear, color: AppTheme.textSecondary, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 5.h,
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = filter);
            },
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.accentColor 
                      : AppTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                filter,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_outlined,
              color: AppTheme.accentColor.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'No annotations yet',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Open a PDF and use annotation tools\nto highlight, underline, draw, or add notes',
              textAlign: TextAlign.center,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            
            // Tools info
            _buildToolsInfo(),
            
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.library_books),
              label: const Text('Open Library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Tools',
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildToolItem(Icons.highlight, 'Highlight', 'Paint or text-detect highlight'),
          _buildToolItem(Icons.format_underlined, 'Underline', 'Underline text'),
          _buildToolItem(Icons.draw, 'Draw', 'Freehand drawing'),
          _buildToolItem(Icons.note_add, 'Notes', 'Add notes to annotations'),
          _buildToolItem(Icons.auto_fix_off, 'Eraser', 'Remove annotations'),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentColor, size: 18),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationsList() {
    final grouped = _groupByDocument(_filteredAnnotations);
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final docTitle = grouped.keys.elementAt(index);
        final docAnnotations = grouped[docTitle]!;
        
        return _buildDocumentSection(docTitle, docAnnotations);
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDocument(List<Map<String, dynamic>> annotations) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final annotation in annotations) {
      final docTitle = annotation['documentTitle'] ?? 'Unknown Document';
      grouped.putIfAbsent(docTitle, () => []).add(annotation);
    }
    
    return grouped;
  }

  Widget _buildDocumentSection(String docTitle, List<Map<String, dynamic>> annotations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: AppTheme.accentColor, size: 18),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  docTitle,
                  style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${annotations.length}',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...annotations.map((a) => _buildAnnotationTile(a)),
        SizedBox(height: 1.h),
      ],
    );
  }

  Widget _buildAnnotationTile(Map<String, dynamic> annotation) {
    final type = annotation['type'] ?? 'note';
    final content = annotation['content'] ?? annotation['note'] ?? '';
    final page = annotation['page'] ?? 0;
    final color = annotation['color'] as Color? ?? AppTheme.accentColor;
    
    IconData icon;
    switch (type.toString().toLowerCase()) {
      case 'highlight':
      case 'texthighlight':
        icon = Icons.highlight;
        break;
      case 'underline':
        icon = Icons.format_underlined;
        break;
      case 'drawing':
        icon = Icons.draw;
        break;
      default:
        icon = Icons.note;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Page $page',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
