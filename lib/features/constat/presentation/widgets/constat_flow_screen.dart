import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/providers/app_session_provider.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_page_scaffold.dart';

// Reusable intro wrapper for constat flow entry points.
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
    return AppPageScaffold(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1769AA), Color(0xFF0B2D4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B2D4D).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 26, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Checklist card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.checklist_rounded,
                        size: 16,
                        color: AppColors.trustBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ce que vous allez faire',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                ...checklist.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Primary action ────────────────────────────────────────────────
          AppButton(
            label: primaryLabel,
            onPressed: () {
              _applyConstatStep(ref, primaryRoute);
              context.push(primaryRoute);
            },
          ),

          if (secondaryLabel != null && secondaryRoute != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: secondaryLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push(secondaryRoute!),
            ),
          ],
        ],
      ),
    );
  }
}

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
