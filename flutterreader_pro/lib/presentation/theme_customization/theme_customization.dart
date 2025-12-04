import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Clean, functional theme customization page
class ThemeCustomization extends StatefulWidget {
  const ThemeCustomization({super.key});

  @override
  State<ThemeCustomization> createState() => _ThemeCustomizationState();
}

class _ThemeCustomizationState extends State<ThemeCustomization> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  
  String _selectedTheme = 'midnight';
  String _selectedAccentColor = '#6366F1';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    if (mounted) {
      setState(() {
        _selectedTheme = _settingsService.themeName;
        _selectedAccentColor = _settingsService.accentColor;
        _isLoading = false;
      });
    }
  }

  void _selectTheme(String themeId) async {
    final theme = SettingsService.getThemeByName(themeId);
    if (theme != null) {
      setState(() {
        _selectedTheme = themeId;
        _selectedAccentColor = theme['accent']!;
      });
      
      await _settingsService.setThemeName(themeId);
      await _settingsService.setAccentColor(theme['accent']!);
      
      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Theme "${theme['name']}" applied'),
              ],
            ),
            backgroundColor: SettingsService.colorFromHex(theme['accent']!),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(4.w),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Theme Customization',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Card
                  _buildPreviewCard(),
                  
                  SizedBox(height: 3.h),
                  
                  // Theme Selection
                  _buildSectionHeader('Choose Theme', Icons.palette),
                  SizedBox(height: 2.h),
                  _buildThemeGrid(),
                  
                  SizedBox(height: 4.h),
                  
                  // Apply Button
                  _buildApplyButton(),
                  
                  SizedBox(height: 4.h),
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewCard() {
    final currentTheme = SettingsService.getThemeByName(_selectedTheme);
    final accentColor = SettingsService.colorFromHex(_selectedAccentColor);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor,
            accentColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'BK-RDR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Preview: ${currentTheme?['name'] ?? 'Theme'}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            currentTheme?['description'] ?? 'Theme preview',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SettingsService.colorFromHex(_selectedAccentColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: SettingsService.colorFromHex(_selectedAccentColor), size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: SettingsService.availableThemes.length,
      itemBuilder: (context, index) {
        final theme = SettingsService.availableThemes[index];
        final isSelected = _selectedTheme == theme['id'];
        final accentColor = SettingsService.colorFromHex(theme['accent']!);
        
        return GestureDetector(
          onTap: () => _selectTheme(theme['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: SettingsService.colorFromHex(theme['surface']!),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Theme content
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Accent color bar
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      // Preview lines
                      Container(
                        height: 6,
                        width: 70.w * 0.35,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        height: 6,
                        width: 70.w * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Spacer(),
                      Text(
                        theme['name']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplyButton() {
    final accentColor = SettingsService.colorFromHex(_selectedAccentColor);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.save, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Theme settings saved'),
                ],
              ),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Apply Theme',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
