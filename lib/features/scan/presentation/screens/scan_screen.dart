import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPageScaffold(
      title: 'Scan center',
      subtitle: 'OCR and capture flows',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero ────────────────────────────────────────────────────
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3459), Color(0xFF1A5C96)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Vehicle photo capture',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Photo-based OCR preview, image validation, and inspection summary.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Scan mode card ───────────────────────────────────────────
          SectionCard(
            title: 'Available scan modes',
            subtitle: 'Choose the flow you want to start',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScanModeRow(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle scan',
                  subtitle: 'Full inspection capture',
                  onTap: () => context.push(RouteNames.previewPath),
                  primary: true,
                ),
                const SizedBox(height: 8),
                _ScanModeRow(
                  icon: Icons.badge_outlined,
                  title: 'Carte grise scan',
                  subtitle: 'Registration document OCR',
                  onTap: () => context.push(RouteNames.scanCarteGrisePath),
                ),
                const SizedBox(height: 8),
                _ScanModeRow(
                  icon: Icons.credit_card_outlined,
                  title: 'Permis de conduire scan',
                  subtitle: 'Driver license OCR',
                  onTap: () => context.push(RouteNames.scanPermisPath),
                ),
                const SizedBox(height: 8),
                _ScanModeRow(
                  icon: Icons.shield_outlined,
                  title: 'Assurance scan',
                  subtitle: 'Insurance certificate OCR',
                  onTap: () => context.push(RouteNames.scanAssurancePath),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Guidance card ────────────────────────────────────────────
          SectionCard(
            title: 'Tips for best results',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _guidanceTip(theme, Icons.wb_sunny_outlined, 'Good lighting — no shadows'),
                _guidanceTip(theme, Icons.crop_free_outlined, 'Document fully inside the frame'),
                _guidanceTip(theme, Icons.flash_off_outlined, 'Avoid flash reflection'),
                _guidanceTip(theme, Icons.straighten_outlined, 'Keep the document flat'),
                _guidanceTip(theme, Icons.rate_review_outlined, 'Review and correct extracted fields before saving'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanModeRow extends StatelessWidget {
  const _ScanModeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (primary) {
      return AppButton(label: title, icon: icon, onPressed: onTap);
    }

    return Material(
      color: const Color(0xFFF3F6FB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF5C6773)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: const Color(0xFF5C6773).withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _guidanceTip(ThemeData theme, IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall),
        ),
      ],
    ),
  );
}
