import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final Function(List<Offset>) onDrawingComplete;
  final Color selectedColor;
  final double strokeWidth;
  final VoidCallback onClose;

  const DrawingCanvasWidget({
    super.key,
    required this.onDrawingComplete,
    required this.selectedColor,
    this.strokeWidth = 3.0,
    required this.onClose,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;
  double _currentStrokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    _currentStrokeWidth = widget.strokeWidth;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.95),
        body: SafeArea(
          child: Column(
            children: [
              // Top toolbar
              _buildTopToolbar(),

              // Drawing canvas
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: DrawingPainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          color: widget.selectedColor,
                          strokeWidth: _currentStrokeWidth,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                size: 5.w,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drawing Mode',
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Draw with your finger or stylus',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearCanvas,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'clear',
                size: 5.w,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stroke width slider
          Row(
            children: [
              CustomIconWidget(
                iconName: 'brush',
                size: 5.w,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.selectedColor,
                    thumbColor: widget.selectedColor,
                    overlayColor: widget.selectedColor.withValues(alpha: 0.2),
                    inactiveTrackColor:
                        AppTheme.textSecondary.withValues(alpha: 0.3),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _currentStrokeWidth,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() {
                        _currentStrokeWidth = value;
                      });
                    },
                  ),
                ),
              ),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: widget.selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _undoLastStroke,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'undo',
                          size: 5.w,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Undo',
                          style: AppTheme.darkTheme.textTheme.labelMedium
                              ?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _saveDrawing,
                  child: Container(
                    height: 6.h,
                    decoration: AppTheme.gradientDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'check',
                          size: 5.w,
                          color: AppTheme.textPrimary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Save Drawing',
                          style: AppTheme.darkTheme.textTheme.labelMedium
                              ?.copyWith(
                            color: AppTheme.textPrimary,
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

  void _onPanStart(DragStartDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _isDrawing = true;
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _currentStroke.add(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing && _currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_currentStroke));
        _currentStroke.clear();
        _isDrawing = false;
      });
    }
  }

  void _clearCanvas() {
    HapticFeedback.mediumImpact();
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  void _undoLastStroke() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _saveDrawing() {
    HapticFeedback.mediumImpact();

    // Flatten all strokes into a single list of points
    List<Offset> allPoints = [];
    for (final stroke in _strokes) {
      allPoints.addAll(stroke);
    }

    if (allPoints.isNotEmpty) {
      widget.onDrawingComplete(allPoints);
    }

    widget.onClose();
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;
  final double strokeWidth;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);

        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }

        canvas.drawPath(path, paint);
      } else if (stroke.length == 1) {
        // Draw single point as a circle
        canvas.drawCircle(
            stroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke; // Reset style
      }
    }

    // Draw current stroke
    if (currentStroke.length > 1) {
      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);

      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }

      canvas.drawPath(path, paint);
    } else if (currentStroke.length == 1) {
      canvas.drawCircle(currentStroke.first, strokeWidth / 2,
          paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
