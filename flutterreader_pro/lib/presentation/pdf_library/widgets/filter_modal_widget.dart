import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterModalWidget extends StatefulWidget {
  final String selectedSortBy;
  final bool isAscending;
  final List<String> selectedStatuses;
  final Function(String, bool, List<String>) onApplyFilters;

  const FilterModalWidget({
    super.key,
    required this.selectedSortBy,
    required this.isAscending,
    required this.selectedStatuses,
    required this.onApplyFilters,
  });

  @override
  State<FilterModalWidget> createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _sortBy = 'Date Added';
  bool _isAscending = true;
  List<String> _selectedStatuses = [];

  final List<String> _sortOptions = [
    'Date Added',
    'Name',
    'File Size',
    'Last Opened',
    'Reading Progress',
  ];

  final List<String> _statusOptions = [
    'Not Started',
    'In Progress',
    'Completed',
    'Favorites',
  ];

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

    _sortBy = widget.selectedSortBy;
    _isAscending = widget.isAscending;
    _selectedStatuses = List.from(widget.selectedStatuses);

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
                constraints: BoxConstraints(
                  maxHeight: 80.h,
                ),
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSortSection(),
                            SizedBox(height: 3.h),
                            _buildStatusSection(),
                            SizedBox(height: 4.h),
                          ],
                        ),
                      ),
                    ),
                    _buildActionButtons(),
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
          CustomIconWidget(
            iconName: 'tune',
            color: AppTheme.textPrimary,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Filter & Sort',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _closeModal,
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

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ..._sortOptions.map((option) => _buildSortOption(option)),
        SizedBox(height: 2.h),
        _buildSortOrderToggle(),
      ],
    );
  }

  Widget _buildSortOption(String option) {
    final isSelected = _sortBy == option;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _sortBy = option;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withValues(alpha: 0.1)
              : AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : AppTheme.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: isSelected
                  ? 'radio_button_checked'
                  : 'radio_button_unchecked',
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                option,
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color:
                      isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOrderToggle() {
    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isAscending = true;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color:
                      _isAscending ? AppTheme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'arrow_upward',
                      color: _isAscending
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Ascending',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: _isAscending
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight:
                            _isAscending ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isAscending = false;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color:
                      !_isAscending ? AppTheme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'arrow_downward',
                      color: !_isAscending
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Descending',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: !_isAscending
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight:
                            !_isAscending ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Status',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ..._statusOptions.map((status) => _buildStatusOption(status)),
      ],
    );
  }

  Widget _buildStatusOption(String status) {
    final isSelected = _selectedStatuses.contains(status);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedStatuses.remove(status);
          } else {
            _selectedStatuses.add(status);
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withValues(alpha: 0.1)
              : AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : AppTheme.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: isSelected ? 'check_box' : 'check_box_outline_blank',
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                status,
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color:
                      isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'Not Started':
        badgeColor = AppTheme.textSecondary;
        break;
      case 'In Progress':
        badgeColor = AppTheme.accentColor;
        break;
      case 'Completed':
        badgeColor = AppTheme.successColor;
        break;
      case 'Favorites':
        badgeColor = AppTheme.warningColor;
        break;
      default:
        badgeColor = AppTheme.textSecondary;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _resetFilters,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Reset',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _applyFilters,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: AppTheme.gradientDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Apply Filters',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _sortBy = 'Date Added';
      _isAscending = true;
      _selectedStatuses.clear();
    });
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();
    widget.onApplyFilters(_sortBy, _isAscending, _selectedStatuses);
    _closeModal();
  }

  void _closeModal() {
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }
}
