import 'package:flutter/material.dart';
import '../presentation/settings/settings.dart';
import '../presentation/annotation_tools/annotation_tools.dart';
import '../presentation/pdf_library/pdf_library.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/pdf_reader/pdf_reader.dart';
import '../presentation/theme_customization/theme_customization.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String settings = '/settings';
  static const String annotationTools = '/annotation-tools';
  static const String pdfLibrary = '/pdf-library';
  static const String homeDashboard = '/home-dashboard';
  static const String pdfReader = '/pdf-reader';
  static const String themeCustomization = '/theme-customization';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeDashboard(),
    settings: (context) => const Settings(),
    annotationTools: (context) => const AnnotationTools(),
    pdfLibrary: (context) => const PdfLibrary(),
    homeDashboard: (context) => const HomeDashboard(),
    pdfReader: (context) => const PdfReader(),
    themeCustomization: (context) => const ThemeCustomization(),
    // TODO: Add your other routes here
  };
}
