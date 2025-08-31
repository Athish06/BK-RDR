import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ShelfWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> documents;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Function(Map<String, dynamic>) onDocumentTap;
  final Function(Map<String, dynamic>) onDocumentLongPress;
  final Function(Map<String, dynamic>, String) onMoveDocument;
  final bool isGridView;
  final bool isDragMode;

  const ShelfWidget({
    super.key,
    required this.title,
    required this.documents,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDocumentTap,
    required this.onDocumentLongPress,
    required this.onMoveDocument,
    required this.isGridView,
    required this.isDragMode,
  });

  @override
  State<ShelfWidget> createState() => _ShelfWidgetState();
}

class _ShelfWidgetState extends State<ShelfWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ShelfWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildShelfHeader(),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                child: widget.documents.isEmpty
                    ? _buildEmptyState()
                    : widget.isGridView
                        ? _buildGridView()
                        : _buildListView(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShelfHeader() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggleExpanded();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          gradient: _getShelfGradient(),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 8.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: _getShelfIcon(),
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.documents.length} documents',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 3.14159,
                  child: CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'folder_open',
            color: AppTheme.textSecondary,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No documents in ${widget.title}',
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Drag documents here or tap "+" to add',
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 0.75,
        ),
        itemCount: widget.documents.length,
        itemBuilder: (context, index) {
          final document = widget.documents[index];
          return _buildDocumentCard(document, index);
        },
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.documents.length,
        itemBuilder: (context, index) {
          final document = widget.documents[index];
          return _buildDocumentListItem(document, index);
        },
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document, int index) {
    return GestureDetector(
      onTap: () => widget.onDocumentTap(document),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onDocumentLongPress(document);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentColor.withValues(alpha: 0.1),
              AppTheme.gradientEnd.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: CustomIconWidget(
                        iconName: 'picture_as_pdf',
                        color: AppTheme.errorColor,
                        size: 32,
                      ),
                    ),
                    if (document['readingProgress'] != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.2),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                (document['readingProgress'] as double) / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient:
                                    AppTheme.gradientDecoration().gradient,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document['title'] as String,
                      style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'access_time',
                          color: AppTheme.textSecondary,
                          size: 12,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            document['lastOpened'] as String,
                            style: AppTheme.darkTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildDocumentListItem(Map<String, dynamic> document, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () => widget.onDocumentTap(document),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onDocumentLongPress(document);
        },
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 6.h,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientDecoration().gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'picture_as_pdf',
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document['title'] as String,
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Text(
                        document['fileSize'] as String,
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        document['lastOpened'] as String,
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (document['readingProgress'] != null) ...[
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor:
                                  (document['readingProgress'] as double) / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient:
                                      AppTheme.gradientDecoration().gradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${document['readingProgress']}%',
                          style: AppTheme.dataTextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'more_vert',
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getShelfGradient() {
    switch (widget.title) {
      case 'Favorites':
        return LinearGradient(
          colors: [
            AppTheme.warningColor,
            AppTheme.warningColor.withValues(alpha: 0.8),
          ],
        );
      case 'In Progress':
        return LinearGradient(
          colors: [
            AppTheme.accentColor,
            AppTheme.gradientEnd,
          ],
        );
      case 'Completed':
        return LinearGradient(
          colors: [
            AppTheme.successColor,
            AppTheme.successColor.withValues(alpha: 0.8),
          ],
        );
      default:
        return AppTheme.gradientDecoration().gradient as LinearGradient;
    }
  }

  String _getShelfIcon() {
    switch (widget.title) {
      case 'Favorites':
        return 'favorite';
      case 'In Progress':
        return 'schedule';
      case 'Completed':
        return 'check_circle';
      default:
        return 'folder';
    }
  }
}
