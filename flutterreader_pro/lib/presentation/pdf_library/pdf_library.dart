import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/document_action_sheet_widget.dart';
import './widgets/filter_modal_widget.dart';
import './widgets/library_header_widget.dart';
import './widgets/library_statistics_widget.dart';
import './widgets/shelf_widget.dart';

class PdfLibrary extends StatefulWidget {
  const PdfLibrary({super.key});

  @override
  State<PdfLibrary> createState() => _PdfLibraryState();
}

class _PdfLibraryState extends State<PdfLibrary> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _refreshController;
  late Animation<double> _fabAnimation;
  late Animation<double> _refreshAnimation;

  final DocumentService _documentService = DocumentService();
  
  String _searchQuery = '';
  bool _isGridView = true;
  bool _isBulkSelectionMode = false;
  bool _isRefreshing = false;
  String _selectedSortBy = 'Date Added';
  bool _isAscending = true;
  List<String> _selectedStatuses = [];
  Set<String> _selectedDocuments = {};

  final Map<String, bool> _shelfExpansionState = {
    'Favorites': true,
    'In Progress': true,
    'Completed': false,
    'Recent': true,
  };

  // Real document data
  Map<String, List<DocumentModel>> _documentShelves = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final documents = await _documentService.getAllDocuments();
      
      setState(() {
        _documentShelves = {
          'Favorites': documents.where((doc) => doc.isFavorite).toList(),
          'In Progress': documents.where((doc) => doc.status == 'in_progress').toList(),
          'Completed': documents.where((doc) => doc.status == 'completed').toList(),
          'Recent': documents.where((doc) {
            final daysDiff = DateTime.now().difference(doc.lastOpened).inDays;
            return daysDiff <= 7;
          }).toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            LibraryHeaderWidget(
              searchQuery: _searchQuery,
              onSearchChanged: _handleSearchChanged,
              onFilterPressed: _showFilterModal,
              isGridView: _isGridView,
              onViewToggle: _handleViewToggle,
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading documents...',
                            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppTheme.accentColor,
                      backgroundColor: AppTheme.surfaceColor,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: LibraryStatisticsWidget(
                              totalDocuments: _getTotalDocuments(),
                              totalSizeGB: _getTotalSizeGB(),
                              readingProgress: _getOverallProgress(),
                              completedDocuments: _getCompletedDocuments(),
                            ),
                          ),
                          ..._buildShelfSlivers(),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 10.h),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Import Documents FAB
          FloatingActionButton(
            heroTag: "import_fab",
            onPressed: _handleImportFiles,
            backgroundColor: AppTheme.accentColor,
            foregroundColor: AppTheme.textPrimary,
            child: Icon(Icons.add),
            tooltip: 'Import Documents',
          ),
          SizedBox(height: 16),
          // Bulk Selection FAB
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  List<Widget> _buildShelfSlivers() {
    final filteredShelves = _getFilteredShelves();
    return filteredShelves.entries.map((entry) {
      final shelfName = entry.key;
      final documents = entry.value;

      return SliverToBoxAdapter(
        child: ShelfWidget(
          title: shelfName,
          documents: documents.map((doc) => doc.toJson()).toList(),
          isExpanded: _shelfExpansionState[shelfName] ?? false,
          onToggleExpanded: () => _toggleShelfExpansion(shelfName),
          onDocumentTap: (docMap) => _handleDocumentTap(documents.firstWhere((d) => d.id == docMap['id'])),
          onDocumentLongPress: (docMap) => _handleDocumentLongPress(documents.firstWhere((d) => d.id == docMap['id'])),
          onMoveDocument: (docMap, shelf) => _handleMoveDocument(documents.firstWhere((d) => d.id == docMap['id']), shelf),
          isGridView: _isGridView,
          isDragMode: _isBulkSelectionMode,
        ),
      );
    }).toList();
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_fabAnimation.value * 0.3),
          child: FloatingActionButton.extended(
            onPressed:
                _isBulkSelectionMode ? _exitBulkSelection : _enterBulkSelection,
            backgroundColor: _isBulkSelectionMode
                ? AppTheme.errorColor
                : AppTheme.accentColor,
            foregroundColor: AppTheme.textPrimary,
            elevation: 8,
            icon: CustomIconWidget(
              iconName: _isBulkSelectionMode ? 'close' : 'checklist',
              color: AppTheme.textPrimary,
              size: 20,
            ),
            label: Text(
              _isBulkSelectionMode ? 'Cancel' : 'Select',
              style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, List<DocumentModel>> _getFilteredShelves() {
    Map<String, List<DocumentModel>> filteredShelves = {};

    _documentShelves.forEach((shelfName, documents) {
      List<DocumentModel> filteredDocs = documents.where((doc) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final title = doc.title.toLowerCase();
          if (!title.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Status filter
        if (_selectedStatuses.isNotEmpty) {
          if (!_selectedStatuses.contains(doc.status)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort documents
      filteredDocs.sort((a, b) {
        int comparison = 0;
        switch (_selectedSortBy) {
          case 'Name':
            comparison = a.title.compareTo(b.title);
            break;
          case 'File Size':
            comparison = a.fileSize.compareTo(b.fileSize);
            break;
          case 'Reading Progress':
            comparison = a.readingProgress.compareTo(b.readingProgress);
            break;
          case 'Date Added':
          default:
            comparison = a.dateAdded.compareTo(b.dateAdded);
            break;
        }

        return _isAscending ? comparison : -comparison;
      });

      if (filteredDocs.isNotEmpty) {
        filteredShelves[shelfName] = filteredDocs;
      }
    });

    return filteredShelves;
  }

  int _getTotalDocuments() {
    return _documentShelves.values.expand((docs) => docs).length;
  }

  double _getTotalSizeGB() {
    double totalBytes = 0;
    _documentShelves.values.expand((docs) => docs).forEach((doc) {
      totalBytes += doc.fileSize;
    });
    return totalBytes / (1024 * 1024 * 1024);
  }

  int _getOverallProgress() {
    final allDocs = _documentShelves.values.expand((docs) => docs).toList();
    if (allDocs.isEmpty) return 0;

    double totalProgress = 0;
    for (final doc in allDocs) {
      totalProgress += doc.readingProgress;
    }

    return (totalProgress / allDocs.length).round();
  }

  int _getCompletedDocuments() {
    return _documentShelves.values
        .expand((docs) => docs)
        .where((doc) => doc.readingProgress >= 100.0)
        .length;
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _handleViewToggle(bool isGridView) {
    HapticFeedback.lightImpact();
    setState(() {
      _isGridView = isGridView;
    });
  }

  void _toggleShelfExpansion(String shelfName) {
    setState(() {
      _shelfExpansionState[shelfName] =
          !(_shelfExpansionState[shelfName] ?? false);
    });
  }

  void _handleDocumentTap(DocumentModel document) {
    if (_isBulkSelectionMode) {
      _toggleDocumentSelection(document.id);
    } else {
      Navigator.pushNamed(context, '/pdf-reader');
    }
  }

  void _handleDocumentLongPress(DocumentModel document) {
    if (!_isBulkSelectionMode) {
      _showDocumentActionSheet(document);
    }
  }

  void _handleMoveDocument(DocumentModel document, String targetShelf) async {
    HapticFeedback.mediumImpact();
    
    try {
      // Update document status
      String newStatus = document.status;
      if (targetShelf == 'In Progress') {
        newStatus = 'in_progress';
      } else if (targetShelf == 'Completed') {
        newStatus = 'completed';
      }
      
      bool newFavoriteStatus = targetShelf == 'Favorites' ? true : document.isFavorite;
      
      final updatedDocument = document.copyWith(
        status: newStatus,
        isFavorite: newFavoriteStatus,
      );
      
      await _documentService.updateDocument(updatedDocument);
      await _loadDocuments(); // Reload to refresh UI
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved "${document.title}" to $targetShelf'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving document: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _toggleDocumentSelection(String documentId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDocuments.contains(documentId)) {
        _selectedDocuments.remove(documentId);
      } else {
        _selectedDocuments.add(documentId);
      }
    });
  }

  void _enterBulkSelection() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isBulkSelectionMode = true;
    });
    _fabController.forward();
  }

  void _exitBulkSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _isBulkSelectionMode = false;
      _selectedDocuments.clear();
    });
    _fabController.reverse();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();

    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Library refreshed'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showFilterModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModalWidget(
        selectedSortBy: _selectedSortBy,
        isAscending: _isAscending,
        selectedStatuses: _selectedStatuses,
        onApplyFilters: _handleApplyFilters,
      ),
    );
  }

  void _handleApplyFilters(
      String sortBy, bool isAscending, List<String> statuses) {
    setState(() {
      _selectedSortBy = sortBy;
      _isAscending = isAscending;
      _selectedStatuses = statuses;
    });
  }

  void _showDocumentActionSheet(DocumentModel document) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentActionSheetWidget(
        document: document.toJson(), // Convert to Map for existing widget
        onMoveToShelf: (shelf) => _handleMoveDocument(document, shelf),
        onDelete: () => _handleDeleteDocument(document),
        onShare: () => _handleShareDocument(document),
        onProperties: () => _handleShowProperties(document),
        onAddToFavorites: () => _handleAddToFavorites(document),
      ),
    );
  }

  void _handleDeleteDocument(DocumentModel document) async {
    HapticFeedback.mediumImpact();
    
    try {
      await _documentService.deleteDocument(document.id);
      await _loadDocuments(); // Reload to refresh UI
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${document.title}"'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppTheme.textPrimary,
              onPressed: () {
                // TODO: Implement undo functionality
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleShareDocument(DocumentModel document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${document.title}"'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleShowProperties(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Document Properties',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPropertyRow('Title', document.title),
            _buildPropertyRow('File Size', document.formattedFileSize),
            _buildPropertyRow('Reading Progress', '${document.readingProgress.toInt()}%'),
            _buildPropertyRow('Status', document.status),
            _buildPropertyRow('Date Added', document.dateAdded.toString().split(' ')[0]),
            _buildPropertyRow('Last Opened', document.lastOpenedFormatted),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddToFavorites(DocumentModel document) async {
    try {
      if (!document.isFavorite) {
        final updatedDocument = document.copyWith(isFavorite: true);
        await _documentService.updateDocument(updatedDocument);
        await _loadDocuments(); // Reload to refresh UI
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${document.title}" to Favorites'),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to favorites: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Show import options
  void _handleImportFiles() {
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
            Container(
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Import PDF',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            _buildImportOption(
              icon: 'folder',
              title: 'Local Storage',
              subtitle: 'Browse files on your device',
              onTap: () {
                Navigator.pop(context);
                _importFiles();
              },
            ),
            _buildImportOption(
              icon: 'cloud_upload',
              title: 'Google Drive',
              subtitle: 'Import from Google Drive',
              onTap: () {
                Navigator.pop(context);
                _importFiles(); // FilePicker handles Drive on mobile
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientDecoration().gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }

  // Actual file import functionality
  void _importFiles() async {
    try {
      final importedDocuments = await _documentService.pickAndImportDocuments();
      if (importedDocuments != null && importedDocuments.isNotEmpty) {
        await _loadDocuments(); // Reload to show new documents
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${importedDocuments.length} document(s)'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing files: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
