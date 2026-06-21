import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _GradientPrimaryButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
        );
      case AppButtonVariant.secondary:
        return _SecondaryButton(label: label, icon: icon, onPressed: onPressed);
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: onPressed,
          child: _ButtonRow(label: label, icon: icon),
        );
    }
  }
}

// ── Gradient primary ─────────────────────────────────────────────────────────

class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [const Color(0xFFB0BEC5), const Color(0xFF90A4AE)]
                : [const Color(0xFF1769AA), const Color(0xFF0B2D4D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: _ButtonRow(label: label, icon: icon),
        ),
      ),
    );
  }
}

// ── Outlined secondary ───────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _ButtonRow(label: label, icon: icon),
    );
  }
}

// ── Shared row ───────────────────────────────────────────────────────────────

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
