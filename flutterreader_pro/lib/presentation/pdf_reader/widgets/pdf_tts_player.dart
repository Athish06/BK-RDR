import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PdfTtsPlayer extends StatefulWidget {
  final bool isVisible;
  final bool isPlaying;
  final bool isPaused;
  final double progress;
  final String currentSentence;
  final double playbackSpeed;
  final VoidCallback? onPlayPause;
  final VoidCallback? onStop;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<double>? onSpeedChanged;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onClose;

  const PdfTtsPlayer({
    super.key,
    required this.isVisible,
    this.isPlaying = false,
    this.isPaused = false,
    this.progress = 0.0,
    this.currentSentence = '',
    this.playbackSpeed = 1.0,
    this.onPlayPause,
    this.onStop,
    this.onPrevious,
    this.onNext,
    this.onSpeedChanged,
    this.onSeek,
    this.onClose,
  });

  @override
  State<PdfTtsPlayer> createState() => _PdfTtsPlayerState();
}

class _PdfTtsPlayerState extends State<PdfTtsPlayer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _showSpeedControl = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _slideController.forward();
    }

    if (widget.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PdfTtsPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePlayPause() {
    HapticFeedback.lightImpact();
    widget.onPlayPause?.call();
  }

  void _handleStop() {
    HapticFeedback.lightImpact();
    widget.onStop?.call();
  }

  void _handlePrevious() {
    HapticFeedback.lightImpact();
    widget.onPrevious?.call();
  }

  void _handleNext() {
    HapticFeedback.lightImpact();
    widget.onNext?.call();
  }

  void _toggleSpeedControl() {
    setState(() {
      _showSpeedControl = !_showSpeedControl;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 15.h,
      left: 4.w,
      right: 4.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.gradientDecoration().gradient,
            borderRadius: BorderRadius.circular(20),
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
              // Speed control panel
              if (_showSpeedControl)
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Playback Speed',
                            style: AppTheme.darkTheme.textTheme.labelMedium
                                ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${widget.playbackSpeed.toStringAsFixed(1)}x',
                            style: AppTheme.dataTextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'slow_motion_video',
                            color: AppTheme.textSecondary,
                            size: 16,
                          ),
                          Expanded(
                            child: Slider(
                              value: widget.playbackSpeed,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              activeColor: Colors.white,
                              inactiveColor:
                                  Colors.white.withValues(alpha: 0.3),
                              onChanged: (value) {
                                HapticFeedback.selectionClick();
                                widget.onSpeedChanged?.call(value);
                              },
                            ),
                          ),
                          CustomIconWidget(
                            iconName: 'fast_forward',
                            color: AppTheme.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Main player controls
              Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    // Current sentence display
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: widget.isPlaying
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  padding: EdgeInsets.all(1.5.w),
                                  decoration: BoxDecoration(
                                    color: widget.isPlaying
                                        ? AppTheme.successColor
                                        : AppTheme.textSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomIconWidget(
                                    iconName: 'record_voice_over',
                                    color: AppTheme.textPrimary,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now Reading',
                                  style: AppTheme.darkTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  widget.currentSentence.isNotEmpty
                                      ? widget.currentSentence
                                      : 'Select text to start reading',
                                  style: AppTheme.darkTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontStyle: widget.currentSentence.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                                color: AppTheme.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: 'skip_previous',
                          onTap: _handlePrevious,
                          size: 28,
                        ),
                        _buildControlButton(
                          icon: widget.isPlaying ? 'pause' : 'play_arrow',
                          onTap: _handlePlayPause,
                          size: 36,
                          isPrimary: true,
                        ),
                        _buildControlButton(
                          icon: 'skip_next',
                          onTap: _handleNext,
                          size: 28,
                        ),
                        _buildControlButton(
                          icon: 'stop',
                          onTap: _handleStop,
                          size: 24,
                        ),
                        _buildControlButton(
                          icon: 'speed',
                          onTap: _toggleSpeedControl,
                          size: 24,
                          isActive: _showSpeedControl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String icon,
    required VoidCallback onTap,
    required double size,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isPrimary ? 3.w : 2.w),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white.withValues(alpha: 0.3)
              : isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isPrimary ? 20 : 12),
          border: isPrimary
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }
}
