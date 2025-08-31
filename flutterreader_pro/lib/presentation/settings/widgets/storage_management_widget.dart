import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StorageManagementWidget extends StatefulWidget {
  const StorageManagementWidget({super.key});

  @override
  State<StorageManagementWidget> createState() =>
      _StorageManagementWidgetState();
}

class _StorageManagementWidgetState extends State<StorageManagementWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isCleaningCache = false;

  final Map<String, dynamic> _storageData = {
    "totalStorage": 2.4, // GB
    "usedStorage": 1.8, // GB
    "pdfLibrary": 1.2, // GB
    "cache": 0.4, // GB
    "annotations": 0.15, // GB
    "themes": 0.05, // GB
    "totalPdfs": 47,
    "cacheFiles": 156,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (_storageData["usedStorage"] as double) /
          (_storageData["totalStorage"] as double),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _clearCache() async {
    setState(() {
      _isCleaningCache = true;
    });

    // Simulate cache clearing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _storageData["cache"] = 0.0;
      _storageData["usedStorage"] =
          (_storageData["usedStorage"] as double) - 0.4;
      _storageData["cacheFiles"] = 0;
      _isCleaningCache = false;
    });

    // Update animation
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: (_storageData["usedStorage"] as double) /
          (_storageData["totalStorage"] as double),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cache cleared successfully! Freed 400 MB',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          backgroundColor: AppTheme.surfaceColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStorageHeader(),
          SizedBox(height: 2.h),
          _buildStorageProgress(),
          SizedBox(height: 2.h),
          _buildStorageBreakdown(),
          SizedBox(height: 2.h),
          _buildStorageActions(),
        ],
      ),
    );
  }

  Widget _buildStorageHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomIconWidget(
            iconName: 'storage',
            color: AppTheme.accentColor,
            size: 24,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Storage Management',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                '${_storageData["usedStorage"]} GB of ${_storageData["totalStorage"]} GB used',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageProgress() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used Space',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _progressAnimation.value > 0.8
                          ? [AppTheme.errorColor, AppTheme.warningColor]
                          : [AppTheme.accentColor, AppTheme.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorageBreakdown() {
    final breakdownItems = [
      {
        'label': 'PDF Library',
        'size': _storageData["pdfLibrary"],
        'icon': 'picture_as_pdf',
        'color': AppTheme.accentColor,
      },
      {
        'label': 'Cache Files',
        'size': _storageData["cache"],
        'icon': 'cached',
        'color': AppTheme.warningColor,
      },
      {
        'label': 'Annotations',
        'size': _storageData["annotations"],
        'icon': 'edit',
        'color': AppTheme.successColor,
      },
      {
        'label': 'Themes',
        'size': _storageData["themes"],
        'icon': 'palette',
        'color': AppTheme.gradientEnd,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Breakdown',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        ...breakdownItems.map((item) {
          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 3.w),
                CustomIconWidget(
                  iconName: item['icon'] as String,
                  color: item['color'] as Color,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${(item['size'] as double).toStringAsFixed(2)} GB',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStorageActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCleaningCache ? null : _clearCache,
                icon: _isCleaningCache
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.textPrimary,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'cleaning_services',
                        color: AppTheme.textPrimary,
                        size: 18,
                      ),
                label: Text(
                  _isCleaningCache ? 'Cleaning...' : 'Clear Cache',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/pdf-library');
                },
                icon: CustomIconWidget(
                  iconName: 'folder_open',
                  color: AppTheme.accentColor,
                  size: 18,
                ),
                label: Text(
                  'Manage Files',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.accentColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentColor),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.accentColor,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Cache files help improve app performance but can be safely cleared to free up space.',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
