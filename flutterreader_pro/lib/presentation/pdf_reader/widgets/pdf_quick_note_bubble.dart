import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PdfQuickNoteBubble extends StatefulWidget {
  final Offset position;
  final String note;
  final bool isEditing;
  final ValueChanged<String>? onNoteChanged;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  const PdfQuickNoteBubble({
    super.key,
    required this.position,
    required this.note,
    this.isEditing = false,
    this.onNoteChanged,
    this.onSave,
    this.onDelete,
    this.onClose,
  });

  @override
  State<PdfQuickNoteBubble> createState() => _PdfQuickNoteBubbleState();

  /// Shows the note as a centered dialog - improved design with formatting
  static Future<void> showAsDialog({
    required BuildContext context,
    required String initialNote,
    required ValueChanged<String> onSave,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickNoteDialog(
        initialNote: initialNote,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }
}

/// Dialog version of quick note - styled like the screenshot
class _QuickNoteDialog extends StatefulWidget {
  final String initialNote;
  final ValueChanged<String> onSave;
  final VoidCallback onDelete;

  const _QuickNoteDialog({
    required this.initialNote,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<_QuickNoteDialog> {
  late TextEditingController _controller;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  final int _maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _controller.addListener(() {
      setState(() {}); // Update character count
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterCount = _controller.text.length;
    final isOverLimit = characterCount > _maxCharacters;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 2.h),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Note',
                          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Formatting toolbar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  // Bold
                  _buildFormatButton(
                    icon: Icons.format_bold,
                    isActive: _isBold,
                    onTap: () => setState(() => _isBold = !_isBold),
                  ),
                  SizedBox(width: 2.w),
                  // Italic
                  _buildFormatButton(
                    icon: Icons.format_italic,
                    isActive: _isItalic,
                    onTap: () => setState(() => _isItalic = !_isItalic),
                  ),
                  SizedBox(width: 2.w),
                  // Underline
                  _buildFormatButton(
                    icon: Icons.format_underlined,
                    isActive: _isUnderline,
                    onTap: () => setState(() => _isUnderline = !_isUnderline),
                  ),
                  const Spacer(),
                  // Character count
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: isOverLimit ? AppTheme.errorColor : AppTheme.accentColor,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$characterCount/$_maxCharacters',
                          style: TextStyle(
                            color: isOverLimit ? AppTheme.errorColor : AppTheme.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // Note input area
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Container(
                height: 25.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                    decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start typing your note here...\n\nYou can add insights, questions, or any thoughts about this section.',
                    hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(3.w),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // Action buttons
            Padding(
              padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 3.h),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Save button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _controller.text.isEmpty || isOverLimit
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              widget.onSave(_controller.text);
                              Navigator.pop(context);
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        decoration: BoxDecoration(
                          color: _controller.text.isEmpty || isOverLimit
                              ? AppTheme.textSecondary.withValues(alpha: 0.3)
                              : AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save_outlined,
                              color: _controller.text.isEmpty || isOverLimit
                                  ? AppTheme.textSecondary
                                  : Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Save Note',
                              style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                                color: _controller.text.isEmpty || isOverLimit
                                    ? AppTheme.textSecondary
                                    : Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor.withValues(alpha: 0.2) : AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.accentColor : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.accentColor : AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

/// Simple state class for keeping the widget interface
class _PdfQuickNoteBubbleState extends State<PdfQuickNoteBubble> {
  @override
  Widget build(BuildContext context) {
    // This widget is now deprecated in favor of PdfQuickNoteBubble.showAsDialog
    // Keeping it for backward compatibility - shows nothing
    return const SizedBox.shrink();
  }
}
