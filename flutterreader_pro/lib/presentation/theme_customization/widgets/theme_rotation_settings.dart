import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ThemeRotationSettings extends StatefulWidget {
  final bool isEnabled;
  final String rotationType;
  final List<String> selectedThemes;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onRotationTypeChanged;
  final ValueChanged<List<String>> onSelectedThemesChanged;

  const ThemeRotationSettings({
    super.key,
    required this.isEnabled,
    required this.rotationType,
    required this.selectedThemes,
    required this.onEnabledChanged,
    required this.onRotationTypeChanged,
    required this.onSelectedThemesChanged,
  });

  @override
  State<ThemeRotationSettings> createState() => _ThemeRotationSettingsState();
}

class _ThemeRotationSettingsState extends State<ThemeRotationSettings>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  final List<Map<String, dynamic>> _rotationTypes = [
    {
      'id': 'time_based',
      'name': 'Time of Day',
      'description': 'Changes based on morning, afternoon, evening',
      'icon': 'schedule',
    },
    {
      'id': 'session_based',
      'name': 'Reading Session',
      'description': 'New theme for each reading session',
      'icon': 'auto_stories',
    },
    {
      'id': 'daily',
      'name': 'Daily',
      'description': 'Different theme each day',
      'icon': 'today',
    },
    {
      'id': 'weekly',
      'name': 'Weekly',
      'description': 'Changes every week',
      'icon': 'date_range',
    },
  ];

  final List<Map<String, dynamic>> _availableThemes = [
    {
      'id': 'blue_violet',
      'name': 'Blue Violet',
      'gradient': LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'teal_cyan',
      'name': 'Teal Cyan',
      'gradient': LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'sunset',
      'name': 'Sunset',
      'gradient': LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'ocean',
      'name': 'Ocean',
      'gradient': LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'gradient': LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF84CC16)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'royal',
      'name': 'Royal',
      'gradient': LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.isEnabled) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ThemeRotationSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with toggle
          GestureDetector(
            onTap: () => widget.onEnabledChanged(!widget.isEnabled),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'autorenew',
                    color: widget.isEnabled
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Rotation',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Automatically cycle through themes',
                          style:
                              AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: widget.isEnabled,
                    onChanged: widget.onEnabledChanged,
                    activeColor: AppTheme.accentColor,
                    activeTrackColor:
                        AppTheme.accentColor.withValues(alpha: 0.3),
                    inactiveThumbColor: AppTheme.textSecondary,
                    inactiveTrackColor:
                        AppTheme.textSecondary.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rotation type selection
                  Text(
                    'Rotation Schedule',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Column(
                    children: _rotationTypes.map((type) {
                      final isSelected = widget.rotationType == type['id'];

                      return GestureDetector(
                        onTap: () => widget.onRotationTypeChanged(type['id']),
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 2.h),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentColor.withValues(alpha: 0.1)
                                : AppTheme.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : AppTheme.textSecondary
                                      .withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: type['icon'],
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type['name'],
                                      style: AppTheme
                                          .darkTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: isSelected
                                            ? AppTheme.accentColor
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      type['description'],
                                      style: AppTheme
                                          .darkTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                CustomIconWidget(
                                  iconName: 'radio_button_checked',
                                  color: AppTheme.accentColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 2.h),

                  // Theme selection
                  Text(
                    'Themes in Rotation',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Select themes to include in rotation',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2.w,
                      mainAxisSpacing: 2.w,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _availableThemes.length,
                    itemBuilder: (context, index) {
                      final theme = _availableThemes[index];
                      final isSelected =
                          widget.selectedThemes.contains(theme['id']);

                      return GestureDetector(
                        onTap: () {
                          final updatedThemes =
                              List<String>.from(widget.selectedThemes);
                          if (isSelected) {
                            updatedThemes.remove(theme['id']);
                          } else {
                            updatedThemes.add(theme['id']);
                          }
                          widget.onSelectedThemesChanged(updatedThemes);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: theme['gradient'],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.accentColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // Theme name
                              Positioned(
                                bottom: 2.w,
                                left: 2.w,
                                right: 2.w,
                                child: Text(
                                  theme['name'],
                                  style: AppTheme.darkTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Selection indicator
                              if (isSelected)
                                Positioned(
                                  top: 1.w,
                                  right: 1.w,
                                  child: Container(
                                    padding: EdgeInsets.all(1.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CustomIconWidget(
                                      iconName: 'check',
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
