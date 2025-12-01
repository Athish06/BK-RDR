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

  /// Shows the note as a centered dialog
  static Future<void> showAsDialog({
    required BuildContext context,
    required String initialNote,
    required ValueChanged<String> onSave,
    required VoidCallback onDelete,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _QuickNoteDialog(
        initialNote: initialNote,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }
}

/// Dialog version of quick note - centered and properly dismissible
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
      child: Container(
        width: 80.w,
        constraints: BoxConstraints(maxHeight: 50.h),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientDecoration().gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomIconWidget(
                      iconName: 'note',
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Quick Note',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Note input
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: null,
                    minLines: 4,
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your note here...',
                      hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(3.w),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // Action buttons
            Padding(
              padding: EdgeInsets.only(left: 3.w, right: 3.w, bottom: 3.w),
              child: Row(
                children: [
                  // Delete button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onDelete();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'delete',
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Delete',
                              style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Save button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSave(_controller.text);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'check',
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Save',
                              style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
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
