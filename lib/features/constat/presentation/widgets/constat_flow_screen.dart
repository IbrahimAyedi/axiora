import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/providers/app_session_provider.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_page_scaffold.dart';
import '../../../../../core/widgets/section_card.dart';

// widget reusable mte3 constat flow screens
// ywarri hero section, checklist w next action button
class ConstatFlowScreen extends ConsumerWidget {
  const ConstatFlowScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
    required this.checklist,
    required this.primaryLabel,
    required this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
    this.showBackButton = true,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final String description;
  final List<String> checklist;
  final String primaryLabel;
  final String primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return AppPageScaffold(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withAlpha(200),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFF0F4FF), Color(0xFFF8FAFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? theme.dividerColor : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in a soft rounded container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withAlpha(isDark ? 35 : 22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 28, color: effectiveIconColor),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Checklist ─────────────────────────────────────────────────────
          SectionCard(
            title: 'Checklist',
            subtitle: 'Keep the draft moving with the essentials below',
            icon: Icons.checklist_outlined,
            iconColor: AppColors.primary,
            child: Column(
              children: checklist
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Next action ───────────────────────────────────────────────────
          SectionCard(
            title: 'Next action',
            icon: Icons.arrow_forward_outlined,
            iconColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: primaryLabel,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    _applyConstatStep(ref, primaryRoute);
                    context.push(primaryRoute);
                  },
                ),
                if (secondaryLabel != null && secondaryRoute != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: secondaryLabel!,
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(secondaryRoute!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// tupdate session/draft حسب route eli user mechi leha
void _applyConstatStep(WidgetRef ref, String route) {
  final notifier = ref.read(appSessionProvider.notifier);

  switch (route) {
    case RouteNames.accidentInfoPath:
      notifier.startDraftConstat();
      break;
    case RouteNames.driverInfoPath:
      notifier.updateAccidentStep();
      break;
    case RouteNames.vehicleInfoPath:
      notifier.updateDriverStep();
      break;
    case RouteNames.photosDamagePath:
      notifier.updateVehicleStep();
      break;
    case RouteNames.constatReviewPath:
      notifier.updateDamageStep();
      break;
    case RouteNames.constatSuccessPath:
      notifier.submitConstat();
      break;
    default:
      break;
  }
}

// trajja3 previous route حسب current route mte3 constat flow
String? previousConstatRoute(String route) {
  switch (route) {
    case RouteNames.accidentInfoPath:
      return RouteNames.constatIntroPath;
    case RouteNames.driverInfoPath:
      return RouteNames.accidentInfoPath;
    case RouteNames.vehicleInfoPath:
      return RouteNames.driverInfoPath;
    case RouteNames.photosDamagePath:
      return RouteNames.vehicleInfoPath;
    case RouteNames.constatReviewPath:
      return RouteNames.photosDamagePath;
    case RouteNames.constatSignaturePath:
      return RouteNames.constatReviewPath;
    case RouteNames.constatSuccessPath:
      return RouteNames.constatSignaturePath;
    default:
      return null;
  }
}
