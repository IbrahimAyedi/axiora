import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand primaries ──────────────────────────────────────────────────────
  static const primary = Color(0xFF0B2D4D);      // Navy Blue (Axiora brand)
  static const primaryDark = Color(0xFF071D33);
  static const primaryLight = Color(0xFFE7F0FB);
  static const trustBlue = Color(0xFF1769AA);     // Trust Blue
  static const cyanTech = Color(0xFF38BDF8);      // Cyan Tech accent
  static const accent = Color(0xFFFFA24A);        // Amber — constat/warning flow
  static const accentDark = Color(0xFFE07B10);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFE8EEF6);
  static const surfaceElevated = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFFADB8C6);

  // ── Border ───────────────────────────────────────────────────────────────
  static const border = Color(0xFFD8E2EE);
  static const borderFocus = primary;

  // ── Semantic: Info ────────────────────────────────────────────────────────
  static const info = Color(0xFF2F6FED);
  static const infoLight = Color(0xFFE8F0FD);

  // ── Semantic: Success ─────────────────────────────────────────────────────
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFEAF4EA);

  // ── Semantic: Warning ─────────────────────────────────────────────────────
  static const warning = Color(0xFFF9A825);
  static const warningLight = Color(0xFFFFF8E1);

  // ── Semantic: Error ───────────────────────────────────────────────────────
  static const error = Color(0xFFC62828);
  static const errorLight = Color(0xFFFDECEC);

  // ── Overlay helpers ───────────────────────────────────────────────────────
  static const white12 = Color(0x1FFFFFFF);
  static const white20 = Color(0x33FFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const black08 = Color(0x14000000);
}
