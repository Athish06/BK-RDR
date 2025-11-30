import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/settings_search_widget.dart';
import './widgets/settings_section_widget.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final Map<String, bool> _expandedSections = {
    'Reading Preferences': false,
    'Appearance': false,
    'Annotations': false,
    'Audio': false,
    'Privacy': false,
    'About': false,
  };

  // Settings data with search keywords
  final Map<String, List<SettingsItemData>> _settingsData = {};
  final Map<String, List<String>> _searchKeywords = {};
  bool _settingsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_settingsInitialized) {
      _initializeSettingsData();
      _settingsInitialized = true;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
  }

  void _initializeSettingsData() {
    _settingsData['Reading Preferences'] = [
      SettingsItemData(
        title: 'Auto-scroll Speed',
        subtitle: 'Adjust automatic scrolling speed',
        icon: 'speed',
        iconColor: AppTheme.accentColor,
        trailing: _buildSpeedSlider(),
        onTap: () => _showSpeedDialog(),
      ),
      SettingsItemData(
        title: 'Page Turn Animation',
        subtitle: 'Choose page transition style',
        icon: 'flip_to_front',
        iconColor: AppTheme.successColor,
        hasNavigation: true,
        onTap: () => _showAnimationOptions(),
      ),
      SettingsItemData(
        title: 'Gesture Sensitivity',
        subtitle: 'Adjust touch gesture responsiveness',
        icon: 'touch_app',
        iconColor: AppTheme.warningColor,
        trailing: _buildSensitivityIndicator(),
        onTap: () => _showGestureSettings(),
      ),
      SettingsItemData(
        title: 'Reading Mode',
        subtitle: 'Continuous or page-by-page',
        icon: 'chrome_reader_mode',
        iconColor: AppTheme.gradientEnd,
        hasNavigation: true,
        onTap: () => Navigator.pushNamed(context, '/pdf-reader'),
      ),
    ];

    _settingsData['Appearance'] = [
      SettingsItemData(
        title: 'Theme Customization',
        subtitle: 'Colors, gradients, and visual style',
        icon: 'palette',
        iconColor: AppTheme.accentColor,
        trailing: _buildThemePreview(),
        hasNavigation: true,
        onTap: () => Navigator.pushNamed(context, '/theme-customization'),
      ),
      SettingsItemData(
        title: 'Font Settings',
        subtitle: 'Size, family, and spacing',
        icon: 'text_fields',
        iconColor: AppTheme.successColor,
        hasNavigation: true,
        onTap: () => _showFontSettings(),
      ),
      SettingsItemData(
        title: 'Display Brightness',
        subtitle: 'Auto-adjust for reading comfort',
        icon: 'brightness_6',
        iconColor: AppTheme.warningColor,
        trailing: _buildBrightnessToggle(),
        onTap: () => _toggleAutoBrightness(),
      ),
      SettingsItemData(
        title: 'Navigation Style',
        subtitle: 'Bottom bar appearance and behavior',
        icon: 'navigation',
        iconColor: AppTheme.gradientEnd,
        hasNavigation: true,
        onTap: () => _showNavigationOptions(),
      ),
    ];

    _settingsData['Annotations'] = [
      SettingsItemData(
        title: 'Default Colors',
        subtitle: 'Set preferred highlight and note colors',
        icon: 'color_lens',
        iconColor: AppTheme.accentColor,
        trailing: _buildColorPalette(),
        onTap: () => Navigator.pushNamed(context, '/annotation-tools'),
      ),
      SettingsItemData(
        title: 'Note Templates',
        subtitle: 'Create reusable annotation templates',
        icon: 'note_add',
        iconColor: AppTheme.successColor,
        hasNavigation: true,
        onTap: () => _showNoteTemplates(),
      ),
      SettingsItemData(
        title: 'Export Format',
        subtitle: 'Choose default export format',
        icon: 'file_download',
        iconColor: AppTheme.warningColor,
        trailing: Text(
          'JSON',
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        onTap: () => _showExportOptions(),
      ),
      SettingsItemData(
        title: 'Auto-save',
        subtitle: 'Automatically save annotations',
        icon: 'save',
        iconColor: AppTheme.gradientEnd,
        trailing: _buildAutoSaveToggle(),
        onTap: () => _toggleAutoSave(),
      ),
    ];

    _settingsData['Audio'] = [
      SettingsItemData(
        title: 'Text-to-Speech Voice',
        subtitle: 'Select preferred voice and language',
        icon: 'record_voice_over',
        iconColor: AppTheme.accentColor,
        trailing: Text(
          'English (US)',
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        hasNavigation: true,
        onTap: () => _showVoiceSettings(),
      ),
      SettingsItemData(
        title: 'Speech Speed',
        subtitle: 'Adjust reading speed',
        icon: 'speed',
        iconColor: AppTheme.successColor,
        trailing: _buildSpeedIndicator(),
        onTap: () => _showSpeedSettings(),
      ),
      SettingsItemData(
        title: 'Test Playback',
        subtitle: 'Preview current voice settings',
        icon: 'play_circle',
        iconColor: AppTheme.warningColor,
        onTap: () => _testPlayback(),
      ),
      SettingsItemData(
        title: 'Audio Controls',
        subtitle: 'Floating player preferences',
        icon: 'audio_file',
        iconColor: AppTheme.gradientEnd,
        hasNavigation: true,
        onTap: () => _showAudioControls(),
      ),
    ];

    _settingsData['Privacy'] = [
      SettingsItemData(
        title: 'Biometric Authentication',
        subtitle: 'Secure app access with fingerprint/face',
        icon: 'fingerprint',
        iconColor: AppTheme.accentColor,
        trailing: _buildBiometricToggle(),
        onTap: () => _toggleBiometric(),
      ),
      SettingsItemData(
        title: 'Data Export',
        subtitle: 'Export your reading data and annotations',
        icon: 'file_upload',
        iconColor: AppTheme.successColor,
        hasNavigation: true,
        onTap: () => _exportData(),
      ),
      SettingsItemData(
        title: 'Analytics Sharing',
        subtitle: 'Help improve the app with usage data',
        icon: 'analytics',
        iconColor: AppTheme.warningColor,
        trailing: _buildAnalyticsToggle(),
        onTap: () => _toggleAnalytics(),
      ),
      SettingsItemData(
        title: 'Privacy Policy',
        subtitle: 'View our privacy and data practices',
        icon: 'privacy_tip',
        iconColor: AppTheme.gradientEnd,
        hasNavigation: true,
        onTap: () => _showPrivacyPolicy(),
      ),
    ];

    _settingsData['About'] = [
      SettingsItemData(
        title: 'Version Information',
        subtitle: 'FlutterReader Pro v2.1.0 (Build 2025080501)',
        icon: 'info',
        iconColor: AppTheme.accentColor,
        onTap: () => _showVersionInfo(),
      ),
      SettingsItemData(
        title: 'Help & Support',
        subtitle: 'Get help and contact support',
        icon: 'help',
        iconColor: AppTheme.successColor,
        hasNavigation: true,
        onTap: () => _showHelp(),
      ),
      SettingsItemData(
        title: 'Rate the App',
        subtitle: 'Share your experience on the App Store',
        icon: 'star_rate',
        iconColor: AppTheme.warningColor,
        hasNavigation: true,
        onTap: () => _rateApp(),
      ),
      SettingsItemData(
        title: 'Reset Settings',
        subtitle: 'Restore all settings to default',
        icon: 'restore',
        iconColor: AppTheme.errorColor,
        onTap: () => _showResetDialog(),
      ),
    ];

    // Initialize search keywords
    _searchKeywords['Reading Preferences'] = [
      'auto scroll',
      'speed',
      'page turn',
      'animation',
      'gesture',
      'sensitivity',
      'reading mode',
      'continuous'
    ];
    _searchKeywords['Appearance'] = [
      'theme',
      'color',
      'gradient',
      'font',
      'size',
      'brightness',
      'navigation',
      'style'
    ];
    _searchKeywords['Annotations'] = [
      'highlight',
      'note',
      'color',
      'template',
      'export',
      'save',
      'annotation'
    ];
    _searchKeywords['Audio'] = [
      'voice',
      'speech',
      'tts',
      'text to speech',
      'speed',
      'language',
      'audio',
      'playback'
    ];
    _searchKeywords['Privacy'] = [
      'biometric',
      'fingerprint',
      'face',
      'security',
      'data',
      'export',
      'analytics',
      'privacy'
    ];
    _searchKeywords['About'] = [
      'version',
      'help',
      'support',
      'rate',
      'reset',
      'info',
      'contact'
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });

    if (query.isNotEmpty) {
      _highlightMatchingSections();
    }
  }

  void _highlightMatchingSections() {
    for (String section in _settingsData.keys) {
      final keywords = _searchKeywords[section] ?? [];
      final items = _settingsData[section] ?? [];

      bool hasMatch = keywords
              .any((keyword) => keyword.contains(_searchQuery)) ||
          items.any((item) =>
              item.title.toLowerCase().contains(_searchQuery) ||
              (item.subtitle?.toLowerCase().contains(_searchQuery) ?? false));

      if (hasMatch && !_expandedSections[section]!) {
        setState(() {
          _expandedSections[section] = true;
        });
      }
    }
  }

  void _onSearchClear() {
    setState(() {
      _searchQuery = '';
      // Collapse all sections
      for (String key in _expandedSections.keys) {
        _expandedSections[key] = false;
      }
    });
  }

  void _toggleSection(String section) {
    HapticFeedback.lightImpact();
    setState(() {
      _expandedSections[section] = !_expandedSections[section]!;
    });
  }

  List<SettingsItemData> _getFilteredItems(String section) {
    if (_searchQuery.isEmpty) {
      return _settingsData[section] ?? [];
    }

    return (_settingsData[section] ?? []).where((item) {
      return item.title.toLowerCase().contains(_searchQuery) ||
          (item.subtitle?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: AppTheme.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'help_outline',
              color: AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: () => _showHelp(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SettingsSearchWidget(
                  onSearchChanged: _onSearchChanged,
                  onSearchClear: _onSearchClear,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sections = _settingsData.keys.toList();

                    if (index >= sections.length) {
                      return SizedBox(height: 10.h); // Bottom padding
                    }

                    final section = sections[index];
                    final filteredItems = _getFilteredItems(section);

                    if (_searchQuery.isNotEmpty && filteredItems.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return SettingsSectionWidget(
                      title: section,
                      items: filteredItems,
                      isExpanded: _expandedSections[section]!,
                      onToggle: () => _toggleSection(section),
                    );
                  },
                  childCount: _settingsData.length + 1, // +1 for padding
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget builders for trailing elements
  Widget _buildSpeedSlider() {
    return Container(
      width: 15.w,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        child: Slider(
          value: 0.6,
          onChanged: (value) {},
          activeColor: AppTheme.accentColor,
          inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildSensitivityIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Medium',
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.warningColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildThemePreview() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: AppTheme.gradientDecoration().gradient,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildBrightnessToggle() {
    return Switch(
      value: true,
      onChanged: (value) => _toggleAutoBrightness(),
      activeThumbColor: AppTheme.accentColor,
    );
  }

  Widget _buildColorPalette() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.warningColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSaveToggle() {
    return Switch(
      value: true,
      onChanged: (value) => _toggleAutoSave(),
      activeThumbColor: AppTheme.successColor,
    );
  }

  Widget _buildSpeedIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '1.2x',
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.successColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Switch(
      value: true,
      onChanged: (value) => _toggleBiometric(),
      activeThumbColor: AppTheme.accentColor,
    );
  }

  Widget _buildAnalyticsToggle() {
    return Switch(
      value: false,
      onChanged: (value) => _toggleAnalytics(),
      activeThumbColor: AppTheme.accentColor,
    );
  }

  // Action methods
  void _showSpeedDialog() {
    HapticFeedback.lightImpact();
    // Implementation for speed dialog
  }

  void _showAnimationOptions() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/pdf-reader');
  }

  void _showGestureSettings() {
    HapticFeedback.lightImpact();
    // Implementation for gesture settings
  }

  void _showFontSettings() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/theme-customization');
  }

  void _toggleAutoBrightness() {
    HapticFeedback.lightImpact();
    // Implementation for brightness toggle
  }

  void _showNavigationOptions() {
    HapticFeedback.lightImpact();
    // Implementation for navigation options
  }

  void _showNoteTemplates() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/annotation-tools');
  }

  void _showExportOptions() {
    HapticFeedback.lightImpact();
    // Implementation for export options
  }

  void _toggleAutoSave() {
    HapticFeedback.lightImpact();
    // Implementation for auto-save toggle
  }

  void _showVoiceSettings() {
    HapticFeedback.lightImpact();
    // Implementation for voice settings
  }

  void _showSpeedSettings() {
    HapticFeedback.lightImpact();
    // Implementation for speed settings
  }

  void _testPlayback() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Playing test audio with current settings...',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAudioControls() {
    HapticFeedback.lightImpact();
    // Implementation for audio controls
  }

  void _toggleBiometric() {
    HapticFeedback.lightImpact();
    // Implementation for biometric toggle
  }

  void _exportData() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exporting your data... This may take a moment.',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _toggleAnalytics() {
    HapticFeedback.lightImpact();
    // Implementation for analytics toggle
  }

  void _showPrivacyPolicy() {
    HapticFeedback.lightImpact();
    // Implementation for privacy policy
  }

  void _showVersionInfo() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Version Information',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FlutterReader Pro',
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Version: 2.1.0\nBuild: 2025080501\nRelease Date: August 5, 2025',
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/home-dashboard');
  }

  void _rateApp() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you! Redirecting to App Store...',
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

  void _showResetDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Reset Settings',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
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
              style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Settings have been reset to default values.',
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
            },
            child: Text(
              'Reset',
              style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
