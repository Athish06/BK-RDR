import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PdfFloatingControls extends StatefulWidget {
  final bool isVisible;
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final bool isAutoScrolling;
  final double autoScrollSpeed;
  final bool isTextReflowMode;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAnnotationTap;
  final VoidCallback? onTTSTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onAutoScrollToggle;
  final ValueChanged<double>? onAutoScrollSpeedChanged;
  final VoidCallback? onTextReflowToggle;
  final ValueChanged<double>? onZoomChanged;

  const PdfFloatingControls({
    super.key,
    required this.isVisible,
    required this.currentPage,
    required this.totalPages,
    required this.zoomLevel,
    this.isAutoScrolling = false,
    this.autoScrollSpeed = 1.0,
    this.isTextReflowMode = false,
    this.onBookmarkTap,
    this.onSearchTap,
    this.onAnnotationTap,
    this.onTTSTap,
    this.onSettingsTap,
    this.onAutoScrollToggle,
    this.onAutoScrollSpeedChanged,
    this.onTextReflowToggle,
    this.onZoomChanged,
  });

  @override
  State<PdfFloatingControls> createState() => _PdfFloatingControlsState();
}

class _PdfFloatingControlsState extends State<PdfFloatingControls>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showSpeedSlider = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isVisible) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(PdfFloatingControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
        _slideController.forward();
      } else {
        _fadeController.reverse();
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleControlTap(VoidCallback? action) {
    HapticFeedback.lightImpact();
    action?.call();
  }

  void _toggleSpeedSlider() {
    setState(() {
      _showSpeedSlider = !_showSpeedSlider;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom navigation bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBottomNavigationBar(),
            ),
          ),
        ),

        // Auto-scroll speed slider
        if (_showSpeedSlider)
          Positioned(
            bottom: 20.h,
            right: 4.w,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSpeedSlider(),
            ),
          ),

        // Page indicator
        Positioned(
          top: 8.h,
          right: 4.w,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildPageIndicator(),
          ),
        ),

        // Zoom controls
        Positioned(
          right: 4.w,
          top: 25.h,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildZoomControls(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientDecoration().gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(
                icon: 'bookmark_border',
                onTap: () => _handleControlTap(widget.onBookmarkTap),
              ),
              _buildNavButton(
                icon: 'search',
                onTap: () => _handleControlTap(widget.onSearchTap),
              ),
              _buildNavButton(
                icon: 'edit',
                onTap: () => _handleControlTap(widget.onAnnotationTap),
              ),
              _buildNavButton(
                icon: widget.isAutoScrolling ? 'pause' : 'play_arrow',
                onTap: () {
                  _handleControlTap(widget.onAutoScrollToggle);
                  if (widget.isAutoScrolling) {
                    _toggleSpeedSlider();
                  }
                },
              ),
              _buildNavButton(
                icon: 'record_voice_over',
                onTap: () => _handleControlTap(widget.onTTSTap),
              ),
              _buildNavButton(
                icon: widget.isTextReflowMode ? 'view_column' : 'view_stream',
                onTap: () => _handleControlTap(widget.onTextReflowToggle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '${widget.currentPage} / ${widget.totalPages}',
        style: AppTheme.dataTextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final newZoom = (widget.zoomLevel + 0.25).clamp(0.5, 3.0);
              widget.onZoomChanged?.call(newZoom);
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'zoom_in',
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            child: Text(
              '${(widget.zoomLevel * 100).round()}%',
              style: AppTheme.dataTextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final newZoom = (widget.zoomLevel - 0.25).clamp(0.5, 3.0);
              widget.onZoomChanged?.call(newZoom);
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'zoom_out',
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSlider() {
    return Container(
      width: 60.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto-scroll Speed',
                style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _toggleSpeedSlider,
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'slow_motion_video',
                color: AppTheme.textSecondary,
                size: 16,
              ),
              Expanded(
                child: Slider(
                  value: widget.autoScrollSpeed,
                  min: 0.1,
                  max: 3.0,
                  divisions: 29,
                  activeColor: AppTheme.accentColor,
                  inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.3),
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    widget.onAutoScrollSpeedChanged?.call(value);
                  },
                ),
              ),
              CustomIconWidget(
                iconName: 'fast_forward',
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
          Text(
            '${widget.autoScrollSpeed.toStringAsFixed(1)}x',
            style: AppTheme.dataTextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
