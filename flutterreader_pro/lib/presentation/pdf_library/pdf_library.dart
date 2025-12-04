import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

class PdfLibrary extends StatefulWidget {
  const PdfLibrary({super.key});

  @override
  State<PdfLibrary> createState() => _PdfLibraryState();
}

class _PdfLibraryState extends State<PdfLibrary> with SingleTickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  final FolderService _folderService = FolderService();
  
  String _searchQuery = '';
  bool _isGridView = true;
  bool _isLoading = true;
  String? _currentFolderId;
  List<FolderModel> _breadcrumbs = [];
  String _sortBy = 'recent'; // recent, name, size
  String _filterBy = 'all'; // all, favorites, reading
  
  List<DocumentModel> _documents = [];
  List<FolderModel> _folders = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Always use getDocumentsInFolder - it gets root documents when folderId is null
      // This prevents showing documents that are inside folders at the root level
      final docs = await _documentService.getDocumentsInFolder(_currentFolderId);
      final folders = await _folderService.getFolders(parentId: _currentFolderId);
      
      setState(() {
        _documents = docs;
        _folders = folders;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadData();
  }

  void _handleDocumentTap(DocumentModel doc) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/pdf-reader', arguments: doc);
  }

  Future<void> _importDocuments() async {
    _showLoadingDialog('Picking files...');
    
    try {
      final files = await _documentService.pickFiles();
      
      if (files == null || files.isEmpty) {
        Navigator.pop(context);
        return;
      }
      
      Navigator.pop(context);
      _showLoadingDialog('Uploading ${files.length} file(s)...');
      
      final documents = await _documentService.importDocuments(files, folderId: _currentFolderId);
      Navigator.pop(context);
      
      if (documents != null && documents.isNotEmpty) {
        await _loadData();
        _showSuccessSnackBar('${documents.length} document(s) imported');
      } else {
        _showErrorSnackBar('Failed to import documents');
      }
    } catch (e) {
      try { Navigator.pop(context); } catch (_) {}
      _showErrorSnackBar('Import failed: ${e.toString()}');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentColor,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.create_new_folder, color: Colors.amber, size: 20),
            ),
            SizedBox(width: 12),
            Text('New Folder', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter folder name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.primaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _createFolder(controller.text.trim());
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder(String name) async {
    try {
      _showLoadingDialog('Creating folder...');
      await _folderService.createFolder(name: name, parentId: _currentFolderId);
      Navigator.pop(context);
      await _loadData();
      _showSuccessSnackBar('Folder "$name" created');
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Failed to create folder: $e');
    }
  }

  void _navigateToFolder(FolderModel folder) {
    HapticFeedback.lightImpact();
    setState(() {
      _breadcrumbs.add(folder);
      _currentFolderId = folder.id;
    });
    _loadData();
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    if (_breadcrumbs.isNotEmpty) {
      _breadcrumbs.removeLast();
      setState(() {
        _currentFolderId = _breadcrumbs.isEmpty ? null : _breadcrumbs.last.id;
      });
      _loadData();
    }
  }

  void _navigateToBreadcrumb(int index) {
    HapticFeedback.lightImpact();
    if (index == -1) {
      setState(() {
        _breadcrumbs = [];
        _currentFolderId = null;
      });
    } else {
      setState(() {
        _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
        _currentFolderId = _breadcrumbs[index].id;
      });
    }
    _loadData();
  }

  List<DocumentModel> get _filteredDocuments {
    var docs = _documents.where((doc) {
      // Search filter
      if (_searchQuery.isNotEmpty && 
          !doc.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      // Category filter
      if (_filterBy == 'favorites' && !doc.isFavorite) return false;
      if (_filterBy == 'reading' && doc.readingProgress <= 0) return false;
      return true;
    }).toList();
    
    // Sort
    switch (_sortBy) {
      case 'name':
        docs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'size':
        docs.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case 'recent':
      default:
        docs.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    }
    
    return docs;
  }

  List<FolderModel> get _filteredFolders {
    if (_searchQuery.isEmpty) return _folders;
    return _folders.where((folder) =>
      folder.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Search and filters
            _buildSearchAndFilters(),
            
            // Breadcrumbs
            if (_breadcrumbs.isNotEmpty) _buildBreadcrumbs(),
            
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppTheme.accentColor,
                      child: _buildContent(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
    final totalDocs = _filteredDocuments.length;
    final totalFolders = _filteredFolders.length;
    final hasActiveFilter = _filterBy != 'all' || _searchQuery.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
      child: Row(
        children: [
          // Back button if in folder
          if (_breadcrumbs.isNotEmpty) ...[
            GestureDetector(
              onTap: _navigateBack,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
              ),
            ),
            SizedBox(width: 3.w),
          ],
          
          // Title and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _breadcrumbs.isNotEmpty ? _breadcrumbs.last.name : 'Library',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$totalDocs documents${totalFolders > 0 ? ' • $totalFolders folders' : ''}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // View toggle
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggleButton(Icons.grid_view_rounded, true),
                SizedBox(width: 4),
                _buildViewToggleButton(Icons.view_list_rounded, false),
              ],
            ),
          ),
          
          SizedBox(width: 2.w),
          
          // New folder button
          GestureDetector(
            onTap: _showCreateFolderDialog,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.create_new_folder_outlined, color: AppTheme.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isGrid) {
    final isActive = _isGridView == isGrid;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isGridView = isGrid);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppTheme.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search documents and folders...',
                hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          SizedBox(height: 1.5.h),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Icons.apps_rounded),
                SizedBox(width: 2.w),
                _buildFilterChip('Favorites', 'favorites', Icons.star_rounded),
                SizedBox(width: 2.w),
                _buildFilterChip('Reading', 'reading', Icons.auto_stories_rounded),
                SizedBox(width: 4.w),
                Container(width: 1, height: 24, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
                SizedBox(width: 4.w),
                _buildSortChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isActive = _filterBy == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterBy = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accentColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppTheme.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    final sortLabels = {
      'recent': 'Recent',
      'name': 'Name',
      'size': 'Size',
    };
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _buildSortSheet(),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: AppTheme.textSecondary),
            SizedBox(width: 6),
            Text(
              sortLabels[_sortBy] ?? 'Sort',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSheet() {
    return Padding(
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
            'Sort By',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSortOption('Recent', 'recent', Icons.access_time_rounded),
          _buildSortOption('Name', 'name', Icons.sort_by_alpha_rounded),
          _buildSortOption('Size', 'size', Icons.data_usage_rounded),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isActive = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.accentColor : AppTheme.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppTheme.accentColor : AppTheme.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isActive ? Icon(Icons.check, color: AppTheme.accentColor) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBreadcrumbs() {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () => _navigateToBreadcrumb(-1),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, color: AppTheme.accentColor, size: 14),
                  SizedBox(width: 4),
                  Text('Home', style: TextStyle(color: AppTheme.accentColor, fontSize: 12)),
                ],
              ),
            ),
          ),
          for (int i = 0; i < _breadcrumbs.length; i++) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 16),
            ),
            GestureDetector(
              onTap: () => _navigateToBreadcrumb(i),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i == _breadcrumbs.length - 1 ? AppTheme.accentColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _breadcrumbs[i].name,
                  style: TextStyle(
                    color: i == _breadcrumbs.length - 1 ? AppTheme.accentColor : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: i == _breadcrumbs.length - 1 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              color: AppTheme.accentColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading documents...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final folders = _filteredFolders;
    final docs = _filteredDocuments;
    
    if (folders.isEmpty && docs.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_isGridView) {
      return _buildGridView(folders, docs);
    } else {
      return _buildListView(folders, docs);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.folder_open_rounded,
              size: 56,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No documents yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Import your first PDF to get started',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _importDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Import PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridView(List<FolderModel> folders, List<DocumentModel> docs) {
    return CustomScrollView(
      slivers: [
        // Folders Section
        if (folders.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder_rounded, color: Colors.amber, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Folders',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${folders.length}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildFolderGridItem(folders[index], index),
                childCount: folders.length,
              ),
            ),
          ),
        ],
        
        // Documents Section
        if (docs.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.h),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description_rounded, color: AppTheme.accentColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Documents',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${docs.length}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildDocumentGridItem(docs[index], index),
                childCount: docs.length,
              ),
            ),
          ),
        ],
        
        // Bottom padding
        SliverPadding(padding: EdgeInsets.only(bottom: 10.h)),
      ],
    );
  }

  Widget _buildListView(List<FolderModel> folders, List<DocumentModel> docs) {
    return CustomScrollView(
      slivers: [
        // Folders Section
        if (folders.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder_rounded, color: Colors.amber, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Folders',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${folders.length}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildFolderListItem(folders[index], index),
                childCount: folders.length,
              ),
            ),
          ),
        ],
        
        // Documents Section
        if (docs.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.h),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description_rounded, color: AppTheme.accentColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Documents',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${docs.length}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildDocumentListItem(docs[index], index),
                childCount: docs.length,
              ),
            ),
          ),
        ],
        
        // Bottom padding
        SliverPadding(padding: EdgeInsets.only(bottom: 10.h)),
      ],
    );
  }

  Widget _buildFolderGridItem(FolderModel folder, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: Interval(
          (index * 0.05).clamp(0, 1),
          ((index * 0.05) + 0.3).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      ),
      child: GestureDetector(
        onTap: () => _navigateToFolder(folder),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.folder_rounded, size: 48, color: Colors.amber),
                  ),
                  SizedBox(height: 1.5.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Text(
                      folder.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showFolderOptions(folder),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.more_horiz, color: AppTheme.textSecondary, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderListItem(FolderModel folder, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: Interval(
          (index * 0.05).clamp(0, 1),
          ((index * 0.05) + 0.3).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: () => _navigateToFolder(folder),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_rounded, size: 28, color: Colors.amber),
          ),
          title: Text(
            folder.name,
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          trailing: GestureDetector(
            onTap: () => _showFolderOptions(folder),
            child: Icon(Icons.more_horiz, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentGridItem(DocumentModel doc, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: Interval(
          (index * 0.05).clamp(0, 1),
          ((index * 0.05) + 0.3).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      ),
      child: GestureDetector(
        onTap: () => _handleDocumentTap(doc),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Thumbnail area
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withValues(alpha: 0.1),
                            Colors.red.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.picture_as_pdf_rounded, size: 36, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Info area
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // Progress bar
                          if (doc.readingProgress > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: doc.readingProgress,
                                backgroundColor: AppTheme.primaryDark,
                                valueColor: AlwaysStoppedAnimation(AppTheme.accentColor),
                                minHeight: 4,
                              ),
                            ),
                            SizedBox(height: 6),
                          ],
                          Row(
                            children: [
                              if (doc.isFavorite)
                                Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const Spacer(),
                              Text(
                                _formatFileSize(doc.fileSize),
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // More options
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showDocumentOptions(doc),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.more_horiz, color: AppTheme.textSecondary, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentListItem(DocumentModel doc, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: Interval(
          (index * 0.05).clamp(0, 1),
          ((index * 0.05) + 0.3).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: () => _handleDocumentTap(doc),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.15),
                  Colors.red.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 26)),
          ),
          title: Text(
            doc.title,
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatFileSize(doc.fileSize),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (doc.isFavorite) ...[
                    SizedBox(width: 8),
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  ],
                ],
              ),
              if (doc.readingProgress > 0) ...[
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: doc.readingProgress,
                    backgroundColor: AppTheme.primaryDark,
                    valueColor: AlwaysStoppedAnimation(AppTheme.accentColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
          trailing: GestureDetector(
            onTap: () => _showDocumentOptions(doc),
            child: Icon(Icons.more_horiz, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _importDocuments,
      backgroundColor: AppTheme.accentColor,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Import', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  void _showFolderOptions(FolderModel folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(5.w),
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder_rounded, color: Colors.amber, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildOptionTile(Icons.edit_outlined, 'Rename', AppTheme.textPrimary, () {
              Navigator.pop(context);
              _showRenameFolderDialog(folder);
            }),
            _buildOptionTile(Icons.delete_outline, 'Delete', Colors.red, () {
              Navigator.pop(context);
              _showDeleteFolderDialog(folder);
            }),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(FolderModel folder) {
    final controller = TextEditingController(text: folder.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Folder', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.primaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _folderService.renameFolder(folder.id, controller.text.trim());
                await _loadData();
                _showSuccessSnackBar('Folder renamed');
              }
            },
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Folder?', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'This will delete "${folder.name}" and all its contents. This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _folderService.deleteFolder(folder.id);
              await _loadData();
              _showSuccessSnackBar('Folder deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDocumentOptions(DocumentModel doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(5.w),
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildOptionTile(
              doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              doc.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              doc.isFavorite ? Colors.amber : AppTheme.textPrimary,
              () async {
                Navigator.pop(context);
                await _documentService.toggleFavorite(doc.id, !doc.isFavorite);
                await _loadData();
              },
            ),
            _buildOptionTile(Icons.drive_file_move_outlined, 'Move to Folder', AppTheme.textPrimary, () {
              Navigator.pop(context);
              _showMoveFolderDialog(doc);
            }),
            _buildOptionTile(Icons.edit_outlined, 'Rename', AppTheme.textPrimary, () {
              Navigator.pop(context);
              _showRenameDocumentDialog(doc);
            }),
            _buildOptionTile(Icons.delete_outline, 'Delete', Colors.red, () {
              Navigator.pop(context);
              _showDeleteDocumentDialog(doc);
            }),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showMoveFolderDialog(DocumentModel doc) async {
    final folders = await _folderService.getFolders();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(5.w),
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
              'Move to Folder',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: Icon(Icons.home_rounded, color: AppTheme.accentColor),
              title: Text('Root (No Folder)', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                await _documentService.moveToFolder(doc.id, null);
                await _loadData();
                _showSuccessSnackBar('Document moved to root');
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            ...folders.map((folder) => ListTile(
              leading: Icon(Icons.folder_rounded, color: Colors.amber),
              title: Text(folder.name, style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                await _documentService.moveToFolder(doc.id, folder.id);
                await _loadData();
                _showSuccessSnackBar('Moved to "${folder.name}"');
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  void _showRenameDocumentDialog(DocumentModel doc) {
    final controller = TextEditingController(text: doc.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Document', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Document name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.primaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _documentService.renameDocument(doc.id, controller.text.trim());
                await _loadData();
                _showSuccessSnackBar('Document renamed');
              }
            },
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDocumentDialog(DocumentModel doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Document?', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'This will permanently delete "${doc.title}". This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Deleting...');
              await _documentService.deleteDocument(doc.id);
              Navigator.pop(context);
              await _loadData();
              _showSuccessSnackBar('Document deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
