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
}

class _PdfQuickNoteBubbleState extends State<PdfQuickNoteBubble>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _noteController.text = widget.note;
    _scaleController.forward();

    if (widget.isEditing) {
      _expandBubble();
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PdfQuickNoteBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note != oldWidget.note) {
      _noteController.text = widget.note;
    }

    if (widget.isEditing != oldWidget.isEditing) {
      if (widget.isEditing) {
        _expandBubble();
      } else {
        _collapseBubble();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _expandBubble() {
    setState(() {
      _isExpanded = true;
    });
    _pulseController.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noteFocusNode.requestFocus();
    });
  }

  void _collapseBubble() {
    setState(() {
      _isExpanded = false;
    });
    _noteFocusNode.unfocus();
    _pulseController.repeat(reverse: true);
  }

  void _handleSave() {
    HapticFeedback.lightImpact();
    widget.onNoteChanged?.call(_noteController.text);
    widget.onSave?.call();
    _collapseBubble();
  }

  void _handleDelete() {
    HapticFeedback.lightImpact();
    widget.onDelete?.call();
  }

  void _handleTap() {
    if (!_isExpanded) {
      HapticFeedback.lightImpact();
      _expandBubble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isExpanded ? 70.w : 40,
            constraints: BoxConstraints(
              minHeight: _isExpanded ? 20.h : 40,
              maxHeight: _isExpanded ? 40.h : 40,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.gradientDecoration().gradient,
              borderRadius: BorderRadius.circular(_isExpanded ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.4),
                  blurRadius: _isExpanded ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isExpanded ? _buildExpandedNote() : _buildCollapsedNote(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedNote() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: widget.note.isEmpty ? 'add' : 'note',
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedNote() {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomIconWidget(
                  iconName: 'note',
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Quick Note',
                  style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Note input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _noteController,
                focusNode: _noteFocusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Add your note here...',
                  hintStyle: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(2.w),
                ),
                onChanged: widget.onNoteChanged,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Action buttons
          Row(
            children: [
              if (widget.note.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: _handleDelete,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'delete',
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Delete',
                            style: AppTheme.darkTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.note.isNotEmpty) SizedBox(width: 2.w),
              Expanded(
                child: GestureDetector(
                  onTap: _handleSave,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'check',
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Save',
                          style:
                              AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
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
