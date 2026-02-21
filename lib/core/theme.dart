import 'package:flutter/material.dart';

class AppTheme {
  // Deep Professional Palette
  static const Color _orange = Color(0xFFF59E0B); // Productive Orange
  static const Color _background = Color(0xFF000000); // Pure Black for OLED
  static const Color _surface = Color(0xFF121212); // Deep Grey for Cards

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _background,
    
    // Updated to match your Orange/Black aesthetic
    colorScheme: ColorScheme.dark(
      primary: _orange,
      secondary: const Color(0xFF10B981), // Emerald
      surface: _surface,
      onSurface: Colors.white,
      primaryContainer: _orange.withOpacity(0.2),
    ),

    // Fixed CardTheme Implementation
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero, // Prevents unexpected gaps
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10, width: 1), // Subtle border
      ),
    ),

    // Modern AppBar look
    appBarTheme: const AppBarTheme(
      backgroundColor: _background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    ),

    // Standardized Text for legibility
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold, 
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      bodyLarge: TextStyle(color: Colors.white), 
      bodyMedium: TextStyle(color: Color(0xFF94A3B8)), // Slate-400
    ),

    // Fix for the Checkboxes in your TaskCards
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _orange;
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}