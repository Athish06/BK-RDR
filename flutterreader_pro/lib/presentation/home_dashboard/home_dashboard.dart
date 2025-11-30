import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
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
    final continueReading = await _documentService.getContinueReadingDocuments();
    final recent = await _documentService.getRecentDocuments();
    
    if (mounted) {
      setState(() {
        _continueReadingBooks = continueReading;
        _recentBooks = recent;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.mediumImpact();
    await _loadData();

    setState(() {
      _isRefreshing = false;
    });

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

  void _showImportOptions() {
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
              title: 'Device Files',
              subtitle: 'Browse files on your device',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pdf-library');
              },
            ),
            _buildImportOption(
              icon: 'cloud_upload',
              title: 'Cloud Storage',
              subtitle: 'Import from Google Drive, Dropbox',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pdf-library');
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  'Good ${_getGreeting()}!',
                  style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Ready to continue your reading journey?',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔥 7-day streak',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'auto_stories',
            color: Colors.white.withValues(alpha: 0.8),
            size: 48,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: 'schedule',
              title: 'Today',
              value: '45 min',
              subtitle: 'Reading time',
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildStatCard(
              icon: 'auto_stories',
              title: 'Progress',
              value: '23',
              subtitle: 'Pages read',
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildStatCard(
              icon: 'trending_up',
              title: 'Goal',
              value: '89%',
              subtitle: 'Weekly',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: AppTheme.accentColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildContinueReading() {
    if (_continueReadingBooks.isEmpty) {
      return const SizedBox.shrink();
    }

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
        SizedBox(height: 1.5.h), // Reduced spacing
        SizedBox(
          height: 26.h, // Increased from 22.h to 26.h to fix overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _continueReadingBooks.length,
            itemBuilder: (context, index) {
              final book = _continueReadingBooks[index];
              return _buildBookCard(book);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(DocumentModel book) {
    final progress = book.readingProgress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _handleBookTap(book),
      child: Container(
        width: 40.w,
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover placeholder
            Flexible(
              fit: FlexFit.loose,
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.6),
                      AppTheme.gradientEnd.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'menu_book',
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

            // Book info
            Flexible(
              fit: FlexFit.tight,
              flex: 3, // Increased flex from 2 to 3 to give more space to text
              child: Padding(
                padding: EdgeInsets.all(2.w), // Increased padding slightly
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title + date block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            book.title,
                            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h), // Increased spacing
                          Text(
                            DateFormat.yMMMd().format(book.lastOpened),
                            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Progress block
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                          minHeight: 2,
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

  Widget _buildRecentBooks() {
    if (_recentBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'No recent books',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

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
        SizedBox(height: 1.5.h), // Reduced spacing
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: _recentBooks.length,
          itemBuilder: (context, index) {
            final book = _recentBooks[index];
            return _buildRecentBookTile(book);
          },
        ),
      ],
    );
  }

  Widget _buildRecentBookTile(DocumentModel book) {
    final progress = book.readingProgress.clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h), // Reduced margin to prevent overflow
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        onTap: () => _handleBookTap(book),
        contentPadding: EdgeInsets.all(3.w),
        leading: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accentColor.withValues(alpha: 0.6),
                AppTheme.gradientEnd.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'article',
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Text(
          book.title,
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),
            Text(
              DateFormat.yMMMd().format(book.lastOpened),
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    minHeight: 2,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: CustomIconWidget(
          iconName: 'chevron_right',
          color: AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: CustomAppBar(
        title: 'FlutterReader Pro',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'search',
              color: AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
            tooltip: 'Search documents',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            tooltip: 'Settings',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting header
                _buildGreetingHeader(),

                SizedBox(height: 1.h), // Further reduced spacing

                // Quick stats
                _buildQuickStats(),

                SizedBox(height: 2.h), // Further reduced spacing

                // Continue reading section
                _buildContinueReading(),

                SizedBox(height: 2.h), // Further reduced spacing

                // Recent books
                _buildRecentBooks(),

                SizedBox(height: 4.h), // Further reduced bottom padding to prevent overflow
              ],
            ),
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
          onPressed: _showImportOptions,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: CustomIconWidget(
            iconName: 'add',
            color: Colors.white,
            size: 28,
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
}
