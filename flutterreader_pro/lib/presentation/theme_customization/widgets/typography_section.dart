import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class TypographySection extends StatefulWidget {
  final String selectedFontFamily;
  final double fontSize;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onFontSizeChanged;

  const TypographySection({
    super.key,
    required this.selectedFontFamily,
    required this.fontSize,
    required this.onFontFamilyChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<TypographySection> createState() => _TypographySectionState();
}

class _TypographySectionState extends State<TypographySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _fontFamilies = [
    {
      'name': 'Inter',
      'displayName': 'Inter (Default)',
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Roboto',
      'displayName': 'Roboto',
      'preview': 'Modern and friendly reading experience',
    },
    {
      'name': 'Open Sans',
      'displayName': 'Open Sans',
      'preview': 'Clean and highly legible typography',
    },
    {
      'name': 'Lato',
      'displayName': 'Lato',
      'preview': 'Elegant and professional appearance',
    },
    {
      'name': 'Source Sans Pro',
      'displayName': 'Source Sans Pro',
      'preview': 'Optimized for user interfaces',
    },
    {
      'name': 'Nunito',
      'displayName': 'Nunito',
      'preview': 'Rounded and approachable design',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
                iconName: 'text_fields',
                color: AppTheme.accentColor,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Typography',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Live preview text
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Preview',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 1.h),
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'FlutterReader Pro transforms your PDF reading experience with advanced typography and smooth animations.',
                        style: GoogleFonts.getFont(
                          widget.selectedFontFamily,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Font family selection
          Text(
            'Font Family',
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _fontFamilies.length,
              itemBuilder: (context, index) {
                final font = _fontFamilies[index];
                final isSelected = widget.selectedFontFamily == font['name'];

                return GestureDetector(
                  onTap: () {
                    widget.onFontFamilyChanged(font['name']);
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                  },
                  child: Container(
                    width: 45.w,
                    margin: EdgeInsets.only(right: 3.w),
                    padding: EdgeInsets.all(3.w),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          font['displayName'],
                          style: GoogleFonts.getFont(
                            font['name'],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppTheme.accentColor
                                : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Expanded(
                          child: Text(
                            font['preview'],
                            style: GoogleFonts.getFont(
                              font['name'],
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 3.h),

          // Font size control
          Row(
            children: [
              Text(
                'Font Size',
                style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.fontSize.round()}sp',
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          Row(
            children: [
              // Decrease button
              GestureDetector(
                onTap: () {
                  if (widget.fontSize > 12) {
                    widget.onFontSizeChanged(widget.fontSize - 1);
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'remove',
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.accentColor,
                    thumbColor: AppTheme.accentColor,
                    overlayColor: AppTheme.accentColor.withValues(alpha: 0.2),
                    inactiveTrackColor:
                        AppTheme.textSecondary.withValues(alpha: 0.3),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: widget.fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    onChanged: (value) {
                      widget.onFontSizeChanged(value);
                      _animationController.forward().then((_) {
                        _animationController.reverse();
                      });
                    },
                  ),
                ),
              ),

              // Increase button
              GestureDetector(
                onTap: () {
                  if (widget.fontSize < 24) {
                    widget.onFontSizeChanged(widget.fontSize + 1);
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}