import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NoteEditorWidget extends StatefulWidget {
  final String initialText;
  final Function(String) onSave;
  final VoidCallback onCancel;
  final String title;
  final int maxLength;

  const NoteEditorWidget({
    super.key,
    this.initialText = '',
    required this.onSave,
    required this.onCancel,
    this.title = 'Add Note',
    this.maxLength = 500,
  });

  @override
  State<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends State<NoteEditorWidget>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late FocusNode _focusNode;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _currentLength = widget.initialText.length;
    _focusNode = FocusNode();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _textController.addListener(_updateLength);
    _slideController.forward();

    // Auto-focus after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_updateLength);
    _textController.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _updateLength() {
    setState(() {
      _currentLength = _textController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: 80.h,
          minHeight: 50.h,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 0.5.h,
                  margin: EdgeInsets.symmetric(vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              _buildHeader(),

              // Formatting toolbar
              _buildFormattingToolbar(),

              // Text editor
              Expanded(
                child: _buildTextEditor(),
              ),

              // Character counter and actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Add your thoughts and insights',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onCancel();
            },
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                size: 5.w,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildFormatButton(
            icon: 'format_bold',
            isActive: _isBold,
            onTap: () {
              setState(() {
                _isBold = !_isBold;
              });
            },
          ),
          SizedBox(width: 2.w),
          _buildFormatButton(
            icon: 'format_italic',
            isActive: _isItalic,
            onTap: () {
              setState(() {
                _isItalic = !_isItalic;
              });
            },
          ),
          SizedBox(width: 2.w),
          _buildFormatButton(
            icon: 'format_underlined',
            isActive: _isUnderline,
            onTap: () {
              setState(() {
                _isUnderline = !_isUnderline;
              });
            },
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'text_fields',
                  size: 4.w,
                  color: AppTheme.accentColor,
                ),
                SizedBox(width: 1.w),
                Text(
                  '$_currentLength/${widget.maxLength}',
                  style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                    color: _currentLength > widget.maxLength * 0.9
                        ? AppTheme.errorColor
                        : AppTheme.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required String icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.accentColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: CustomIconWidget(
          iconName: icon,
          size: 5.w,
          color: isActive ? AppTheme.accentColor : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        maxLength: widget.maxLength,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          height: 1.6,
          fontWeight: _isBold ? FontWeight.w600 : FontWeight.w400,
          fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
          decoration:
              _isUnderline ? TextDecoration.underline : TextDecoration.none,
        ),
        decoration: InputDecoration(
          hintText:
              'Start typing your note here...\n\nYou can add insights, questions, or any thoughts about this section.',
          hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            height: 1.6,
          ),
          border: InputBorder.none,
          counterText: '', // Hide default counter
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        onChanged: (text) {
          // Auto-save draft functionality could be added here
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasText = _textController.text.trim().isNotEmpty;
    final isOverLimit = _currentLength > widget.maxLength;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Progress indicator
          if (_currentLength > 0) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _currentLength / widget.maxLength,
                    backgroundColor:
                        AppTheme.textSecondary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverLimit ? AppTheme.errorColor : AppTheme.accentColor,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  '${((_currentLength / widget.maxLength) * 100).toInt()}%',
                  style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                    color: isOverLimit
                        ? AppTheme.errorColor
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onCancel();
                  },
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textSecondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style:
                            AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: hasText && !isOverLimit
                      ? () {
                          HapticFeedback.mediumImpact();
                          widget.onSave(_textController.text.trim());
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 6.h,
                    decoration: hasText && !isOverLimit
                        ? AppTheme.gradientDecoration(
                            borderRadius: BorderRadius.circular(12),
                          )
                        : BoxDecoration(
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'save',
                          size: 5.w,
                          color: hasText && !isOverLimit
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Save Note',
                          style: AppTheme.darkTheme.textTheme.labelMedium
                              ?.copyWith(
                            color: hasText && !isOverLimit
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
