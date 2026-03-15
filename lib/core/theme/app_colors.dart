import 'package:flutter/material.dart';

/// Application Color System
/// Supports both light and dark themes with configurable primary color
class AppColors {
  // Light Mode
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF333333);

  // Primary (Brand Color - Configurable)
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textDisabled = Color(0xFFCCCCCC);

  // Text Colors (Dark Mode)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF808080);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
}

/// Extension for getting theme-appropriate colors
extension AppColorsExtension on BuildContext {
  Color get background =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground;

  Color get surface =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface;

  Color get cardColor =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.lightCard;

  Color get borderColor =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.darkBorder
          : AppColors.lightBorder;

  Color get textPrimary =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.darkTextPrimary
          : AppColors.textPrimary;

  Color get textSecondary =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.darkTextSecondary
          : AppColors.textSecondary;
}
