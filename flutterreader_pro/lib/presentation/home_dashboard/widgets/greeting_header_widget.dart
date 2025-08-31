import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GreetingHeaderWidget extends StatefulWidget {
  final int readingStreak;
  final VoidCallback? onRefresh;

  const GreetingHeaderWidget({
    super.key,
    required this.readingStreak,
    this.onRefresh,
  });

  @override
  State<GreetingHeaderWidget> createState() => _GreetingHeaderWidgetState();
}

class _GreetingHeaderWidgetState extends State<GreetingHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late Animation<double> _flameAnimation;
  late AnimationController _streakController;
  late Animation<double> _streakAnimation;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _streakController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flameAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _flameController,
      curve: Curves.easeInOut,
    ));

    _streakAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _streakController,
      curve: Curves.elasticOut,
    ));

    _flameController.repeat(reverse: true);
    _streakController.forward();
  }

  @override
  void dispose() {
    _flameController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Ready to continue your reading journey?',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _streakAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _streakAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientDecoration().gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _flameAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _flameAnimation.value,
                            child: CustomIconWidget(
                              iconName: 'local_fire_department',
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${widget.readingStreak}',
                        style:
                            AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
