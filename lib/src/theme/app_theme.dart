import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    const background = Color(0xFF05070B);
    const surface = Color(0xFF0B0F16);
    const surfaceHigh = Color(0xFF111821);
    const border = Color(0xFF202936);
    const primary = Color(0xFFBFEFE4);

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
        backgroundColor: const Color(0xF205070B),
        indicatorColor: primary.withValues(alpha: 0.12),
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
        fillColor: const Color(0xFF090D13),
        hintStyle: const TextStyle(color: Color(0xFF697384)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x66202936)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x66202936)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x99BFEFE4)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF0D121A),
        selectedColor: primary.withValues(alpha: 0.10),
        side: const BorderSide(color: Color(0x55202936)),
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
          backgroundColor: const Color(0xFFE8EEF8),
          foregroundColor: const Color(0xFF05070B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8EEF8),
          side: const BorderSide(color: Color(0x66202936)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
