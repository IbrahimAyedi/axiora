import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

// widget reusable mte3 step header
// nesta3mlouh fi workflow eli fih steps kif constat creation
class AppStepHeader extends StatelessWidget {
  const AppStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  // step actuelle
  final int step;

  // nombre total mte3 steps
  final int totalSteps;

  // title mte3 step
  final String title;

  // description sghira mte3 step
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // n7sbou progress bin 0 w 1
    final progress = step / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // text ywarri user win wsel fil workflow
        Text(
          'Step $step of $totalSteps',
          style: Theme.of(context).textTheme.labelMedium,
        ),

        const SizedBox(height: 8),

        // progress bar mte3 steps
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceAlt,
          ),
        ),

        const SizedBox(height: 16),

        // title principal mte3 step
        Text(title, style: Theme.of(context).textTheme.headlineSmall),

        const SizedBox(height: 8),

        // subtitle/description mte3 step
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}