import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentActionSheetWidget extends StatefulWidget {
  final Map<String, dynamic> document;
  final Function(String) onMoveToShelf;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onProperties;
  final VoidCallback onAddToFavorites;

  const DocumentActionSheetWidget({
    super.key,
    required this.document,
    required this.onMoveToShelf,
    required this.onDelete,
    required this.onShare,
    required this.onProperties,
    required this.onAddToFavorites,
  });

  @override
  State<DocumentActionSheetWidget> createState() =>
      _DocumentActionSheetWidgetState();
}

class _DocumentActionSheetWidgetState extends State<DocumentActionSheetWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _shelves = ['Favorites', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildActionsList(),
                    _buildMoveToShelfSection(),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientDecoration().gradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
                  widget.document['title'] as String,
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.document['fileSize']} • ${widget.document['lastOpened']}',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _closeActionSheet,
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
    );
  }

  Widget _buildActionsList() {
    final actions = [
      {
        'icon': 'open_in_new',
        'title': 'Open Document',
        'subtitle': 'Continue reading',
        'color': AppTheme.accentColor,
        'onTap': () {
          _closeActionSheet();
          Navigator.pushNamed(context, '/pdf-reader');
        },
      },
      {
        'icon': 'favorite_border',
        'title': 'Add to Favorites',
        'subtitle': 'Quick access',
        'color': AppTheme.warningColor,
        'onTap': () {
          widget.onAddToFavorites();
          _closeActionSheet();
        },
      },
      {
        'icon': 'share',
        'title': 'Share Document',
        'subtitle': 'Send to others',
        'color': AppTheme.successColor,
        'onTap': () {
          widget.onShare();
          _closeActionSheet();
        },
      },
      {
        'icon': 'info_outline',
        'title': 'Properties',
        'subtitle': 'View details',
        'color': AppTheme.textSecondary,
        'onTap': () {
          widget.onProperties();
          _closeActionSheet();
        },
      },
      {
        'icon': 'delete_outline',
        'title': 'Delete Document',
        'subtitle': 'Remove from library',
        'color': AppTheme.errorColor,
        'onTap': () {
          _showDeleteConfirmation();
        },
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: actions.map((action) => _buildActionItem(action)).toList(),
      ),
    );
  }

  Widget _buildActionItem(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        action['onTap']();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: (action['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: action['icon'] as String,
                color: action['color'] as Color,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action['title'] as String,
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    action['subtitle'] as String,
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveToShelfSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move to Shelf',
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: _shelves.map((shelf) => _buildShelfChip(shelf)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfChip(String shelf) {
    Color chipColor;
    String iconName;

    switch (shelf) {
      case 'Favorites':
        chipColor = AppTheme.warningColor;
        iconName = 'favorite';
        break;
      case 'In Progress':
        chipColor = AppTheme.accentColor;
        iconName = 'schedule';
        break;
      case 'Completed':
        chipColor = AppTheme.successColor;
        iconName = 'check_circle';
        break;
      default:
        chipColor = AppTheme.textSecondary;
        iconName = 'folder';
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onMoveToShelf(shelf);
          _closeActionSheet();
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: chipColor,
                size: 20,
              ),
              SizedBox(height: 0.5.h),
              Text(
                shelf,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: chipColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Document',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.document['title']}"? This action cannot be undone.',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
              _closeActionSheet();
            },
            child: Text(
              'Delete',
              style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeActionSheet() {
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }
}
