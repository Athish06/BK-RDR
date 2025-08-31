import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './widgets/gradient_editor_panel.dart';
import './widgets/reading_mode_preferences.dart';
import './widgets/theme_preview_card.dart';
import './widgets/theme_rotation_settings.dart';
import './widgets/typography_section.dart';

class ThemeCustomization extends StatefulWidget {
  const ThemeCustomization({super.key});

  @override
  State<ThemeCustomization> createState() => _ThemeCustomizationState();
}

class _ThemeCustomizationState extends State<ThemeCustomization>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _previewAnimationController;
  late AnimationController _confettiController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _previewScaleAnimation;
  late Animation<double> _confettiAnimation;

  // Theme state
  String _selectedThemeId = 'blue_violet';
  LinearGradient _currentGradient = const LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  bool _isGradientEditorExpanded = false;

  // Typography state
  String _selectedFontFamily = 'Inter';
  double _fontSize = 16.0;

  // Reading mode state
  String _selectedReadingMode = 'full_dark';
  double _brightness = 0.8;
  double _colorTemperature = 0.3;
  bool _animationsEnabled = true;

  // Theme rotation state
  bool _themeRotationEnabled = false;
  String _rotationType = 'time_based';
  List<String> _selectedRotationThemes = ['blue_violet', 'teal_cyan'];

  // Mock data for theme gallery
  final List<Map<String, dynamic>> _themeGallery = [
    {
      'id': 'blue_violet',
      'name': 'Blue Violet',
      'gradient': const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'unlocked': true,
    },
    {
      'id': 'teal_cyan',
      'name': 'Teal Cyan',
      'gradient': const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'unlocked': true,
    },
    {
      'id': 'sunset',
      'name': 'Sunset',
      'gradient': const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'unlocked': true,
    },
    {
      'id': 'ocean',
      'name': 'Ocean',
      'gradient': const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'unlocked': false,
      'requirement': 'Read 50 pages',
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF84CC16)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'unlocked': false,
      'requirement': 'Complete 10 documents',
    },
    {
      'id': 'royal',
      'name': 'Royal',
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'unlocked': false,
      'requirement': '7-day reading streak',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPreferences();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _previewScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _previewAnimationController,
      curve: Curves.elasticOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeInOut,
    ));

    // Start entrance animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _previewAnimationController.forward();
    });
  }

  void _loadUserPreferences() {
    // Simulate loading user preferences
    // In a real app, this would load from SharedPreferences or a database
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _previewAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onThemeSelected(String themeId) {
    final theme = _themeGallery.firstWhere((t) => t['id'] == themeId);

    if (!theme['unlocked']) {
      _showUnlockDialog(theme);
      return;
    }

    setState(() {
      _selectedThemeId = themeId;
      _currentGradient = theme['gradient'];
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Trigger preview animation
    _previewAnimationController.reset();
    _previewAnimationController.forward();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme "${theme['name']}" applied successfully!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUnlockDialog(Map<String, dynamic> theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.warningColor,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Theme Locked',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 8.h,
              decoration: BoxDecoration(
                gradient: theme['gradient'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  theme['name'],
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Unlock this theme by:',
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              theme['requirement'],
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Theme',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will reset all theme customizations to default OLED-optimized settings. Continue?',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedThemeId = 'blue_violet';
                _currentGradient = const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                );
                _selectedFontFamily = 'Inter';
                _fontSize = 16.0;
                _selectedReadingMode = 'full_dark';
                _brightness = 0.8;
                _colorTemperature = 0.3;
                _animationsEnabled = true;
                _themeRotationEnabled = false;
                _rotationType = 'time_based';
                _selectedRotationThemes = ['blue_violet', 'teal_cyan'];
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Theme reset to default settings'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: AppTheme.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, 0),
              child: Text(
                'Theme Customization',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.textSecondary,
              size: 24,
            ),
            onPressed: _resetToDefault,
            tooltip: 'Reset to default',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.textSecondary,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live preview header
            AnimatedBuilder(
              animation: _previewScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _previewScaleAnimation.value,
                  child: Container(
                    width: double.infinity,
                    height: 25.h,
                    margin: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: _currentGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _currentGradient.colors.first
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Sample PDF content
                        Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mock header
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'picture_as_pdf',
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'FlutterReader Pro',
                                    style: GoogleFonts.getFont(
                                      _selectedFontFamily,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.h),

                              // Mock content
                              Text(
                                'Chapter 1: Getting Started',
                                style: GoogleFonts.getFont(
                                  _selectedFontFamily,
                                  fontSize: (_fontSize + 2).sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),

                              Text(
                                'This premium PDF reader transforms your reading experience with cinematic animations and OLED-optimized themes.',
                                style: GoogleFonts.getFont(
                                  _selectedFontFamily,
                                  fontSize: _fontSize.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.6,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const Spacer(),

                              // Live preview indicator
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 3.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'visibility',
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Live Preview',
                                      style: AppTheme
                                          .darkTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Theme gallery section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Theme Gallery',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            SizedBox(
              height: 22.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemCount: _themeGallery.length,
                itemBuilder: (context, index) {
                  final theme = _themeGallery[index];
                  return Stack(
                    children: [
                      ThemePreviewCard(
                        themeName: theme['name'],
                        gradient: theme['gradient'],
                        isSelected: _selectedThemeId == theme['id'],
                        onTap: () => _onThemeSelected(theme['id']),
                        showAnimation: _animationsEnabled,
                      ),

                      // Lock overlay for locked themes
                      if (!theme['unlocked'])
                        Positioned.fill(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'lock',
                                  color: AppTheme.warningColor,
                                  size: 32,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Locked',
                                  style: AppTheme.darkTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            SizedBox(height: 3.h),

            // Advanced customization panel
            GradientEditorPanel(
              currentGradient: _currentGradient,
              onGradientChanged: (gradient) {
                setState(() {
                  _currentGradient = gradient;
                });
              },
              isExpanded: _isGradientEditorExpanded,
              onToggleExpanded: () {
                setState(() {
                  _isGradientEditorExpanded = !_isGradientEditorExpanded;
                });
              },
            ),

            // Typography section
            TypographySection(
              selectedFontFamily: _selectedFontFamily,
              fontSize: _fontSize,
              onFontFamilyChanged: (fontFamily) {
                setState(() {
                  _selectedFontFamily = fontFamily;
                });
              },
              onFontSizeChanged: (fontSize) {
                setState(() {
                  _fontSize = fontSize;
                });
              },
            ),

            // Reading mode preferences
            ReadingModePreferences(
              selectedMode: _selectedReadingMode,
              brightness: _brightness,
              colorTemperature: _colorTemperature,
              animationsEnabled: _animationsEnabled,
              onModeChanged: (mode) {
                setState(() {
                  _selectedReadingMode = mode;
                });
              },
              onBrightnessChanged: (brightness) {
                setState(() {
                  _brightness = brightness;
                });
              },
              onColorTemperatureChanged: (temperature) {
                setState(() {
                  _colorTemperature = temperature;
                });
              },
              onAnimationsToggled: (enabled) {
                setState(() {
                  _animationsEnabled = enabled;
                });
              },
            ),

            // Theme rotation settings
            ThemeRotationSettings(
              isEnabled: _themeRotationEnabled,
              rotationType: _rotationType,
              selectedThemes: _selectedRotationThemes,
              onEnabledChanged: (enabled) {
                setState(() {
                  _themeRotationEnabled = enabled;
                });
              },
              onRotationTypeChanged: (type) {
                setState(() {
                  _rotationType = type;
                });
              },
              onSelectedThemesChanged: (themes) {
                setState(() {
                  _selectedRotationThemes = themes;
                });
              },
            ),

            // Bottom spacing
            SizedBox(height: 10.h),
          ],
        ),
      ),

      // Floating action button for quick actions
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Trigger confetti animation for theme application
          _confettiController.forward().then((_) {
            _confettiController.reset();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Theme customizations saved!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => Navigator.pushNamed(context, '/pdf-reader'),
              ),
            ),
          );
        },
        backgroundColor: AppTheme.accentColor,
        icon: CustomIconWidget(
          iconName: 'save',
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Apply Theme',
          style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}