import 'package:flutter/material.dart';

class AppTheme {
  static Color getSeedColor(String themeColor) {
    switch (themeColor) {
      case 'Blue':
        return Colors.blueAccent;
      case 'Purple':
        return Colors.deepPurpleAccent;
      case 'Green':
        return const Color(0xFF0F9D58);
      case 'Pink':
        return Colors.pinkAccent;
      case 'Orange':
        return Colors.orangeAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }
}

class AppThemes {
  static ThemeData getTheme({
    required String themeMode,
    required String themeColor,
    required String fontSize,
  }) {
    final seed = AppTheme.getSeedColor(themeColor);
    final isDark = themeMode == 'Dark' || themeMode == 'OLED';
    final isOled = themeMode == 'OLED';

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: isDark ? Brightness.dark : Brightness.light,
      background: isOled ? Colors.black : (isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE)),
      surface: isOled ? const Color(0xFF0D0D0D) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
    );

    double getBodyScale() {
      if (fontSize == 'Small') return 0.9;
      if (fontSize == 'Large') return 1.15;
      return 1.0;
    }

    final scale = getBodyScale();
    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 57 * scale, fontWeight: FontWeight.bold, letterSpacing: -0.25),
      headlineMedium: TextStyle(fontSize: 28 * scale, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.background,
      cardTheme: CardTheme(
        color: colorScheme.surface,
        elevation: isOled ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isOled
              ? BorderSide(color: Colors.white.withOpacity(0.12), width: 1)
              : BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onBackground),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isOled ? Colors.black : colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
