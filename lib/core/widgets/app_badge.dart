import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

// widget sghir yaffichi label fi badge
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.surfaceAlt,
    this.foregroundColor = AppColors.textPrimary,
  });

  // text eli bech yban fi badge
  final String label;

  // couleur mte3 background
  final Color backgroundColor;

  // couleur mte3 text
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding dakhel badge
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      // decoration mte3 badge: couleur + rounded corners
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),

      // label mte3 badge
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
            ),
      ),
    );
  }
}