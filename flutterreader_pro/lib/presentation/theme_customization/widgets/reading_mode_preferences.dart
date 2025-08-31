import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ReadingModePreferences extends StatefulWidget {
  final String selectedMode;
  final double brightness;
  final double colorTemperature;
  final bool animationsEnabled;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onColorTemperatureChanged;
  final ValueChanged<bool> onAnimationsToggled;

  const ReadingModePreferences({
    super.key,
    required this.selectedMode,
    required this.brightness,
    required this.colorTemperature,
    required this.animationsEnabled,
    required this.onModeChanged,
    required this.onBrightnessChanged,
    required this.onColorTemperatureChanged,
    required this.onAnimationsToggled,
  });

  @override
  State<ReadingModePreferences> createState() => _ReadingModePreferencesState();
}

class _ReadingModePreferencesState extends State<ReadingModePreferences>
    with TickerProviderStateMixin {
  late AnimationController _brightnessController;
  late AnimationController _temperatureController;
  late Animation<Color?> _brightnessColorAnimation;
  late Animation<Color?> _temperatureColorAnimation;

  final List<Map<String, dynamic>> _readingModes = [
    {
      'id': 'full_dark',
      'name': 'Full Dark',
      'description': 'Pure OLED black background',
      'icon': 'dark_mode',
      'color': Color(0xFF000000),
    },
    {
      'id': 'auto_night',
      'name': 'Auto Night',
      'description': 'Adapts to ambient light',
      'icon': 'brightness_auto',
      'color': Color(0xFF1A1A1A),
    },
    {
      'id': 'custom',
      'name': 'Custom',
      'description': 'Personalized settings',
      'icon': 'tune',
      'color': Color(0xFF2D2D30),
    },
  ];

  @override
  void initState() {
    super.initState();
    _brightnessController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _temperatureController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _brightnessColorAnimation = ColorTween(
      begin: AppTheme.textSecondary,
      end: AppTheme.accentColor,
    ).animate(_brightnessController);

    _temperatureColorAnimation = ColorTween(
      begin: AppTheme.textSecondary,
      end: AppTheme.warningColor,
    ).animate(_temperatureController);
  }

  @override
  void dispose() {
    _brightnessController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'visibility',
                color: AppTheme.accentColor,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Reading Mode',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Reading mode selection
          Column(
            children: _readingModes.map((mode) {
              final isSelected = widget.selectedMode == mode['id'];

              return GestureDetector(
                onTap: () => widget.onModeChanged(mode['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 2.h),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                        : AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: mode['color'],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: mode['icon'],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode['name'],
                              style: AppTheme.darkTheme.textTheme.titleSmall
                                  ?.copyWith(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              mode['description'],
                              style: AppTheme.darkTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.accentColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Brightness control
          if (widget.selectedMode == 'custom') ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _brightnessColorAnimation,
                  builder: (context, child) {
                    return CustomIconWidget(
                      iconName: 'brightness_6',
                      color: _brightnessColorAnimation.value ??
                          AppTheme.textSecondary,
                      size: 20,
                    );
                  },
                ),
                SizedBox(width: 3.w),
                Text(
                  'Brightness',
                  style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(widget.brightness * 100).round()}%',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.accentColor,
                thumbColor: AppTheme.accentColor,
                overlayColor: AppTheme.accentColor.withValues(alpha: 0.2),
                inactiveTrackColor:
                    AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: widget.brightness,
                min: 0.1,
                max: 1.0,
                onChanged: (value) {
                  widget.onBrightnessChanged(value);
                  _brightnessController.forward().then((_) {
                    _brightnessController.reverse();
                  });
                },
              ),
            ),

            SizedBox(height: 2.h),

            // Color temperature control
            Row(
              children: [
                AnimatedBuilder(
                  animation: _temperatureColorAnimation,
                  builder: (context, child) {
                    return CustomIconWidget(
                      iconName: 'wb_incandescent',
                      color: _temperatureColorAnimation.value ??
                          AppTheme.textSecondary,
                      size: 20,
                    );
                  },
                ),
                SizedBox(width: 3.w),
                Text(
                  'Warmth',
                  style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(widget.colorTemperature * 100).round()}%',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.warningColor,
                thumbColor: AppTheme.warningColor,
                overlayColor: AppTheme.warningColor.withValues(alpha: 0.2),
                inactiveTrackColor:
                    AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: widget.colorTemperature,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  widget.onColorTemperatureChanged(value);
                  _temperatureController.forward().then((_) {
                    _temperatureController.reverse();
                  });
                },
              ),
            ),
          ],

          SizedBox(height: 3.h),

          // Animation preferences
          Container(
            padding: EdgeInsets.all(4.w),
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
                CustomIconWidget(
                  iconName: 'animation',
                  color: widget.animationsEnabled
                      ? AppTheme.accentColor
                      : AppTheme.textSecondary,
                  size: 24,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smooth Animations',
                        style:
                            AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Enable buttery-smooth transitions',
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.animationsEnabled,
                  onChanged: widget.onAnimationsToggled,
                  activeColor: AppTheme.accentColor,
                  activeTrackColor: AppTheme.accentColor.withValues(alpha: 0.3),
                  inactiveThumbColor: AppTheme.textSecondary,
                  inactiveTrackColor:
                      AppTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
