import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PdfSearchOverlay extends StatefulWidget {
  final bool isVisible;
  final String searchQuery;
  final int currentMatch;
  final int totalMatches;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onPreviousMatch;
  final VoidCallback? onNextMatch;
  final VoidCallback? onClose;

  const PdfSearchOverlay({
    super.key,
    required this.isVisible,
    required this.searchQuery,
    required this.currentMatch,
    required this.totalMatches,
    this.onSearchChanged,
    this.onPreviousMatch,
    this.onNextMatch,
    this.onClose,
  });

  @override
  State<PdfSearchOverlay> createState() => _PdfSearchOverlayState();
}

class _PdfSearchOverlayState extends State<PdfSearchOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
      begin: const Offset(0, -1),
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

    _searchController.text = widget.searchQuery;

    if (widget.isVisible) {
      _slideController.forward();
      _fadeController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(PdfSearchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
        _fadeController.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _slideController.reverse();
        _fadeController.reverse();
        _searchFocusNode.unfocus();
      }
    }

    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String query) {
    widget.onSearchChanged?.call(query);
  }

  void _handlePreviousMatch() {
    HapticFeedback.lightImpact();
    widget.onPreviousMatch?.call();
  }

  void _handleNextMatch() {
    HapticFeedback.lightImpact();
    widget.onNextMatch?.call();
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientDecoration().gradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search input row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _handleSearchChanged,
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search in document...',
                                hintStyle: AppTheme
                                    .darkTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                prefixIcon: CustomIconWidget(
                                  iconName: 'search',
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _handleSearchChanged('');
                                        },
                                        child: CustomIconWidget(
                                          iconName: 'clear',
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          size: 20,
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
                        ),
                        SizedBox(width: 2.w),
                        GestureDetector(
                          onTap: _handleClose,
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

                    // Search results and navigation
                    if (widget.searchQuery.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          // Results counter
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.totalMatches > 0
                                  ? '${widget.currentMatch} of ${widget.totalMatches}'
                                  : 'No matches',
                              style: AppTheme.dataTextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Navigation buttons
                          if (widget.totalMatches > 0) ...[
                            GestureDetector(
                              onTap: widget.currentMatch > 1
                                  ? _handlePreviousMatch
                                  : null,
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: widget.currentMatch > 1
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'keyboard_arrow_up',
                                  color: widget.currentMatch > 1
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            GestureDetector(
                              onTap: widget.currentMatch < widget.totalMatches
                                  ? _handleNextMatch
                                  : null,
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color:
                                      widget.currentMatch < widget.totalMatches
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'keyboard_arrow_down',
                                  color:
                                      widget.currentMatch < widget.totalMatches
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
