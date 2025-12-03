import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum CustomBottomBarVariant {
  standard,
  magnetic,
  floating,
  minimal,
}

class CustomBottomBar extends StatefulWidget {
  final CustomBottomBarVariant variant;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final bool showLabels;
  final double? elevation;
  final Color? backgroundColor;
  final bool enableHapticFeedback;
  final EdgeInsets? margin;

  const CustomBottomBar({
    super.key,
    this.variant = CustomBottomBarVariant.standard,
    this.currentIndex = 0,
    this.onTap,
    this.showLabels = false,
    this.elevation,
    this.backgroundColor,
    this.enableHapticFeedback = true,
    this.margin,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _magneticController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Navigation items with routes
  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home-dashboard',
    ),
    _NavigationItem(
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books,
      label: 'Library',
      route: '/pdf-library',
    ),
    _NavigationItem(
      icon: Icons.edit_note_outlined,
      activeIcon: Icons.edit_note,
      label: 'Notes',
      route: '/annotation-tools',
    ),
    _NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _magneticController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _magneticController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (widget.variant) {
      case CustomBottomBarVariant.magnetic:
        return _buildMagneticBottomBar(context, isDark);
      case CustomBottomBarVariant.floating:
        return _buildFloatingBottomBar(context, isDark);
      case CustomBottomBarVariant.minimal:
        return _buildMinimalBottomBar(context, isDark);
      default:
        return _buildStandardBottomBar(context, isDark);
    }
  }

  Widget _buildStandardBottomBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56, // Further reduced from 60 to 56
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Further reduced vertical padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;

              return _buildNavigationItem(
                context,
                item,
                index,
                isSelected,
                isDark,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMagneticBottomBar(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _magneticController,
      builder: (context, child) {
        return Container(
          margin: widget.margin ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == widget.currentIndex;

                  return _buildMagneticNavigationItem(
                    context,
                    item,
                    index,
                    isSelected,
                    isDark,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBottomBar(BuildContext context, bool isDark) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientDecoration().gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == widget.currentIndex;

                return _buildFloatingNavigationItem(
                  context,
                  item,
                  index,
                  isSelected,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(
            color: AppTheme.textSecondary.withAlpha(26),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;

              return _buildMinimalNavigationItem(
                context,
                item,
                index,
                isSelected,
                isDark,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    _NavigationItem item,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _handleTap(context, index, item.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 18,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
            if (widget.showLabels) ...[
              const SizedBox(height: 1),
              Flexible( // Wrap text in Flexible to prevent overflow
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMagneticNavigationItem(
    BuildContext context,
    _NavigationItem item,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () => _handleTap(context, index, item.route),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? 1.0 : _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentColor.withAlpha(38)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: isSelected ? 26 : 22,
                    color: isSelected
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                  ),
                  if (widget.showLabels && isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingNavigationItem(
    BuildContext context,
    _NavigationItem item,
    int index,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _handleTap(context, index, item.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? item.activeIcon : item.icon,
          size: isSelected ? 26 : 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMinimalNavigationItem(
    BuildContext context,
    _NavigationItem item,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _handleTap(context, index, item.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        child: Icon(
          isSelected ? item.activeIcon : item.icon,
          size: 24,
          color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index, String route) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    widget.onTap?.call(index);
    Navigator.pushNamed(context, route);

    if (widget.variant == CustomBottomBarVariant.magnetic) {
      _magneticController.forward().then((_) {
        _magneticController.reverse();
      });
    }
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    return AppTheme.surfaceColor; // Always use dark surface color
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
