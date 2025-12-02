import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Settings state
  bool _darkMode = true;
  bool _autoSaveAnnotations = true;
  bool _showPageNumbers = true;
  bool _enableHaptics = true;
  double _defaultZoom = 1.0;
  String _defaultHighlightColor = 'Yellow';

  final List<String> _highlightColors = ['Yellow', 'Green', 'Blue', 'Pink', 'Orange'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.primaryDark,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Settings',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Settings Content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  
                  // Appearance Section
                  _buildSection(
                    title: 'Appearance',
                    children: [
                      _buildSwitchTile(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() => _darkMode = value);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _buildNavigationTile(
                        icon: Icons.palette,
                        title: 'Theme Customization',
                        subtitle: 'Colors and visual style',
                        onTap: () => Navigator.pushNamed(context, '/theme-customization'),
                      ),
                    ],
                  ),
                  
                  // Reading Section
                  _buildSection(
                    title: 'Reading',
                    children: [
                      _buildSwitchTile(
                        icon: Icons.numbers,
                        title: 'Show Page Numbers',
                        subtitle: 'Display page numbers in reader',
                        value: _showPageNumbers,
                        onChanged: (value) {
                          setState(() => _showPageNumbers = value);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _buildSliderTile(
                        icon: Icons.zoom_in,
                        title: 'Default Zoom',
                        value: _defaultZoom,
                        min: 0.5,
                        max: 2.0,
                        onChanged: (value) {
                          setState(() => _defaultZoom = value);
                        },
                      ),
                    ],
                  ),
                  
                  // Annotations Section
                  _buildSection(
                    title: 'Annotations',
                    children: [
                      _buildSwitchTile(
                        icon: Icons.save,
                        title: 'Auto-save Annotations',
                        subtitle: 'Automatically save changes',
                        value: _autoSaveAnnotations,
                        onChanged: (value) {
                          setState(() => _autoSaveAnnotations = value);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _buildDropdownTile(
                        icon: Icons.color_lens,
                        title: 'Default Highlight Color',
                        value: _defaultHighlightColor,
                        options: _highlightColors,
                        onChanged: (value) {
                          setState(() => _defaultHighlightColor = value!);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),
                  
                  // General Section
                  _buildSection(
                    title: 'General',
                    children: [
                      _buildSwitchTile(
                        icon: Icons.vibration,
                        title: 'Haptic Feedback',
                        subtitle: 'Vibration on interactions',
                        value: _enableHaptics,
                        onChanged: (value) {
                          setState(() => _enableHaptics = value);
                          if (value) HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),
                  
                  // About Section
                  _buildSection(
                    title: 'About',
                    children: [
                      _buildInfoTile(
                        icon: Icons.info_outline,
                        title: 'Version',
                        subtitle: 'FlutterReader Pro v1.0.0',
                      ),
                      _buildNavigationTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'View privacy information',
                        onTap: () => _showPrivacyPolicy(),
                      ),
                      _buildActionTile(
                        icon: Icons.restore,
                        title: 'Reset Settings',
                        subtitle: 'Restore default settings',
                        isDestructive: true,
                        onTap: () => _showResetDialog(),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        variant: CustomBottomBarVariant.magnetic,
        currentIndex: 3,
        enableHapticFeedback: true,
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: Text(
            title,
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(
        title,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(
        title,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentColor),
              SizedBox(width: 4.w),
              Text(
                title,
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
            inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(
        title,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(
              option,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: AppTheme.surfaceColor,
        underline: const SizedBox(),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(
        title,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.accentColor;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
          color: isDestructive ? color : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'FlutterReader Pro respects your privacy. All your documents and annotations are stored locally on your device. We do not collect, store, or share any personal data.',
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Settings?',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will restore all settings to their default values. This action cannot be undone.',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            child: Text(
              'Reset',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _darkMode = true;
      _autoSaveAnnotations = true;
      _showPageNumbers = true;
      _enableHaptics = true;
      _defaultZoom = 1.0;
      _defaultHighlightColor = 'Yellow';
    });
    
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings have been reset'),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
