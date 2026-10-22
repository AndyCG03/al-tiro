import 'package:flutter/material.dart';

class Brand {
  static const orange = Color(0xFFFF7900);
  static const amber = Color(0xFFFFBE22);
  static const charcoal = Color(0xFF171717);
  static const logo = 'assets/images/conductor.png';
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: orange,
          brightness: brightness,
        ).copyWith(
          primary: dark ? amber : const Color(0xFF9B3E00),
          onPrimary: dark ? charcoal : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF51300F)
              : const Color(0xFFFFDBAB),
          onPrimaryContainer: dark
              ? const Color(0xFFFFE8C8)
              : const Color(0xFF351800),
          secondary: dark ? orange : const Color(0xFF805200),
          onSecondary: dark ? charcoal : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF3B2A14)
              : const Color(0xFFFFEDCE),
          onSecondaryContainer: dark
              ? const Color(0xFFFFDCA3)
              : const Color(0xFF382500),
          tertiary: dark ? const Color(0xFFFFC66E) : const Color(0xFF77531E),
          onTertiary: dark ? charcoal : Colors.white,
          tertiaryContainer: dark
              ? const Color(0xFF44331E)
              : const Color(0xFFFFE9C7),
          onTertiaryContainer: dark
              ? const Color(0xFFFFE9C7)
              : const Color(0xFF382500),
          surface: dark ? const Color(0xFF222222) : Colors.white,
          onSurface: dark ? const Color(0xFFF8F5EF) : charcoal,
          onSurfaceVariant: dark
              ? const Color(0xFFCCC5BA)
              : const Color(0xFF5E554B),
          surfaceDim: dark ? const Color(0xFF151515) : const Color(0xFFE5DED4),
          surfaceBright: dark
              ? const Color(0xFF3D3934)
              : const Color(0xFFFFFBF5),
          surfaceContainerLowest: dark ? const Color(0xFF101010) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF1C1C1C)
              : const Color(0xFFFFFAF1),
          surfaceContainer: dark
              ? const Color(0xFF292621)
              : const Color(0xFFF6EFE5),
          surfaceContainerHigh: dark
              ? const Color(0xFF322E28)
              : const Color(0xFFF0E8DD),
          surfaceContainerHighest: dark
              ? const Color(0xFF3B352C)
              : const Color(0xFFEAE0D3),
          outline: dark ? const Color(0xFF978B7B) : const Color(0xFF817463),
          outlineVariant: dark
              ? const Color(0xFF50473C)
              : const Color(0xFFD7CABA),
          error: dark ? const Color(0xFFFFB38C) : const Color(0xFFAA3200),
          onError: dark ? const Color(0xFF391000) : Colors.white,
          errorContainer: dark
              ? const Color(0xFF5F2009)
              : const Color(0xFFFFDACA),
          onErrorContainer: dark
              ? const Color(0xFFFFDACA)
              : const Color(0xFF391000),
          inverseSurface: dark ? const Color(0xFFF4EDE2) : charcoal,
          onInverseSurface: dark ? charcoal : const Color(0xFFF4EDE2),
          inversePrimary: dark ? const Color(0xFF9B3E00) : amber,
          surfaceTint: orange,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: dark
          ? const Color(0xFF151515)
          : const Color(0xFFFAF7F2),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF151515)
            : const Color(0xFFFAF7F2),
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
          backgroundColor: orange,
          foregroundColor: charcoal,
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
        indicatorColor: scheme.primaryContainer,
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
