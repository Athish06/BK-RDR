import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AnnotationToolbarWidget extends StatefulWidget {
  final Function(String) onToolSelected;
  final String selectedTool;
  final Function(Color) onColorSelected;
  final Color selectedColor;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const AnnotationToolbarWidget({
    super.key,
    required this.onToolSelected,
    required this.selectedTool,
    required this.onColorSelected,
    required this.selectedColor,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  State<AnnotationToolbarWidget> createState() =>
      _AnnotationToolbarWidgetState();
}

class _AnnotationToolbarWidgetState extends State<AnnotationToolbarWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _showColorPalette = false;

  final List<Map<String, dynamic>> _annotationTools = [
    {
      'id': 'highlight',
      'icon': 'format_color_fill',
      'label': 'Highlight',
      'color': AppTheme.warningColor,
    },
    {
      'id': 'underline',
      'icon': 'format_underlined',
      'label': 'Underline',
      'color': AppTheme.accentColor,
    },
    {
      'id': 'strikethrough',
      'icon': 'format_strikethrough',
      'label': 'Strike',
      'color': AppTheme.errorColor,
    },
    {
      'id': 'draw',
      'icon': 'brush',
      'label': 'Draw',
      'color': AppTheme.successColor,
    },
    {
      'id': 'note',
      'icon': 'note_add',
      'label': 'Note',
      'color': AppTheme.textSecondary,
    },
  ];

  final List<Color> _colorPalette = [
    AppTheme.warningColor,
    AppTheme.accentColor,
    AppTheme.successColor,
    AppTheme.errorColor,
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFF96CEB4),
    const Color(0xFFFECA57),
    const Color(0xFFFF9FF3),
    const Color(0xFF54A0FF),
    const Color(0xFF5F27CD),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surfaceColor,
              AppTheme.surfaceColor.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40.w,
                height: 0.5.h,
                margin: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Undo/Redo controls
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: Row(
                  children: [
                    Text(
                      'Annotation Tools',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _buildUndoRedoButton(
                      icon: 'undo',
                      onTap: widget.onUndo,
                      enabled: widget.canUndo,
                    ),
                    SizedBox(width: 2.w),
                    _buildUndoRedoButton(
                      icon: 'redo',
                      onTap: widget.onRedo,
                      enabled: widget.canRedo,
                    ),
                  ],
                ),
              ),

              // Main toolbar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _annotationTools.map((tool) {
                    final isSelected = widget.selectedTool == tool['id'];
                    return _buildToolButton(
                      tool: tool,
                      isSelected: isSelected,
                    );
                  }).toList(),
                ),
              ),

              // Color palette
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showColorPalette ? 12.h : 0,
                child: _showColorPalette ? _buildColorPalette() : null,
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required Map<String, dynamic> tool,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToolSelected(tool['id']);

        if (tool['id'] == 'highlight' ||
            tool['id'] == 'underline' ||
            tool['id'] == 'draw') {
          setState(() {
            _showColorPalette = !_showColorPalette;
          });
        } else {
          setState(() {
            _showColorPalette = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 15.w,
        height: 15.w,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color:
              isSelected ? null : AppTheme.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: tool['icon'],
              size: 6.w,
              color: isSelected ? AppTheme.textPrimary : tool['color'],
            ),
            SizedBox(height: 0.5.h),
            Text(
              tool['label'],
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUndoRedoButton({
    required String icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap?.call();
            }
          : null,
      child: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.accentColor.withValues(alpha: 0.1)
              : AppTheme.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppTheme.accentColor.withValues(alpha: 0.3)
                : AppTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: CustomIconWidget(
          iconName: icon,
          size: 5.w,
          color: enabled
              ? AppTheme.accentColor
              : AppTheme.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Container(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            child: Text(
              'Select Color',
              style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 1.h,
                childAspectRatio: 1,
              ),
              itemCount: _colorPalette.length,
              itemBuilder: (context, index) {
                final color = _colorPalette[index];
                final isSelected = widget.selectedColor == color;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onColorSelected(color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.textPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? CustomIconWidget(
                            iconName: 'check',
                            size: 4.w,
                            color: AppTheme.textPrimary,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
