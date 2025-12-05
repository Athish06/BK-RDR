import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

import 'package:flutterreader_pro/core/services/settings_service.dart';

void main() async {
  print("🚀 App starting...");
  WidgetsFlutterBinding.ensureInitialized();
  print("✅ WidgetsBinding initialized");

  // Initialize Supabase
  try {
    final envString = await rootBundle.loadString('assets/env.json');
    final env = json.decode(envString);
    
    await Supabase.initialize(
      url: env['SUPABASE_URL'] ?? '',
      anonKey: env['SUPABASE_ANON_KEY'] ?? '',
    );
    print("✅ Supabase initialized");
  } catch (e) {
    print("⚠️ Supabase initialization failed: $e");
  }

  // Initialize Settings (must be after Supabase init)
  final settingsService = SettingsService();
  await settingsService.init();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    print("🔴 Error caught by ErrorWidget: ${details.exception}");
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  // Modified to not block app startup on web
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) => print("📱 Orientation set"))
      .catchError((e) => print("⚠️ Orientation lock failed: $e"));
      
  print("🚀 Calling runApp");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Check for unsaved annotations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUnsavedAnnotations();
    });
  }

  Future<void> _checkUnsavedAnnotations() async {
    try {
      final annotationService = AnnotationService();
      final hasUnsaved = await annotationService.hasUnsavedAnnotations();
      
      if (hasUnsaved && _navigatorKey.currentContext != null) {
        final context = _navigatorKey.currentContext!;
        
        // Show dialog to user
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Unsaved Annotations Found',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Text(
              'You have unsaved annotations from your last session. Would you like to save them to the cloud?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'discard'),
                child: Text('Discard', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                onPressed: () => Navigator.pop(context, 'save'),
                child: Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        
        if (result == 'save') {
          // Show saving indicator
          if (_navigatorKey.currentContext != null) {
            showDialog(
              context: _navigatorKey.currentContext!,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Row(
                  children: [
                    CircularProgressIndicator(color: AppTheme.accentColor),
                    SizedBox(width: 16),
                    Text('Saving annotations...', style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            );
            
            final success = await annotationService.saveAndClose();
            Navigator.pop(_navigatorKey.currentContext!); // Close saving dialog
            
            if (_navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Annotations saved!' : 'Failed to save annotations'),
                  backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          // Discard unsaved annotations
          await annotationService.clearLocalAnnotations();
        }
      }
    } catch (e) {
      print('⚠️ Error checking unsaved annotations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ MyApp build called");
    return Sizer(builder: (context, orientation, screenType) {
      print("📏 Sizer builder called");
      return AnimatedBuilder(
        animation: SettingsService(),
        builder: (context, child) {
          final settings = SettingsService();
          // Create theme data based on settings
          final themeData = settings.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
          // Apply accent color override if needed (simplified for now)
          
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'flutterreader_pro',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
            // 🚨 END CRITICAL SECTION
            debugShowCheckedModeBanner: false,
            routes: AppRoutes.routes,
            initialRoute: AppRoutes.initial,
          );
        },
      );
    });
  }
}
