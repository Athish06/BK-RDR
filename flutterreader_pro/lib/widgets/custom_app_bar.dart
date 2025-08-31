import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum CustomAppBarVariant {
  standard,
  reading,
  search,
  minimal,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showSearchField;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final bool isSearchActive;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.showSearchField = false,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: _buildTitle(context),
      leading: _buildLeading(context),
      actions: _buildActions(context),
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      elevation: _getElevation(),
      backgroundColor: _getBackgroundColor(isDark),
      foregroundColor: _getForegroundColor(isDark),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: _getSystemOverlayStyle(isDark),
      toolbarHeight: _getToolbarHeight(),
      flexibleSpace: variant == CustomAppBarVariant.reading
          ? _buildReadingModeBackground()
          : null,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    if (showSearchField && isSearchActive) {
      return _buildSearchField(context);
    }

    if (title == null) return null;

    final textStyle = _getTitleTextStyle(context);

    switch (variant) {
      case CustomAppBarVariant.minimal:
        return Text(
          title!,
          style: textStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        );
      case CustomAppBarVariant.reading:
        return Text(
          title!,
          style: textStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
        );
      case CustomAppBarVariant.search:
        return showSearchField
            ? _buildSearchField(context)
            : Text(title!, style: textStyle);
      default:
        return Text(title!, style: textStyle);
    }
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textSecondary.withAlpha(51),
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        onSubmitted: (_) => onSearchSubmitted?.call(),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: searchHint ?? 'Search documents...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary.withAlpha(153),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (!automaticallyImplyLeading) return null;

    final canPop = Navigator.of(context).canPop();
    if (!canPop) return null;

    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios,
        size: variant == CustomAppBarVariant.minimal ? 20 : 24,
      ),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      tooltip: 'Back',
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    // Add variant-specific actions
    switch (variant) {
      case CustomAppBarVariant.reading:
        actionWidgets.addAll([
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
            tooltip: 'Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'More options',
          ),
        ]);
        break;
      case CustomAppBarVariant.search:
        if (!isSearchActive) {
          actionWidgets.add(
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
              tooltip: 'Search',
            ),
          );
        }
        break;
      default:
        break;
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // Add navigation actions for standard variant
    if (variant == CustomAppBarVariant.standard && actions == null) {
      actionWidgets.addAll([
        IconButton(
          icon: const Icon(Icons.library_books),
          onPressed: () => Navigator.pushNamed(context, '/pdf-library'),
          tooltip: 'Library',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          tooltip: 'Settings',
        ),
      ]);
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }

  TextStyle _getTitleTextStyle(BuildContext context) {
    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.minimal:
        return GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _getForegroundColor(theme.brightness == Brightness.dark),
        );
      case CustomAppBarVariant.reading:
        return GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: _getForegroundColor(theme.brightness == Brightness.dark),
          letterSpacing: 0.15,
        );
      default:
        return GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _getForegroundColor(theme.brightness == Brightness.dark),
          letterSpacing: 0.15,
        );
    }
  }

  double _getElevation() {
    if (elevation != null) return elevation!;

    switch (variant) {
      case CustomAppBarVariant.minimal:
        return 0;
      case CustomAppBarVariant.reading:
        return 0;
      default:
        return 0;
    }
  }

  Color _getBackgroundColor(bool isDark) {
    if (backgroundColor != null) return backgroundColor!;

    switch (variant) {
      case CustomAppBarVariant.reading:
        return AppTheme.primaryDark;
      case CustomAppBarVariant.minimal:
        return Colors.transparent;
      default:
        return AppTheme.primaryDark; // Always use dark background
    }
  }

  Color _getForegroundColor(bool isDark) {
    if (foregroundColor != null) return foregroundColor!;

    return AppTheme.textPrimary; // Always use white text
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(bool isDark) {
    return isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light,
          );
  }

  double _getToolbarHeight() {
    switch (variant) {
      case CustomAppBarVariant.minimal:
        return 48;
      case CustomAppBarVariant.search:
        return showSearchField ? 64 : 56;
      default:
        return 56;
    }
  }

  Widget? _buildReadingModeBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryDark.withAlpha(242),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_getToolbarHeight());
}
