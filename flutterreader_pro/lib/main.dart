import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("🏗️ MyApp build called");
    return Sizer(builder: (context, orientation, screenType) {
      print("📏 Sizer builder called");
      return MaterialApp(
        title: 'flutterreader_pro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
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
    });
  }
}
