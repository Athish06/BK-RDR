import 'package:flutter/material.dart';
import 'package:flutterreader_pro/core/services/settings_service.dart';
import 'package:flutterreader_pro/presentation/theme_customization/theme_customization.dart';
import 'package:flutterreader_pro/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Section
                  _buildSectionHeader('Appearance'),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple,
                    title: 'Theme & Colors',
                    subtitle: 'Customize app theme and accent colors',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeCustomization(),
                        ),
                      );
                      // Refresh settings after returning
                      await _settings.loadSettings();
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // Reader Section
                  _buildSectionHeader('Reader'),
                  const SizedBox(height: 12),
                  _buildColorPickerTile(
                    icon: Icons.highlight,
                    iconColor: Colors.amber,
                    title: 'Default Highlight Color',
                    subtitle: 'Color used for new highlights',
                    currentColor: _settings.defaultHighlightColorAsColor,
                    onColorChanged: (color) async {
                      // Find the color name from the color value
                      final colorName = _getColorNameFromColor(color);
                      await _settings.setDefaultHighlightColor(colorName);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDropdownTile<String>(
                    icon: Icons.swap_vert_rounded,
                    iconColor: Colors.blue,
                    title: 'Scroll Direction',
                    subtitle: 'How pages scroll in the reader',
                    value: _settings.scrollDirection,
                    items: const [
                      DropdownMenuItem(value: 'vertical', child: Text('Vertical')),
                      DropdownMenuItem(value: 'horizontal', child: Text('Horizontal')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await _settings.setScrollDirection(value);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    icon: Icons.numbers_rounded,
                    iconColor: Colors.green,
                    title: 'Show Page Numbers',
                    subtitle: 'Display page indicator while reading',
                    value: _settings.showPageNumbers,
                    onChanged: (value) async {
                      await _settings.setShowPageNumbers(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDropdownTile<double>(
                    icon: Icons.zoom_in_rounded,
                    iconColor: Colors.orange,
                    title: 'Default Zoom',
                    subtitle: 'Initial zoom level when opening PDFs',
                    value: _settings.defaultZoom,
                    items: const [
                      DropdownMenuItem(value: 1.0, child: Text('100%')),
                      DropdownMenuItem(value: 1.25, child: Text('125%')),
                      DropdownMenuItem(value: 1.5, child: Text('150%')),
                      DropdownMenuItem(value: 1.75, child: Text('175%')),
                      DropdownMenuItem(value: 2.0, child: Text('200%')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await _settings.setDefaultZoom(value);
                        setState(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Behavior Section
                  _buildSectionHeader('Behavior'),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    icon: Icons.vibration_rounded,
                    iconColor: Colors.red,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on certain actions',
                    value: _settings.enableHaptics,
                    onChanged: (value) async {
                      await _settings.setEnableHaptics(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    icon: Icons.brightness_high_rounded,
                    iconColor: Colors.yellow,
                    title: 'Keep Screen On',
                    subtitle: 'Prevent screen from turning off while reading',
                    value: _settings.keepScreenOn,
                    onChanged: (value) async {
                      await _settings.setKeepScreenOn(value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionHeader('About'),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.teal,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    onTap: null,
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.indigo,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _launchUrl('https://example.com/privacy'),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.cyan,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms of service',
                    onTap: () => _launchUrl('https://example.com/terms'),
                  ),

                  const SizedBox(height: 32),

                  // Reset Button
                  Center(
                    child: TextButton.icon(
                      onPressed: _showResetDialog,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.red),
                      label: const Text(
                        'Reset All Settings',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppTheme.surfaceColor,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    final colors = [
      Colors.yellow,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: colors.map((color) {
              final isSelected = currentColor.value == color.value;
              return GestureDetector(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Reset Settings',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _settings.resetToDefaults();
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings reset to defaults'),
                    backgroundColor: AppTheme.accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getColorNameFromColor(Color color) {
    final colorMap = {
      Colors.yellow.value: 'Yellow',
      Colors.blue.value: 'Blue',
      Colors.green.value: 'Green',
      Colors.red.value: 'Red',
      Colors.purple.value: 'Purple',
      Colors.orange.value: 'Orange',
      Colors.pink.value: 'Pink',
      Colors.teal.value: 'Cyan',
    };
    return colorMap[color.value] ?? 'Yellow';
  }
}
