import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _isRefreshing = false;
  final DocumentService _documentService = DocumentService();
  List<DocumentModel> _continueReadingBooks = [];
  List<DocumentModel> _recentBooks = [];
  bool _isLoading = true;
  
  // Reading statistics
  int _totalBooks = 0;
  int _completedBooks = 0;
  int _inProgressBooks = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final allDocs = await _documentService.getAllDocuments();
      final continueReading = await _documentService.getContinueReadingDocuments();
      final recent = await _documentService.getRecentDocuments();
      
      if (mounted) {
        setState(() {
          _continueReadingBooks = continueReading;
          _recentBooks = recent;
          _totalBooks = allDocs.length;
          _completedBooks = allDocs.where((d) => d.status == 'completed').length;
          _inProgressBooks = allDocs.where((d) => d.status == 'in_progress').length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    await _loadData();
    setState(() => _isRefreshing = false);
    HapticFeedback.lightImpact();
  }

  void _handleBookTap(DocumentModel book) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context, 
      '/pdf-reader',
      arguments: book,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.accentColor,
          backgroundColor: AppTheme.surfaceColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.primaryDark,
                elevation: 0,
                title: Text(
                  'FlutterReader',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
                    tooltip: 'Search',
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              
              // Content
              SliverToBoxAdapter(
                child: _isLoading 
                    ? _buildLoadingState()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add PDF',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        variant: CustomBottomBarVariant.magnetic,
        currentIndex: 0,
        enableHapticFeedback: true,
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 60.h,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        _buildGreetingSection(),
        
        SizedBox(height: 2.h),
        
        // Quick Stats
        _buildStatsSection(),
        
        SizedBox(height: 3.h),
        
        // Continue Reading
        if (_continueReadingBooks.isNotEmpty) ...[
          _buildSectionHeader('Continue Reading', onViewAll: () {
            Navigator.pushNamed(context, '/pdf-library');
          }),
          SizedBox(height: 1.5.h),
          _buildContinueReadingList(),
          SizedBox(height: 3.h),
        ],
        
        // Recent Books
        if (_recentBooks.isNotEmpty) ...[
          _buildSectionHeader('Recently Opened'),
          SizedBox(height: 1.5.h),
          _buildRecentBooksList(),
        ],
        
        // Empty State
        if (_continueReadingBooks.isEmpty && _recentBooks.isEmpty)
          _buildEmptyState(),
        
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            _totalBooks > 0 
                ? 'You have $_totalBooks documents in your library'
                : 'Add PDFs to start reading',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(
            icon: Icons.library_books,
            label: 'Total',
            value: _totalBooks.toString(),
            color: AppTheme.accentColor,
          )),
          SizedBox(width: 3.w),
          Expanded(child: _buildStatCard(
            icon: Icons.auto_stories,
            label: 'Reading',
            value: _inProgressBooks.toString(),
            color: AppTheme.warningColor,
          )),
          SizedBox(width: 3.w),
          Expanded(child: _buildStatCard(
            icon: Icons.check_circle_outline,
            label: 'Done',
            value: _completedBooks.toString(),
            color: AppTheme.successColor,
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingList() {
    return SizedBox(
      height: 20.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _continueReadingBooks.length,
        itemBuilder: (context, index) {
          final book = _continueReadingBooks[index];
          return _buildContinueReadingCard(book);
        },
      ),
    );
  }

  Widget _buildContinueReadingCard(DocumentModel book) {
    final progress = book.readingProgress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _handleBookTap(book),
      child: Container(
        width: 45.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.accentColor,
                    size: 36,
                  ),
                ),
              ),
            ),
            
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              book.status == 'completed' ? 'Completed' : 'In Progress',
                              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                            minHeight: 3,
                          ),
                        ),
                      ],
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

  Widget _buildRecentBooksList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _recentBooks.take(5).length,
      itemBuilder: (context, index) {
        final book = _recentBooks[index];
        return _buildRecentBookTile(book);
      },
    );
  }

  Widget _buildRecentBookTile(DocumentModel book) {
    return GestureDetector(
      onTap: () => _handleBookTap(book),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: AppTheme.accentColor,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Last opened ${_formatDate(book.lastOpened)}',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.MMMd().format(date);
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_books_outlined,
            color: AppTheme.accentColor,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Your library is empty',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add PDF documents to start reading\nand annotating',
            textAlign: TextAlign.center,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 3.h),
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
            icon: const Icon(Icons.add),
            label: const Text('Add PDF'),
          ),
        ],
      ),
    );
  }
}
