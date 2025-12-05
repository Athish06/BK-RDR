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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final continueReading = await _documentService.getContinueReadingDocuments();
      final recent = await _documentService.getRecentDocuments();
      
      if (mounted) {
        setState(() {
          _continueReadingBooks = continueReading.take(3).toList(); // Max 3
          _recentBooks = recent.take(3).toList(); // Max 3
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

  void _handleBookTap(DocumentModel book) async {
    HapticFeedback.lightImpact();
    await Navigator.pushNamed(
      context, 
      '/pdf-reader',
      arguments: book,
    );
    // Refresh data when returning from reader
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'BK-RDR',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.accentColor,
          backgroundColor: AppTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _isLoading 
                ? _buildLoadingState()
                : _buildContent(),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientDecoration().gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 28),
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
        // Purple Greeting Box - Just "Hey, Athish!"
        _buildGreetingHeader(),

        SizedBox(height: 2.h),

        // Continue Reading - 2-3 horizontal cards
        if (_continueReadingBooks.isNotEmpty) ...[
          _buildContinueReading(),
          SizedBox(height: 2.h),
        ],

        // Recently Opened - Grid layout (2 per row, max 3)
        if (_recentBooks.isNotEmpty)
          _buildRecentBooksGrid(),

        // Empty State
        if (_continueReadingBooks.isEmpty && _recentBooks.isEmpty)
          _buildEmptyState(),

        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildGreetingHeader() {
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
                  'Hey, Athish!',
                  style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ready to continue your reading journey?',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.menu_book_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Reading',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
                child: Text(
                  'View All',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.5.h),
        SizedBox(
          height: 22.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _continueReadingBooks.length.clamp(0, 3),
            itemBuilder: (context, index) {
              final book = _continueReadingBooks[index];
              return _buildContinueReadingCard(book);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingCard(DocumentModel book) {
    final progress = book.readingProgress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _handleBookTap(book),
      child: Container(
        width: 38.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.7),
                      AppTheme.gradientEnd.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.menu_book, color: Colors.white, size: 32),
                ),
              ),
            ),
            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          'Page ${book.lastPage}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
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

  Widget _buildRecentBooksGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Recently Opened',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate items per row based on screen width
              final itemWidth = (constraints.maxWidth - 3.w) / 2;
              
              return Wrap(
                spacing: 3.w,
                runSpacing: 2.h,
                children: _recentBooks.take(3).map((book) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildRecentBookGridItem(book),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookGridItem(DocumentModel book) {
    final progress = book.readingProgress.clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: () => _handleBookTap(book),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentColor.withValues(alpha: 0.7),
                    AppTheme.gradientEnd.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.description, color: Colors.white, size: 20),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      minHeight: 3,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
            'Add PDF documents to start reading',
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
