import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSearchWidget extends StatefulWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;

  const SettingsSearchWidget({
    super.key,
    this.onSearchChanged,
    this.onSearchClear,
  });

  @override
  State<SettingsSearchWidget> createState() => _SettingsSearchWidgetState();
}

class _SettingsSearchWidgetState extends State<SettingsSearchWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _searchController.addListener(() {
      final query = _searchController.text;
      widget.onSearchChanged?.call(query);
      setState(() {
        _isSearchActive = query.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchClear?.call();
    setState(() {
      _isSearchActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearchActive
                    ? AppTheme.accentColor.withValues(alpha: 0.3)
                    : AppTheme.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: _isSearchActive
                  ? [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _searchController,
              onTap: () {
                _animationController.forward();
              },
              onTapOutside: (_) {
                _animationController.reverse();
              },
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search settings...',
                hintStyle: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: _isSearchActive
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                suffixIcon: _isSearchActive
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'close',
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 2.h,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
