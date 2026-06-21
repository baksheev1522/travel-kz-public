import 'package:flutter/material.dart';

abstract class AppColors {
  static const primary = Color(0xFF1A6FE8);
  static const primaryDark = Color(0xFF1459C4);
  static const secondary = Color(0xFFFF6B35);
  static const accent = Color(0xFF00C9A7);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF0D0D0D);
  static const grey50  = Color(0xFFF8F9FA);
  static const grey100 = Color(0xFFF1F3F5);
  static const grey200 = Color(0xFFE9ECEF);
  static const grey300 = Color(0xFFDEE2E6);
  static const grey400 = Color(0xFFCED4DA);
  static const grey500 = Color(0xFFADB5BD);
  static const grey600 = Color(0xFF6C757D);
  static const grey700 = Color(0xFF495057);
  static const grey800 = Color(0xFF343A40);
  static const grey900 = Color(0xFF212529);

  static const success = Color(0xFF28A745);
  static const warning = Color(0xFFFFC107);
  static const error   = Color(0xFFDC3545);

  static const bgLight = Color(0xFFF5F7FA);
}

abstract class AppTextStyles {
  static const String _font = 'Comfortaa';

  static const headlineLarge = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600,
  );
  static const titleLarge = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600,
  );
  static const titleMedium = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400, height: 1.6,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const bodySmall = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400,
  );
  static const labelLarge = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600,
  );
}

abstract class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Comfortaa',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.white,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSurface: AppColors.grey900,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.grey900,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        textStyle: AppTextStyles.labelLarge,
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.grey200,
      thickness: 1,
      space: 0,
    ),
  );
}