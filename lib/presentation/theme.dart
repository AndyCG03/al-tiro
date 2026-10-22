import 'package:flutter/material.dart';

class Brand {
  static const green = Color(0xFF0A493A);
  static const pink = Color(0xFFED4F9B);
  static const logo = 'assets/images/ajolote.png';
  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(seedColor: green, brightness: brightness).copyWith(
          primary: dark ? const Color(0xFFA8DDC7) : green,
          secondary: pink,
          surface: dark ? const Color(0xFF15241F) : Colors.white,
          onSurface: dark ? const Color(0xFFF4F7F5) : const Color(0xFF153B33),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0C1713)
          : const Color(0xFFF7F9F7),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF0C1713)
            : const Color(0xFFF7F9F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
          color: scheme.onSurface,
        ),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(fontSize: 15, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 13, height: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: pink.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: scheme.onSurface,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
        space: 28,
      ),
    );
  }
}
