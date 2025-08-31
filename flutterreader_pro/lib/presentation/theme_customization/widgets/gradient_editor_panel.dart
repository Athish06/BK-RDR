import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GradientEditorPanel extends StatefulWidget {
  final LinearGradient currentGradient;
  final ValueChanged<LinearGradient> onGradientChanged;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const GradientEditorPanel({
    super.key,
    required this.currentGradient,
    required this.onGradientChanged,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  State<GradientEditorPanel> createState() => _GradientEditorPanelState();
}

class _GradientEditorPanelState extends State<GradientEditorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late List<Color> _gradientColors;
  late AlignmentGeometry _beginAlignment;
  late AlignmentGeometry _endAlignment;
  double _opacity = 1.0;

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

    _gradientColors = List.from(widget.currentGradient.colors);
    _beginAlignment = widget.currentGradient.begin;
    _endAlignment = widget.currentGradient.end;

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(GradientEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
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

  void _updateGradient() {
    final newGradient = LinearGradient(
      colors: _gradientColors
          .map((color) => color.withValues(alpha: _opacity))
          .toList(),
      begin: _beginAlignment,
      end: _endAlignment,
    );
    widget.onGradientChanged(newGradient);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
          // Header
          GestureDetector(
            onTap: widget.onToggleExpanded,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'palette',
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Advanced Customization',
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: AppTheme.textSecondary,
                      size: 24,
                    ),
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
                  // Live preview
                  Container(
                    width: double.infinity,
                    height: 12.h,
                    margin: EdgeInsets.only(bottom: 3.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientColors
                            .map((color) => color.withValues(alpha: _opacity))
                            .toList(),
                        begin: _beginAlignment,
                        end: _endAlignment,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Live Preview',
                        style:
                            AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Color selection
                  Text(
                    'Gradient Colors',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildColorSelector(0, 'Start Color'),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: _buildColorSelector(1, 'End Color'),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Direction controls
                  Text(
                    'Gradient Direction',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDirectionButton(
                          'Top-Left', Alignment.topLeft, Alignment.bottomRight),
                      _buildDirectionButton('Top-Right', Alignment.topRight,
                          Alignment.bottomLeft),
                      _buildDirectionButton('Vertical', Alignment.topCenter,
                          Alignment.bottomCenter),
                      _buildDirectionButton('Horizontal', Alignment.centerLeft,
                          Alignment.centerRight),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Opacity control
                  Text(
                    'Opacity: ${(_opacity * 100).round()}%',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _opacity = value;
                        });
                        _updateGradient();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(int index, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: () => _showColorPicker(index),
          child: Container(
            width: double.infinity,
            height: 6.h,
            decoration: BoxDecoration(
              color: _gradientColors[index],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'colorize',
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionButton(String label, Alignment begin, Alignment end) {
    final isSelected = _beginAlignment == begin && _endAlignment == end;

    return GestureDetector(
      onTap: () {
        setState(() {
          _beginAlignment = begin;
          _endAlignment = end;
        });
        _updateGradient();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : AppTheme.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 10.sp,
          ),
        ),
      ),
    );
  }

  void _showColorPicker(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Select Color',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 80.w,
          height: 30.h,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _predefinedColors.length,
            itemBuilder: (context, colorIndex) {
              final color = _predefinedColors[colorIndex];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _gradientColors[index] = color;
                  });
                  _updateGradient();
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
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
        ],
      ),
    );
  }

  static const List<Color> _predefinedColors = [
    Color(0xFF6366F1), // Blue-violet
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
    Color(0xFF3B82F6), // Blue
    Color(0xFF6B7280), // Gray
    Color(0xFF1F2937), // Dark gray
    Color(0xFF111827), // Very dark
    Color(0xFF4C1D95), // Deep purple
    Color(0xFF065F46), // Deep green
    Color(0xFF7C2D12), // Deep orange
    Color(0xFF991B1B), // Deep red
    Color(0xFF581C87), // Deep violet
    Color(0xFF0F766E), // Deep teal
  ];
}