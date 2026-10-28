import 'package:flutter/material.dart';

class AppColors {
  // PawCare design system — calm, accessible cyan + health green.
  static const navy = Color(0xFF123B55);
  static const teal = Color(0xFF0891B2);
  static const cyan = Color(0xFF22D3EE);
  static const mint = Color(0xFFDDF8F4);
  static const success = Color(0xFF059669);
  static const coral = Color(0xFFFF6B3D);
  static const canvas = Color(0xFFF2FAFC);
  static const darkCanvas = Color(0xFF081C24);
  static const darkSurface = Color(0xFF102A34);
}

ThemeData buildTheme({bool dark = false}) {
  final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.success,
      brightness: dark ? Brightness.dark : Brightness.light);
  final surface = dark ? AppColors.darkSurface : Colors.white;
  final onSurface = dark ? const Color(0xFFF0FBFD) : AppColors.navy;
  final outline = dark ? const Color(0xFF31515C) : const Color(0xFFC8DEE4);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: 'Avenir Next',
    scaffoldBackgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
    appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false),
    textTheme: Typography.material2021().black.apply(
          bodyColor: onSurface,
          displayColor: onSurface,
          fontFamily: 'Avenir Next',
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      labelStyle: TextStyle(
          color: dark ? const Color(0xFFC6DFE5) : const Color(0xFF466571)),
      hintStyle: TextStyle(
          color: dark ? const Color(0xFF9CBAC3) : const Color(0xFF6B8791)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.teal, width: 2.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDC4C45))),
    ),
    cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color:
                    dark ? const Color(0xFF26434D) : const Color(0xFFE0EFF2)))),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // A finite width is required because this shared style is also used
        // by buttons inside Rows (for example, the booking wizard actions).
        // Size.fromHeight creates an infinite minimum width and triggers a
        // RenderBox layout exception on iOS.
        minimumSize: const Size(64, 52),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    dividerTheme: DividerThemeData(
        color: dark ? const Color(0xFF294650) : const Color(0xFFDCECEF)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 72,
      indicatorColor: dark ? const Color(0xFF174B59) : const Color(0xFFC8F1F5),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          fontSize: 12)),
    ),
  );
}
