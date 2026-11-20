import 'package:flutter/material.dart';

/// Palet diambil dari logo AYOSEHAT (navy → hijau, aksen oranye).
class AppColors {
  static const navy = Color(0xFF0F1B2D);
  static const green = Color(0xFF0F7A52);
  static const mint = Color(0xFF3DD598);
  static const orange = Color(0xFFF2711C);
  static const orangeDark = Color(0xFF9A3412);
  static const bg = Color(0xFFF4F3EE);
  static const line = Color(0xFFDCDED6);
  static const muted = Color(0xFF5A6570);
  static const softGreen = Color(0xFFE3F4EA);
  static const softOrange = Color(0xFFFFEBDC);
  static const softGrey = Color(0xFFECEDE8);
  static const red = Color(0xFFB42318);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.orange,
    surface: Colors.white,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: AppColors.navy, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.green, width: 2)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.softGreen,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
    ),
  );
}
