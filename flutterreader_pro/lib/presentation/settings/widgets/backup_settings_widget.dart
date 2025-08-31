import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BackupSettingsWidget extends StatefulWidget {
  const BackupSettingsWidget({super.key});

  @override
  State<BackupSettingsWidget> createState() => _BackupSettingsWidgetState();
}

class _BackupSettingsWidgetState extends State<BackupSettingsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _autoBackup = true;
  bool _encryptBackup = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  final Map<String, dynamic> _backupData = {
    "lastBackup": "2025-08-05 18:30:00",
    "backupSize": "2.1 MB",
    "itemsCount": 47,
    "cloudProvider": "Google Drive",
    "encryptionStatus": "AES-256 Encrypted",
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    _animationController.forward();

    // Simulate backup process
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isBackingUp = false;
      _backupData["lastBackup"] = DateTime.now().toString().substring(0, 19);
    });

    _animationController.reverse();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup completed successfully!',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _performRestore() async {
    setState(() {
      _isRestoring = true;
    });

    _animationController.forward();

    // Simulate restore process
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRestoring = false;
    });

    _animationController.reverse();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings restored successfully!',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackupHeader(),
                SizedBox(height: 2.h),
                _buildBackupStatus(),
                SizedBox(height: 2.h),
                _buildBackupSettings(),
                SizedBox(height: 2.h),
                _buildBackupActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackupHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomIconWidget(
            iconName: 'backup',
            color: AppTheme.accentColor,
            size: 24,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup & Sync',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Keep your settings and preferences safe',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 1.w),
              Text(
                'Active',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackupStatus() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Last Backup',
                  _formatBackupTime(_backupData["lastBackup"] as String),
                  'schedule',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatusItem(
                  'Backup Size',
                  _backupData["backupSize"] as String,
                  'folder',
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Divider(
            color: AppTheme.textSecondary.withValues(alpha: 0.2),
            height: 1,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Items',
                  '${_backupData["itemsCount"]} files',
                  'inventory',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatusItem(
                  'Security',
                  'Encrypted',
                  'security',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, String iconName) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.accentColor,
          size: 20,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSettings() {
    return Column(
      children: [
        _buildSettingToggle(
          'Auto Backup',
          'Automatically backup settings daily',
          _autoBackup,
          (value) {
            setState(() {
              _autoBackup = value;
            });
          },
          'sync',
        ),
        SizedBox(height: 1.h),
        _buildSettingToggle(
          'Encrypt Backup',
          'Secure your backup with encryption',
          _encryptBackup,
          (value) {
            setState(() {
              _encryptBackup = value;
            });
          },
          'lock',
        ),
      ],
    );
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    String iconName,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : AppTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: value ? AppTheme.accentColor : AppTheme.textSecondary,
              size: 18,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
            inactiveThumbColor: AppTheme.textSecondary,
            inactiveTrackColor: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _performBackup,
                icon: _isBackingUp
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.textPrimary,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'backup',
                        color: AppTheme.textPrimary,
                        size: 18,
                      ),
                label: Text(
                  _isBackingUp ? 'Backing up...' : 'Backup Now',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRestoring ? null : _performRestore,
                icon: _isRestoring
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentColor,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'restore',
                        color: AppTheme.accentColor,
                        size: 18,
                      ),
                label: Text(
                  _isRestoring ? 'Restoring...' : 'Restore',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.accentColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentColor),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'verified_user',
                color: AppTheme.successColor,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Your data is encrypted and securely stored. Only you can access your backups.',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBackupTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
