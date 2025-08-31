import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PdfAnnotationToolbar extends StatefulWidget {
  final String selectedText;
  final VoidCallback? onHighlight;
  final VoidCallback? onUnderline;
  final VoidCallback? onDraw;
  final VoidCallback? onNote;
  final VoidCallback? onClose;
  final Color selectedColor;
  final ValueChanged<Color>? onColorChanged;

  const PdfAnnotationToolbar({
    super.key,
    required this.selectedText,
    this.onHighlight,
    this.onUnderline,
    this.onDraw,
    this.onNote,
    this.onClose,
    this.selectedColor = const Color(0xFFFFEB3B),
    this.onColorChanged,
  });

  @override
  State<PdfAnnotationToolbar> createState() => _PdfAnnotationToolbarState();
}

class _PdfAnnotationToolbarState extends State<PdfAnnotationToolbar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _showColorPicker = false;

  final List<Color> _annotationColors = [
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFF9800), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF5722), // Red
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleToolAction(VoidCallback? action) {
    HapticFeedback.lightImpact();
    action?.call();
  }

  void _toggleColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
    });
  }

  void _selectColor(Color color) {
    HapticFeedback.selectionClick();
    widget.onColorChanged?.call(color);
    setState(() {
      _showColorPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            gradient: AppTheme.gradientDecoration().gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selected text preview
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.selectedText.length > 50
                            ? '${widget.selectedText.substring(0, 50)}...'
                            : widget.selectedText,
                        style:
                            AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleToolAction(widget.onClose),
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'close',
                          color: AppTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Annotation tools
              Container(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          icon: 'highlight',
                          label: 'Highlight',
                          onTap: () => _handleToolAction(widget.onHighlight),
                        ),
                        _buildToolButton(
                          icon: 'format_underlined',
                          label: 'Underline',
                          onTap: () => _handleToolAction(widget.onUnderline),
                        ),
                        _buildToolButton(
                          icon: 'draw',
                          label: 'Draw',
                          onTap: () => _handleToolAction(widget.onDraw),
                        ),
                        _buildToolButton(
                          icon: 'note_add',
                          label: 'Note',
                          onTap: () => _handleToolAction(widget.onNote),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Color picker toggle
                    GestureDetector(
                      onTap: _toggleColorPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: widget.selectedColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Color',
                              style: AppTheme.darkTheme.textTheme.labelMedium
                                  ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            CustomIconWidget(
                              iconName: _showColorPicker
                                  ? 'keyboard_arrow_up'
                                  : 'keyboard_arrow_down',
                              color: AppTheme.textPrimary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Color picker
                    if (_showColorPicker) ...[
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: _annotationColors.map((color) {
                            final isSelected = color == widget.selectedColor;
                            return GestureDetector(
                              onTap: () => _selectColor(color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 36 : 32,
                                height: isSelected ? 36 : 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.textPrimary
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? CustomIconWidget(
                                        iconName: 'check',
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 3.w,
          vertical: 1.5.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
