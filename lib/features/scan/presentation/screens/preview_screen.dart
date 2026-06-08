import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../widgets/image_quality_banner.dart';
import '../widgets/ocr_result_card.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appSessionProvider.notifier).startVehicleScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeScan = ref.watch(appSessionProvider).activeScan;
    final previewText = activeScan?.ocrRawText ?? 'Capture ready';
    final qualityLabel =
        activeScan?.extractedData?['qualityLabel'] as String? ??
        'Preview queued';
    final qualityScore = _formatQualityScore(activeScan?.qualityScore);

    return AppPageScaffold(
      title: 'Preview capture',
      subtitle: 'Review before processing',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD7E0EA)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD7E0EA)),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: Color(0xFF5C6773),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Captured vehicle image',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF5C6773),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeScan == null
                      ? 'Preparing document scan session'
                      : 'Scan ${activeScan.status.value} for ${activeScan.scanType.value}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OcrResultCard(text: previewText),
          const SizedBox(height: 10),
          ImageQualityBanner(
            label: qualityLabel,
            score: qualityScore,
          ),
          const SizedBox(height: 12),
          Text(
            'This preview step helps confirm readability before sending to the OCR pipeline.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Continue to processing',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.push(RouteNames.processingPath),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Retake',
            variant: AppButtonVariant.secondary,
            icon: Icons.camera_alt_outlined,
            onPressed: () => context.pop(),
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
