import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.currentStep,
    this.totalSteps,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;

  /// When both are provided, a step progress indicator is shown below the
  /// app bar. [subtitle] becomes the step label shown next to the step count.
  final int? currentStep;
  final int? totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSteps = currentStep != null && totalSteps != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? Builder(
                builder: (ctx) {
                  if (!ctx.canPop()) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    tooltip: 'Retour',
                    onPressed: ctx.pop,
                  );
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (!hasSteps && subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (hasSteps)
              _StepBanner(
                current: currentStep!,
                total: totalSteps!,
                label: subtitle,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step progress banner ─────────────────────────────────────────────────────

class _StepBanner extends StatelessWidget {
  const _StepBanner({
    required this.current,
    required this.total,
    this.label,
  });

  final int current;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented progress bar
          Row(
            children: List.generate(total, (i) {
              final active = i <= current - 1;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: active ? AppColors.trustBlue : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 7),
          // Step label row
          Row(
            children: [
              Text(
                'Étape $current sur $total',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.trustBlue,
                ),
              ),
              if (label != null) ...[
                const Text(
                  ' — ',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
