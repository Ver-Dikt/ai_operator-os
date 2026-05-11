import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    const background = Color(0xFF090B10);
    const surface = Color(0xFF121722);
    const surfaceHigh = Color(0xFF18202D);
    const border = Color(0xFF263244);
    const primary = Color(0xFF6BE4C9);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Color(0xFF061311),
        secondary: Color(0xFFFFB86B),
        tertiary: Color(0xFFFF6B8A),
        surface: surface,
        surfaceContainerHighest: surfaceHigh,
        outline: border,
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: const Color(0xFFE8EEF8),
        displayColor: const Color(0xFFF8FBFF),
        fontFamily: 'Segoe UI',
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xEE0B0F16),
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : const Color(0xFF8B97A8),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E131C),
        hintStyle: const TextStyle(color: Color(0xFF7E8B9D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF101722),
        selectedColor: primary.withValues(alpha: 0.16),
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(
          color: Color(0xFFC8D2E1),
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF061311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8EEF8),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
