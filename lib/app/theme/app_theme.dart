import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
// classe feha theme global mte3 application
// houni nconfiguriw light theme, dark theme w style mte3 widgets

abstract final class AppTheme {
  // ── Shared shape radii ────────────────────────────────────────────────────
  static const _radiusCard = 20.0;
  static const _radiusInput = 14.0;
  static const _radiusButton = 14.0;
  static const _radiusChip = 999.0;

  // ── Shared elevation shadow (light) ──────────────────────────────────────
  static final _cardShadow = BoxShadow(
    color: AppColors.primary.withAlpha(18),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  // ── Light theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      outlineVariant: AppColors.border,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTextStyles.textTheme,

      // ── System UI overlay ─────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: AppColors.border,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        iconTheme: IconThemeData(color: AppColors.primary, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.0,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        shadowColor: AppColors.primary,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textDisabled,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      ),

      // ── Elevated button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceAlt,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusButton),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusButton),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── List tiles (used in Settings) ─────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        minLeadingWidth: 0,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusChip),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: AppColors.primaryLight,
      ),

      // ── Snack bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 4,
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Dark theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: const Color(0xFF4E9BD4),
      secondary: AppColors.accent,
      surface: const Color(0xFF1A2332),
      onSurface: Colors.white,
      error: const Color(0xFFEF5350),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF111820),
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF111820),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2C3D),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: const BorderSide(color: Color(0xFF2D3E52)),
        ),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF5C6773);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4E9BD4);
          }
          return const Color(0xFF2D3E52);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerColor: const Color(0xFF2D3E52),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF4E9BD4),
      ),
    );
  }

  // ── Reusable decoration helpers ───────────────────────────────────────────

  /// Standard card-like BoxDecoration (when you can't use Card widget).
  static BoxDecoration get surfaceDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(_radiusCard),
    border: Border.all(color: AppColors.border),
    boxShadow: [_cardShadow],
  );

  /// Subtle info-tinted surface (for instruction panels, tips, etc.).
  static BoxDecoration get infoDecoration => BoxDecoration(
    color: AppColors.infoLight,
    borderRadius: BorderRadius.circular(_radiusCard),
    border: Border.all(color: AppColors.info.withAlpha(40)),
  );

  /// Success-tinted surface (for confirmation banners, etc.).
  static BoxDecoration get successDecoration => BoxDecoration(
    color: AppColors.successLight,
    borderRadius: BorderRadius.circular(_radiusCard),
    border: Border.all(color: AppColors.success.withAlpha(50)),
  );

  /// Warning-tinted surface.
  static BoxDecoration get warningDecoration => BoxDecoration(
    color: AppColors.warningLight,
    borderRadius: BorderRadius.circular(_radiusCard),
    border: Border.all(color: AppColors.warning.withAlpha(60)),
  );

  /// Error-tinted surface.
  static BoxDecoration get errorDecoration => BoxDecoration(
    color: AppColors.errorLight,
    borderRadius: BorderRadius.circular(_radiusCard),
    border: Border.all(color: AppColors.error.withAlpha(50)),
  );

  /// Deep primary gradient (hero cards, splash, etc.).
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF0F3459), Color(0xFF1A5C96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warm amber gradient (Constat / report flow).
  static const warmGradient = LinearGradient(
    colors: [Color(0xFFFFF5EA), Color(0xFFFFFCF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Neutral light gradient (login background, etc.).
  static const softGradient = LinearGradient(
    colors: [Color(0xFFEBF2FA), Color(0xFFF8FAFD), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 1.0],
  );
}
