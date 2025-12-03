import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

/// Annotation Notes page - shows all annotations and notes from documents
/// Grouped by document with page numbers and option to open in PDF reader
class AnnotationTools extends StatefulWidget {
  const AnnotationTools({super.key});

  @override
  State<AnnotationTools> createState() => _AnnotationToolsState();
}

class _AnnotationToolsState extends State<AnnotationTools> {
  final TextEditingController _searchController = TextEditingController();
  final AnnotationService _annotationService = AnnotationService();
  final DocumentService _documentService = DocumentService();
  
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;
  
  // Annotations grouped by document
  Map<String, List<AnnotationData>> _groupedAnnotations = {};
  Map<String, DocumentModel?> _documentCache = {};

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
    
    try {
      // Load annotations from Supabase grouped by document
      final grouped = await _annotationService.getAnnotationsGroupedByDocument();
      
      // Cache documents for quick access
      final docs = await _documentService.getAllDocuments();
      for (final doc in docs) {
        _documentCache[doc.id] = doc;
      }
      
      if (mounted) {
        setState(() {
          _groupedAnnotations = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading annotations: $e');
      if (mounted) {
        setState(() {
          _groupedAnnotations = {};
          _isLoading = false;
        });
      }
    }
  }

  List<AnnotationData> _getFilteredAnnotations(List<AnnotationData> annotations) {
    var filtered = [...annotations];
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final content = (a.content ?? '').toLowerCase();
        final docTitle = a.documentTitle.toLowerCase();
        return content.contains(_searchQuery.toLowerCase()) ||
               docTitle.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((a) {
        final type = a.type.toLowerCase();
        switch (_selectedFilter) {
          case 'Highlights':
            return type.contains('highlight');
          case 'Underlines':
            return type == 'underline';
          case 'Drawings':
            return type == 'drawing';
          case 'Notes':
            return type == 'note' || type == 'text' || (a.content != null && a.content!.isNotEmpty);
          default:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  void _openAnnotationInReader(AnnotationData annotation) async {
    final docId = annotation.documentId;
    var doc = _documentCache[docId];
    
    if (doc == null) {
      // Try to fetch document
      try {
        final docs = await _documentService.getAllDocuments();
        doc = docs.where((d) => d.id == docId).firstOrNull;
      } catch (e) {
        print('❌ Could not fetch document: $e');
      }
    }
    
    if (doc != null && mounted) {
      Navigator.pushNamed(
        context, 
        '/pdf-reader',
        arguments: doc,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open document'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAnnotation(AnnotationData annotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Annotation?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await _annotationService.deleteAnnotationFromSupabase(annotation.id);
      if (success) {
        await _loadAnnotations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Annotation deleted'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientDecoration().gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annotations',
                  style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Your highlights, notes & drawings',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAnnotations,
              ),
              IconButton(
                icon: Icon(Icons.sort, color: Colors.white),
                onPressed: () => _showSortOptions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search annotations...',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 5.h,
      margin: EdgeInsets.symmetric(vertical: 1.5.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = filter);
              },
              selectedColor: AppTheme.accentColor,
              backgroundColor: AppTheme.surfaceColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.accentColor : Colors.transparent,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading annotations...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationsList() {
    if (_groupedAnnotations.isEmpty) {
      return _buildEmptyState();
    }

    // Filter each group
    final filteredGroups = <String, List<AnnotationData>>{};
    for (final entry in _groupedAnnotations.entries) {
      final filtered = _getFilteredAnnotations(entry.value);
      if (filtered.isNotEmpty) {
        filteredGroups[entry.key] = filtered;
      }
    }

    if (filteredGroups.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnnotations,
      color: AppTheme.accentColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          final key = filteredGroups.keys.elementAt(index);
          final annotations = filteredGroups[key]!;
          final parts = key.split('|');
          final docId = parts.isNotEmpty ? parts[0] : '';
          final docTitle = parts.length > 1 ? parts[1] : 'Unknown Document';
          
          return _buildDocumentAnnotationGroup(docId, docTitle, annotations);
        },
      ),
    );
  }

  Widget _buildDocumentAnnotationGroup(String docId, String docTitle, List<AnnotationData> annotations) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${annotations.length} annotation${annotations.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Open document button
                IconButton(
                  icon: Icon(Icons.open_in_new, color: AppTheme.accentColor, size: 20),
                  tooltip: 'Open document',
                  onPressed: () {
                    if (annotations.isNotEmpty) {
                      _openAnnotationInReader(annotations.first);
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Annotations List
          ...annotations.map((annotation) => _buildAnnotationItem(annotation)),
        ],
      ),
    );
  }

  Widget _buildAnnotationItem(AnnotationData annotation) {
    final type = annotation.type;
    final color = _getColorFromHex(annotation.color);
    final content = annotation.content ?? '';
    final page = annotation.pageNumber;
    final createdAt = annotation.createdAt;
    
    IconData icon;
    String typeLabel;
    
    switch (type.toLowerCase()) {
      case 'highlight':
      case 'texthighlight':
        icon = Icons.highlight;
        typeLabel = 'Highlight';
        break;
      case 'underline':
        icon = Icons.format_underlined;
        typeLabel = 'Underline';
        break;
      case 'drawing':
        icon = Icons.brush;
        typeLabel = 'Drawing';
        break;
      case 'note':
      case 'text':
        icon = Icons.sticky_note_2_outlined;
        typeLabel = 'Note';
        break;
      default:
        icon = Icons.bookmark;
        typeLabel = 'Annotation';
    }

    return InkWell(
      onTap: () => _openAnnotationInReader(annotation),
      onLongPress: () => _showAnnotationOptions(annotation),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 3.w),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Page $page',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (content.isNotEmpty) ...[
                    SizedBox(height: 0.8.h),
                    Text(
                      content,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Open button
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 14),
              onPressed: () => _openAnnotationInReader(annotation),
              tooltip: 'Open in reader',
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnotationOptions(AnnotationData annotation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Annotation Options',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: Icon(Icons.open_in_new, color: AppTheme.accentColor),
              title: Text('Open in Reader', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _openAnnotationInReader(annotation);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteAnnotation(annotation);
              },
            ),
            SizedBox(height: 2.h),
          ],
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.draw_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No annotations yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              'Annotations from your documents will appear here',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
            icon: const Icon(Icons.library_books, color: Colors.white, size: 20),
            label: const Text(
              'Open Library',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Sort By',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSortOption('Date Created', Icons.calendar_today),
            _buildSortOption('Document', Icons.description),
            _buildSortOption('Type', Icons.category),
            _buildSortOption('Page Number', Icons.numbers),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(title, style: TextStyle(color: AppTheme.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        // TODO: Implement sorting
      },
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.yellow;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
