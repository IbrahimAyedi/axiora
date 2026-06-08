import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../widgets/image_quality_banner.dart';
import '../widgets/ocr_result_card.dart';
import '../widgets/result_summary_card.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  Future<void> _saveLocally(BuildContext context, String summary) async {
    await LocalStorageService.instance.saveString(
      CacheKeys.latestScanSummary,
      summary,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Result saved locally'),
            ],
          ),
          backgroundColor: const Color(0xFF124170),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(appSessionProvider);
    final scan = session.activeScan;
    final vehicle = session.mainVehicleProfile;
    final driver = session.mainDriverProfile;
    final insurance = session.mainInsuranceProfile;
    final extractedData = scan?.extractedData;

    final summary =
        extractedData?['summary'] as String? ??
        scan?.notes ??
        'Scan completed and linked to reusable local profiles.';
    final qualityLabel =
        extractedData?['qualityLabel'] as String? ?? 'Validation complete';
    final qualityScore = _formatQualityScore(scan?.qualityScore);
    final ocrText =
        scan?.ocrRawText ??
        vehicle?.plateNumber ??
        extractedData?['plateNumber'] as String? ??
        'No OCR text available';

    return AppPageScaffold(
      title: 'Inspection result',
      subtitle: 'Scan complete',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFA5D6B0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scan processed successfully - review the results below.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OcrResultCard(text: ocrText),
          const SizedBox(height: 10),
          ImageQualityBanner(
            label: qualityLabel,
            score: qualityScore,
          ),
          const SizedBox(height: 10),
          ResultSummaryCard(summary: summary),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Linked profiles',
            subtitle: 'Created from the completed document scan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle: ${vehicle?.brand ?? '--'} ${vehicle?.model ?? ''} ${vehicle?.plateNumber ?? ''}'
                      .trim(),
                ),
                const SizedBox(height: 8),
                Text('Driver: ${driver?.fullName ?? '--'}'),
                const SizedBox(height: 8),
                Text(
                  'Insurance: ${insurance?.companyName ?? '--'} ${insurance?.insuranceNumber ?? ''}'
                      .trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'AI modules (coming soon)',
            subtitle: 'Placeholders for future integration',
            child: Column(
              children: const [
                _ModulePlaceholder(
                  icon: Icons.car_crash_outlined,
                  label: 'Damage analysis',
                ),
                SizedBox(height: 8),
                _ModulePlaceholder(
                  icon: Icons.shield_outlined,
                  label: 'Fraud risk score',
                ),
                SizedBox(height: 8),
                _ModulePlaceholder(
                  icon: Icons.attach_money_outlined,
                  label: 'Estimated repair cost',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Save locally',
            icon: Icons.save_alt_outlined,
            onPressed: () => _saveLocally(context, summary),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Start new scan',
            variant: AppButtonVariant.secondary,
            icon: Icons.camera_alt_outlined,
            onPressed: () => context.go(RouteNames.scanPath),
          ),
        ],
      ),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  const _ModulePlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5C6773)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0EA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ready',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 11,
                color: const Color(0xFF5C6773),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatQualityScore(double? score) {
  if (score == null) return '--';
  return '${(score * 100).round()}%';
}
