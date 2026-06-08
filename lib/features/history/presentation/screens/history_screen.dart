import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/history_item.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(appSessionProvider).historyItems;

    return AppPageScaffold(
      title: 'History',
      subtitle: 'Recent local activity',
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.history_outlined,
              message: 'No activity yet',
              subtitle: 'Your constats and scanned documents will appear here.',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _HistoryCard(
                item: items[index],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual card
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isScan = item.type == HistoryItemType.scan;
    final isConstat = item.type == HistoryItemType.constat;
    final isSubmitted = item.status == 'submitted';

    // Type-specific icon & accent color
    final Color accentColor = isScan ? AppColors.info : AppColors.primary;
    final Color iconBg = isDark
        ? accentColor.withAlpha(40)
        : (isScan ? AppColors.infoLight : AppColors.primaryLight);
    final IconData typeIcon = isScan
        ? Icons.document_scanner_outlined
        : Icons.assignment_outlined;

    // Status badge params
    final String? badgeLabel =
        isConstat ? (isSubmitted ? 'Submitted' : 'Draft') : null;
    final Color badgeBg = isDark
        ? (isSubmitted ? AppColors.success.withAlpha(45) : AppColors.warning.withAlpha(45))
        : (isSubmitted ? AppColors.successLight : AppColors.warningLight);
    final Color badgeFg = isSubmitted ? AppColors.success : AppColors.warning;

    return Material(
      color: isDark ? theme.colorScheme.surface : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isConstat
            ? () => context.push(
                RouteNames.constatDetailPath(item.referenceId),
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? theme.dividerColor : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent strip — stretches to full card height
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Icon container — vertically centered
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(typeIcon, size: 22, color: accentColor),
                  ),
                ),
                const SizedBox(width: 14),

                // Text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Type label + optional status badge
                        Row(
                          children: [
                            Text(
                              _typeLabel(item.type),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (badgeLabel != null) ...[
                              const SizedBox(width: 8),
                              _StatusPill(
                                label: badgeLabel,
                                background: badgeBg,
                                foreground: badgeFg,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Title
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Subtitle
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Chevron for tappable constats
                if (isConstat) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary.withAlpha(140),
                      size: 20,
                    ),
                  ),
                ] else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _typeLabel(HistoryItemType type) {
  return switch (type) {
    HistoryItemType.scan => 'DOCUMENT SCAN',
    HistoryItemType.constat => 'CONSTAT',
  };
}
