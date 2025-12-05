import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing app settings with local cache and Supabase sync
class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;
  SettingsService._internal();
  factory SettingsService() => _instance ??= SettingsService._internal();

  SharedPreferences? _prefs;
  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Cached settings for instant access
  Map<String, dynamic> _cachedSettings = {};
  bool _initialized = false;
  
  // Device ID for Supabase
  String? _deviceId;

  // Settings keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyThemeName = 'theme_name';
  static const String keyAccentColor = 'accent_color';
  static const String keyShowPageNumbers = 'show_page_numbers';
  static const String keyPageNumberDuration = 'page_number_duration';
  static const String keyDefaultZoom = 'default_zoom';
  static const String keyScrollDirection = 'scroll_direction';
  static const String keyKeepScreenOn = 'keep_screen_on';
  static const String keyDoubleTapZoom = 'double_tap_zoom';
  static const String keyAutoSave = 'auto_save_annotations';
  static const String keyHighlightColor = 'default_highlight_color';
  static const String keyEnableHaptics = 'enable_haptics';

  // Default settings
  static const Map<String, dynamic> defaultSettings = {
    keyDarkMode: true,
    keyThemeName: 'midnight',
    keyAccentColor: '#6366F1',
    keyShowPageNumbers: true,
    keyPageNumberDuration: 3,
    keyDefaultZoom: 1.0,
    keyScrollDirection: 'vertical',
    keyKeepScreenOn: true,
    keyDoubleTapZoom: 2.0,
    keyAutoSave: true,
    keyHighlightColor: 'Yellow',
    keyEnableHaptics: true,
  };

  // Available themes
  static const List<Map<String, dynamic>> availableThemes = [
    {
      'id': 'midnight',
      'name': 'Midnight',
      'description': 'Pure dark with indigo accents',
      'accent': '#6366F1',
      'surface': '#1E1E2E',
      'background': '#0A0A0F',
    },
    {
      'id': 'ocean',
      'name': 'Ocean Blue',
      'description': 'Calm blue tones',
      'accent': '#0EA5E9',
      'surface': '#1E293B',
      'background': '#0F172A',
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'description': 'Natural green shades',
      'accent': '#10B981',
      'surface': '#1A2E25',
      'background': '#0D1912',
    },
    {
      'id': 'sunset',
      'name': 'Sunset',
      'description': 'Warm orange glow',
      'accent': '#F59E0B',
      'surface': '#2D2418',
      'background': '#1A150D',
    },
    {
      'id': 'rose',
      'name': 'Rose',
      'description': 'Elegant pink tones',
      'accent': '#F43F5E',
      'surface': '#2D1F24',
      'background': '#1A1114',
    },
    {
      'id': 'lavender',
      'name': 'Lavender',
      'description': 'Soft purple vibes',
      'accent': '#A855F7',
      'surface': '#251D2E',
      'background': '#14101A',
    },
  ];

  // Available highlight colors
  static const List<Map<String, dynamic>> highlightColors = [
    {'name': 'Yellow', 'color': '#FFEB3B'},
    {'name': 'Green', 'color': '#4CAF50'},
    {'name': 'Blue', 'color': '#2196F3'},
    {'name': 'Pink', 'color': '#E91E63'},
    {'name': 'Orange', 'color': '#FF9800'},
    {'name': 'Red', 'color': '#F44336'},
    {'name': 'Purple', 'color': '#9C27B0'},
    {'name': 'Cyan', 'color': '#00BCD4'},
  ];

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _deviceId = _prefs!.getString('device_id');
    
    if (_deviceId == null) {
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs!.setString('device_id', _deviceId!);
    }
    
    // Load from local cache first
    _loadFromLocalCache();
    
    // Then sync with Supabase
    await _syncFromSupabase();
    
    _initialized = true;
  }

  void _loadFromLocalCache() {
    for (final key in defaultSettings.keys) {
      final value = _prefs!.get(key);
      _cachedSettings[key] = value ?? defaultSettings[key];
    }
  }

  Future<void> _syncFromSupabase() async {
    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('device_id', _deviceId!)
          .maybeSingle();

      if (response != null) {
        // Update local cache with Supabase data
        _cachedSettings = {
          keyDarkMode: response['dark_mode'] ?? defaultSettings[keyDarkMode],
          keyThemeName: response['theme_name'] ?? defaultSettings[keyThemeName],
          keyAccentColor: response['accent_color'] ?? defaultSettings[keyAccentColor],
          keyShowPageNumbers: response['show_page_numbers'] ?? defaultSettings[keyShowPageNumbers],
          keyPageNumberDuration: response['page_number_duration'] ?? defaultSettings[keyPageNumberDuration],
          keyDefaultZoom: (response['default_zoom'] as num?)?.toDouble() ?? defaultSettings[keyDefaultZoom],
          keyScrollDirection: response['scroll_direction'] ?? defaultSettings[keyScrollDirection],
          keyKeepScreenOn: response['keep_screen_on'] ?? defaultSettings[keyKeepScreenOn],
          keyDoubleTapZoom: (response['double_tap_zoom'] as num?)?.toDouble() ?? defaultSettings[keyDoubleTapZoom],
          keyAutoSave: response['auto_save_annotations'] ?? defaultSettings[keyAutoSave],
          keyHighlightColor: response['default_highlight_color'] ?? defaultSettings[keyHighlightColor],
          keyEnableHaptics: response['enable_haptics'] ?? defaultSettings[keyEnableHaptics],
        };
        // Update local cache
        await _saveToLocalCache();
        notifyListeners(); // Notify after sync
        print('✅ Settings synced from Supabase');
      } else {
        // Create new settings record in Supabase
        await _saveToSupabase();
        print('✅ New settings record created in Supabase');
      }
    } catch (e) {
      print('⚠️ Could not sync settings from Supabase: $e');
      // Use local cache as fallback
    }
  }

  Future<void> _saveToLocalCache() async {
    for (final entry in _cachedSettings.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is String) {
        await _prefs!.setString(key, value);
      }
    }
  }

  Future<void> _saveToSupabase() async {
    try {
      await _supabase.from('user_settings').upsert({
        'device_id': _deviceId,
        'dark_mode': _cachedSettings[keyDarkMode],
        'theme_name': _cachedSettings[keyThemeName],
        'accent_color': _cachedSettings[keyAccentColor],
        'show_page_numbers': _cachedSettings[keyShowPageNumbers],
        'page_number_duration': _cachedSettings[keyPageNumberDuration],
        'default_zoom': _cachedSettings[keyDefaultZoom],
        'scroll_direction': _cachedSettings[keyScrollDirection],
        'keep_screen_on': _cachedSettings[keyKeepScreenOn],
        'double_tap_zoom': _cachedSettings[keyDoubleTapZoom],
        'auto_save_annotations': _cachedSettings[keyAutoSave],
        'default_highlight_color': _cachedSettings[keyHighlightColor],
        'enable_haptics': _cachedSettings[keyEnableHaptics],
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');
      print('✅ Settings saved to Supabase');
    } catch (e) {
      print('⚠️ Could not save settings to Supabase: $e');
    }
  }

  /// Update a setting (saves locally and syncs to Supabase)
  Future<void> setSetting(String key, dynamic value) async {
    _cachedSettings[key] = value;
    notifyListeners(); // Notify listeners of change
    await _saveToLocalCache();
    await _saveToSupabase();
  }

  /// Get a setting value (from cache for instant access)
  T getSetting<T>(String key) {
    return _cachedSettings[key] ?? defaultSettings[key] as T;
  }

  // ==================== CONVENIENCE GETTERS ====================

  bool get darkMode => getSetting<bool>(keyDarkMode);
  String get themeName => getSetting<String>(keyThemeName);
  String get accentColor => getSetting<String>(keyAccentColor);
  bool get showPageNumbers => getSetting<bool>(keyShowPageNumbers);
  int get pageNumberDuration => getSetting<int>(keyPageNumberDuration);
  double get defaultZoom => getSetting<double>(keyDefaultZoom);
  String get scrollDirection => getSetting<String>(keyScrollDirection);
  bool get keepScreenOn => getSetting<bool>(keyKeepScreenOn);
  double get doubleTapZoom => getSetting<double>(keyDoubleTapZoom);
  bool get autoSaveAnnotations => getSetting<bool>(keyAutoSave);
  String get defaultHighlightColor => getSetting<String>(keyHighlightColor);
  bool get enableHaptics => getSetting<bool>(keyEnableHaptics);

  // ==================== CONVENIENCE SETTERS ====================

  Future<void> setDarkMode(bool value) => setSetting(keyDarkMode, value);
  Future<void> setThemeName(String value) => setSetting(keyThemeName, value);
  Future<void> setAccentColor(String value) => setSetting(keyAccentColor, value);
  Future<void> setShowPageNumbers(bool value) => setSetting(keyShowPageNumbers, value);
  Future<void> setPageNumberDuration(int value) => setSetting(keyPageNumberDuration, value);
  Future<void> setDefaultZoom(double value) => setSetting(keyDefaultZoom, value);
  Future<void> setScrollDirection(String value) => setSetting(keyScrollDirection, value);
  Future<void> setKeepScreenOn(bool value) => setSetting(keyKeepScreenOn, value);
  Future<void> setDoubleTapZoom(double value) => setSetting(keyDoubleTapZoom, value);
  Future<void> setAutoSaveAnnotations(bool value) => setSetting(keyAutoSave, value);
  Future<void> setDefaultHighlightColor(String value) => setSetting(keyHighlightColor, value);
  Future<void> setEnableHaptics(bool value) => setSetting(keyEnableHaptics, value);

  // ==================== RESET ====================

  Future<void> resetAllSettings() async {
    _cachedSettings = Map.from(defaultSettings);
    notifyListeners();
    await _saveToLocalCache();
    await _saveToSupabase();
  }

  /// Alias for resetAllSettings
  Future<void> resetToDefaults() => resetAllSettings();

  /// Async getter for page number duration
  Future<int> getPageNumberDuration() async {
    await init();
    return pageNumberDuration;
  }

  // ==================== HELPERS ====================

  /// Get Color from color name
  static Color colorFromName(String name) {
    final colorData = highlightColors.firstWhere(
      (c) => c['name'] == name,
      orElse: () => highlightColors.first,
    );
    return colorFromHex(colorData['color']!);
  }

  /// Get Color from hex string
  static Color colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Get theme data by name
  static Map<String, dynamic>? getThemeByName(String name) {
    return availableThemes.firstWhere(
      (t) => t['id'] == name,
      orElse: () => availableThemes.first,
    );
  }

  /// Get accent color as Color
  Color getAccentColorAsColor() {
    return colorFromHex(accentColor);
  }

  /// Get default highlight color as Color
  Color get defaultHighlightColorAsColor => colorFromName(defaultHighlightColor);

  /// Check if horizontal scroll
  bool get isHorizontalScroll => scrollDirection == 'horizontal';

  /// Load settings for external use
  Future<void> loadSettings() async {
    await _syncFromSupabase();
  }
}
