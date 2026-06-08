import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  // ── Font family ───────────────────────────────────────────────────────────
  // Uses Inter via `fontFamily` set in AppTheme. All styles here just define
  // the weight/size/height/color — no need to repeat fontFamily per style.

  static const textTheme = TextTheme(
    // ── Display ─────────────────────────────────────────────────────────────
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),

    // ── Headlines ────────────────────────────────────────────────────────────
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.3,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.1,
      color: AppColors.textPrimary,
    ),

    // ── Titles ────────────────────────────────────────────────────────────────
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: 0.0,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.0,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),

    // ── Body ──────────────────────────────────────────────────────────────────
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: 0.0,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: 0.0,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.1,
      color: AppColors.textDisabled,
    ),

    // ── Labels ────────────────────────────────────────────────────────────────
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.15,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.3,
      color: AppColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.5,
      color: AppColors.textSecondary,
    ),
  );
}
