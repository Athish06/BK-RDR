import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum CustomTabBarVariant {
  standard,
  pills,
  underline,
  segmented,
}

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final CustomTabBarVariant variant;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;
  final bool isScrollable;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool enableHapticFeedback;
  final double? height;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.variant = CustomTabBarVariant.standard,
    this.initialIndex = 0,
    this.onTabChanged,
    this.isScrollable = false,
    this.padding,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.enableHapticFeedback = true,
    this.height,
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  // Document-related tabs with navigation routes
  final Map<String, String> _tabRoutes = {
    'Recent': '/home-dashboard',
    'Library': '/pdf-library',
    'Reader': '/pdf-reader',
    'Annotations': '/annotation-tools',
    'Themes': '/theme-customization',
    'Settings': '/settings',
    'Documents': '/pdf-library',
    'Bookmarks': '/pdf-library',
    'History': '/home-dashboard',
    'Favorites': '/pdf-library',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      initialIndex: widget.initialIndex,
      vsync: this,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }

      widget.onTabChanged?.call(_tabController.index);

      // Navigate to corresponding route if available
      final tabName = widget.tabs[_tabController.index];
      final route = _tabRoutes[tabName];
      if (route != null && mounted) {
        Navigator.pushNamed(context, route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (widget.variant) {
      case CustomTabBarVariant.pills:
        return _buildPillsTabBar(context, isDark);
      case CustomTabBarVariant.underline:
        return _buildUnderlineTabBar(context, isDark);
      case CustomTabBarVariant.segmented:
        return _buildSegmentedTabBar(context, isDark);
      default:
        return _buildStandardTabBar(context, isDark);
    }
  }

  Widget _buildStandardTabBar(BuildContext context, bool isDark) {
    return Container(
      height: widget.height ?? 48,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withAlpha(26),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        labelColor: _getSelectedColor(isDark),
        unselectedLabelColor: _getUnselectedColor(isDark),
        indicatorColor: _getSelectedColor(isDark),
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        tabs: widget.tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildPillsTabBar(BuildContext context, bool isDark) {
    return Container(
      height: widget.height ?? 56,
      padding: widget.padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: _getUnselectedColor(isDark),
        indicator: BoxDecoration(
          gradient: AppTheme.gradientDecoration().gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        tabs: widget.tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildUnderlineTabBar(BuildContext context, bool isDark) {
    return Container(
      height: widget.height ?? 48,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        labelColor: _getSelectedColor(isDark),
        unselectedLabelColor: _getUnselectedColor(isDark),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: _getSelectedColor(isDark),
            width: 3,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        tabs: widget.tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildSegmentedTabBar(BuildContext context, bool isDark) {
    return Container(
      height: widget.height ?? 48,
      margin: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withAlpha(51),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: _getUnselectedColor(isDark),
        indicator: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        tabs: widget.tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case CustomTabBarVariant.pills:
        return AppTheme.surfaceColor;
      case CustomTabBarVariant.segmented:
        return Colors.transparent;
      default:
        return isDark ? AppTheme.primaryDark : AppTheme.backgroundLight;
    }
  }

  Color _getSelectedColor(bool isDark) {
    if (widget.selectedColor != null) return widget.selectedColor!;

    return AppTheme.accentColor;
  }

  Color _getUnselectedColor(bool isDark) {
    if (widget.unselectedColor != null) return widget.unselectedColor!;

    return AppTheme.textSecondary;
  }
}

/// Custom tab bar with animated indicator for reading progress
class CustomReadingTabBar extends StatefulWidget {
  final List<String> chapters;
  final int currentChapter;
  final ValueChanged<int>? onChapterChanged;
  final double? progress;

  const CustomReadingTabBar({
    super.key,
    required this.chapters,
    this.currentChapter = 0,
    this.onChapterChanged,
    this.progress,
  });

  @override
  State<CustomReadingTabBar> createState() => _CustomReadingTabBarState();
}

class _CustomReadingTabBarState extends State<CustomReadingTabBar>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.chapters.length,
      initialIndex: widget.currentChapter,
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _tabController.addListener(_handleChapterChange);
    _progressController.forward();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleChapterChange);
    _tabController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleChapterChange() {
    if (_tabController.indexIsChanging) {
      HapticFeedback.selectionClick();
      widget.onChapterChanged?.call(_tabController.index);
      Navigator.pushNamed(context, '/pdf-reader');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          if (widget.progress != null)
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: AppTheme.gradientDecoration().gradient,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: AppTheme.gradientDecoration().gradient,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Chapter tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.accentColor,
            indicatorWeight: 2,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.25,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.25,
            ),
            tabs: widget.chapters.asMap().entries.map((entry) {
              final index = entry.key;
              final chapter = entry.value;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${index + 1}. $chapter'),
                    if (index < widget.currentChapter) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
