import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const background = Color(0xFFF4F7FB);
    const surface = Color(0xFFFFFFFF);
    const surfaceHigh = Color(0xFFEAF0F7);
    const border = Color(0xFFD6E0EC);
    const primary = Color(0xFF136F63);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: Color(0xFFB66A00),
        tertiary: Color(0xFFB4234D),
        surface: surface,
        surfaceContainerHighest: surfaceHigh,
        outline: border,
      ),
      textTheme: Typography.blackMountainView.apply(
        bodyColor: const Color(0xFF16202C),
        displayColor: const Color(0xFF101820),
        fontFamily: 'Segoe UI',
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16202C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF16202C),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const background = Color(0xFF050609);
    const surface = Color(0xF20A0D13);
    const surfaceHigh = Color(0xFF10151D);
    const border = Color(0xFF242B36);
    const primary = Color(0xFFC8FFF4);

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
      textTheme: Typography.whiteMountainView
          .apply(
            bodyColor: const Color(0xFFE8EEF8),
            displayColor: const Color(0xFFF8FBFF),
            fontFamily: 'Segoe UI',
          )
          .copyWith(
            headlineLarge: const TextStyle(
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: const TextStyle(
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
            headlineSmall: const TextStyle(
              fontSize: 19,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
            titleLarge: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            titleMedium: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: const TextStyle(fontSize: 14, height: 1.42),
            bodyMedium: const TextStyle(fontSize: 13, height: 1.38),
            bodySmall: const TextStyle(fontSize: 12, height: 1.32),
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
        color: const Color(0xD90A0D13),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x990B0F16),
        hintStyle: const TextStyle(color: Color(0xFF697384)),
        labelStyle: const TextStyle(
          color: Color(0xFF9AA6B8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0x3DFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0x2EFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0x99C8FFF4)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x66101620),
        selectedColor: primary.withValues(alpha: 0.09),
        side: const BorderSide(color: Color(0x24FFFFFF)),
        labelStyle: const TextStyle(
          color: Color(0xFFBFC9D8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE7F7F4),
          foregroundColor: const Color(0xFF05070B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          minimumSize: const Size(0, 38),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDDE6F3),
          side: const BorderSide(color: Color(0x30FFFFFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 38),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(34, 34),
          padding: const EdgeInsets.all(7),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xF20B0F16),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE8EEF8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
