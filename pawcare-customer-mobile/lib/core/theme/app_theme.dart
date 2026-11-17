import 'package:flutter/material.dart';

class AppColors {
  // PawCare luxury design system — vibrant modern oceanic teal, crisp slate, and warm coral
  static const navy = Color(0xFF0F172A); // Slate 900 - ultra crisp, readable text
  static const teal = Color(0xFF0D9488); // Vibrant Oceanic Teal
  static const cyan = Color(0xFF0284C7); // Clear Sky Cyan
  static const mint = Color(0xFFE6F4F1); // Soft Fresh Mint
  static const success = Color(0xFF10B981); // Crisp Emerald
  static const coral = Color(0xFFF43F5E); // Rose Coral
  static const canvas = Color(0xFFF8FAFC); // Clean Canvas
  static const darkCanvas = Color(0xFF0B1120); // Deep Midnight Canvas
  static const darkSurface = Color(0xFF1E293B); // Rich Dark Glass Surface
  static const surface = Color(0xFFFFFFFF); // Pure White
  static const shimmer = Color(0xFFF1F5F9);
}

ThemeData buildTheme({bool dark = false}) {
  final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.success,
      brightness: dark ? Brightness.dark : Brightness.light);
  final surface = dark ? AppColors.darkSurface : Colors.white;
  final onSurface = dark ? const Color(0xFFF8FAFC) : AppColors.navy;
  final outline = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
    appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false),
    textTheme: (dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: TextStyle(
          color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      hintStyle: TextStyle(
          color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.coral)),
    ),
    cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
                color:
                    dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 50),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    dividerTheme: DividerThemeData(
        color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 68,
      indicatorColor: dark ? const Color(0xFF0F766E) : const Color(0xFFCCFBF1),
      indicatorShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          fontSize: 12)),
    ),
  );
}
