import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../models/pdf_annotation.dart';

class PdfAnnotationToolbar extends StatefulWidget {
  final String selectedText;
  final VoidCallback? onHighlight;
  final VoidCallback? onTextHighlight; // Text-detection highlight
  final VoidCallback? onUnderline;
  final VoidCallback? onDraw;
  final VoidCallback? onNote;
  final VoidCallback? onEraser;
  final VoidCallback? onClose;
  final Color selectedColor;
  final ValueChanged<Color>? onColorChanged;
  final AnnotationType? activeTool;
  final bool useTextHighlight; // Whether text highlight mode is selected
  final ValueChanged<bool>? onHighlightModeChanged;

  const PdfAnnotationToolbar({
    super.key,
    required this.selectedText,
    this.onHighlight,
    this.onTextHighlight,
    this.onUnderline,
    this.onDraw,
    this.onNote,
    this.onEraser,
    this.onClose,
    this.selectedColor = const Color(0xFFFFEB3B),
    this.onColorChanged,
    this.activeTool,
    this.useTextHighlight = false,
    this.onHighlightModeChanged,
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
  bool _showHighlightModeSelector = false;

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected text preview (compact)
                  if (widget.selectedText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.selectedText.length > 40
                                  ? '${widget.selectedText.substring(0, 40)}...'
                                  : widget.selectedText,
                              style:
                                  AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _handleToolAction(widget.onClose),
                            child: Container(
                              padding: EdgeInsets.all(0.8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: CustomIconWidget(
                                iconName: 'close',
                                color: AppTheme.textPrimary,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Annotation tools (compact)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.2.h),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildToolButton(
                              icon: 'highlight',
                              label: widget.useTextHighlight ? 'Text' : 'Paint',
                              onTap: () {
                                setState(() {
                                  _showHighlightModeSelector = !_showHighlightModeSelector;
                                  _showColorPicker = false;
                                });
                              },
                              onLongPress: () {
                                setState(() {
                                  _showHighlightModeSelector = !_showHighlightModeSelector;
                                  _showColorPicker = false;
                                });
                              },
                              color: widget.selectedColor,
                              isActive: widget.activeTool == AnnotationType.highlight || 
                                        widget.activeTool == AnnotationType.textHighlight,
                            ),
                            _buildToolButton(
                              icon: 'format_underlined',
                              label: 'Line',
                              onTap: () => _handleToolAction(widget.onUnderline),
                              color: widget.selectedColor,
                              isActive: widget.activeTool == AnnotationType.underline,
                            ),
                            _buildToolButton(
                              icon: 'draw',
                              label: 'Draw',
                              onTap: () => _handleToolAction(widget.onDraw),
                              color: widget.selectedColor,
                              isActive: widget.activeTool == AnnotationType.drawing,
                            ),
                            _buildToolButton(
                              icon: 'auto_fix_off',
                              label: 'Erase',
                              onTap: () => _handleToolAction(widget.onEraser),
                              color: Colors.white,
                              isActive: widget.activeTool == AnnotationType.eraser,
                            ),
                            _buildToolButton(
                              icon: 'note_add',
                              label: 'Note',
                              onTap: () => _handleToolAction(widget.onNote),
                              isActive: widget.activeTool == AnnotationType.text,
                            ),
                          ],
                        ),
                        
                        // Highlight mode selector (compact)
                        if (_showHighlightModeSelector)
                          Container(
                            margin: EdgeInsets.only(top: 1.h),
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Highlight Mode',
                                  style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 0.8.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildHighlightModeButton(
                                      icon: 'brush',
                                      label: 'Paint',
                                      isSelected: !widget.useTextHighlight,
                                      onTap: () {
                                        widget.onHighlightModeChanged?.call(false);
                                        _handleToolAction(widget.onHighlight);
                                        setState(() => _showHighlightModeSelector = false);
                                      },
                                    ),
                                    SizedBox(width: 2.w),
                                    _buildHighlightModeButton(
                                      icon: 'text_fields',
                                      label: 'Text',
                                      isSelected: widget.useTextHighlight,
                                      onTap: () {
                                        widget.onHighlightModeChanged?.call(true);
                                        _handleToolAction(widget.onTextHighlight);
                                        setState(() => _showHighlightModeSelector = false);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 1.2.h),

                        // Compact color picker toggle
                        GestureDetector(
                          onTap: _toggleColorPicker,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: widget.selectedColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 1.5.w),
                                Text(
                                  'Color',
                                  style: AppTheme.darkTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Compact Color Picker Overlay
        if (_showColorPicker)
          Positioned(
            bottom: 18.h,
            left: 4.w,
            right: 4.w,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Color',
                          style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showColorPicker = false),
                          child: CustomIconWidget(
                            iconName: 'close',
                            color: AppTheme.textSecondary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5.h),
                    Wrap(
                      spacing: 3.w,
                      runSpacing: 1.5.h,
                      alignment: WrapAlignment.center,
                      children: _annotationColors.map((color) {
                        final isSelected = color == widget.selectedColor;
                        return GestureDetector(
                          onTap: () => _selectColor(color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Compact tool button for mobile
  Widget _buildToolButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? color,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 2.2.w,
          vertical: 1.h,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.accentColor.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isActive ? AppTheme.accentColor : (color ?? AppTheme.textPrimary),
              size: 18,
            ),
            SizedBox(height: 0.3.h),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color: isActive ? AppTheme.accentColor : AppTheme.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Compact highlight mode button
  Widget _buildHighlightModeButton({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
