import 'package:flutter/material.dart';

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
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          _ButtonIcon(icon: icon!, variant: variant),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    switch (variant) {
      case AppButtonVariant.secondary:
        return OutlinedButton(onPressed: onPressed, child: child);
      case AppButtonVariant.ghost:
        return TextButton(onPressed: onPressed, child: child);
      case AppButtonVariant.primary:
        return ElevatedButton(onPressed: onPressed, child: child);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon renderer — primary gets a soft backlit container
// ─────────────────────────────────────────────────────────────────────────────

class _ButtonIcon extends StatelessWidget {
  const _ButtonIcon({required this.icon, required this.variant});

  final IconData icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.primary) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 17),
      );
    }
    return Icon(icon, size: 18);
  }
}
