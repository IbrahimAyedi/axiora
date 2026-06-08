import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/ocr_debug_panel.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 OCR result preview lel carte grise
// ywarri data eli t9rat mel OCR, ywarri confidence level,
// w y5alli user ysalla7ha wala yretake photo 9bal autofill
class CarteGriseResultScreen extends ConsumerStatefulWidget {
  const CarteGriseResultScreen({super.key});

  @override
  ConsumerState<CarteGriseResultScreen> createState() =>
      _CarteGriseResultScreenState();
}

class _CarteGriseResultScreenState
    extends ConsumerState<CarteGriseResultScreen> {
  final _formKey = GlobalKey<FormState>();

  final _plateController = TextEditingController();
  final _ownerController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _vinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final scanData = ref.read(appSessionProvider).activeScan?.extractedData;
    _plateController.text = scanData?['plateNumber'] as String? ?? '';
    _ownerController.text = scanData?['ownerName'] as String? ?? '';
    _brandController.text = scanData?['brand'] as String? ?? '';
    _modelController.text = scanData?['model'] as String? ?? '';
    _vinController.text = scanData?['vin'] as String? ?? '';
  }

  @override
  void dispose() {
    _plateController.dispose();
    _ownerController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    ref
        .read(appSessionProvider.notifier)
        .updateCarteGriseDraft(
          plateNumber: _plateController.text.trim(),
          ownerName: _ownerController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          vin: _vinController.text.trim(),
        );
  }

  // ---------------------------------------------------------------------------
  // Confidence helpers
  // ---------------------------------------------------------------------------

  String _confidenceLevel(Map<String, dynamic>? data) =>
      data?['confidenceLevel'] as String? ?? 'weak';

  double _confidenceScore(Map<String, dynamic>? data) {
    final v = data?['qualityScore'];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return 0.0;
  }

  Color _confidenceColor(String level, BuildContext context) {
    return switch (level) {
      'good' => Colors.green,
      'medium' => Colors.orange,
      _ => Theme.of(context).colorScheme.error,
    };
  }

  String _confidenceLabel(String level) => switch (level) {
    'good' => 'Good',
    'medium' => 'Medium',
    _ => 'Weak',
  };

  IconData _confidenceIcon(String level) => switch (level) {
    'good' => Icons.check_circle_outline,
    'medium' => Icons.info_outline,
    _ => Icons.warning_amber_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final activeScan = ref.watch(appSessionProvider).activeScan;
    final extractedData = activeScan?.extractedData;
    final qualityLabel =
        extractedData?['qualityLabel'] as String? ?? 'Document recognized';
    final level = _confidenceLevel(extractedData);
    final score = _confidenceScore(extractedData);
    final isWeak = level == 'weak';
    final isMedium = level == 'medium';
    final confidenceColor = _confidenceColor(level, context);

    return AppPageScaffold(
      title: 'OCR result preview',
      subtitle: 'Step 2 of 3 — review before autofill',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----------------------------------------------------------------
            // Confidence banner
            // ----------------------------------------------------------------
            _ConfidenceBanner(
              label: _confidenceLabel(level),
              icon: _confidenceIcon(level),
              color: confidenceColor,
              score: score,
              qualityLabel: qualityLabel,
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Weak OCR warning
            // ----------------------------------------------------------------
            if (isWeak) ...[
              _WeakOcrWarning(onRetake: () => context.pop()),
              const SizedBox(height: 12),
            ],

            // ----------------------------------------------------------------
            // Medium OCR hint
            // ----------------------------------------------------------------
            if (isMedium && !isWeak) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some fields may be incorrect. Review carefully before continuing.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ----------------------------------------------------------------
            // Photo guidance card
            // ----------------------------------------------------------------
            const SectionCard(
              title: 'Tips for a better scan',
              child: _PhotoGuidance(),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // Editable extracted fields
            // ----------------------------------------------------------------
            const SectionCard(
              title: 'Extracted fields',
              subtitle: 'Correct anything that looks wrong',
              child: SizedBox.shrink(),
            ),
            const SizedBox(height: 8),

            AppTextInput(
              label: 'Plate number',
              controller: _plateController,
              validator: (v) => Validators.requiredField(v, label: 'Plate number'),
            ),
            const SizedBox(height: 12),

            AppTextInput(
              label: 'Owner name',
              controller: _ownerController,
              validator: (v) => Validators.requiredField(v, label: 'Owner name'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextInput(
                    label: 'Brand',
                    controller: _brandController,
                    validator: (v) => Validators.requiredField(v, label: 'Brand'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextInput(
                    label: 'Model',
                    controller: _modelController,
                    validator: (v) => Validators.requiredField(v, label: 'Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppTextInput(
              label: 'VIN',
              controller: _vinController,
              validator: (v) => Validators.requiredField(v, label: 'VIN'),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // Actions
            // ----------------------------------------------------------------
            AppButton(
              label: 'Continue to autofill form',
              icon: Icons.check_circle_outline,
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                _syncDraft();
                context.push(RouteNames.carteGriseAutofillPath);
              },
            ),
            const SizedBox(height: 12),

            AppButton(
              label: 'Retake photo',
              variant: AppButtonVariant.secondary,
              icon: Icons.camera_alt_outlined,
              onPressed: () => context.pop(),
            ),

            // Debug panel — only visible in kDebugMode builds
            OcrDebugPanel(extractedData: extractedData),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ConfidenceBanner extends StatelessWidget {
  const _ConfidenceBanner({
    required this.label,
    required this.icon,
    required this.color,
    required this.score,
    required this.qualityLabel,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double score;
  final String qualityLabel;

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'OCR confidence: $label ($pct%)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            qualityLabel,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _WeakOcrWarning extends StatelessWidget {
  const _WeakOcrWarning({required this.onRetake});

  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.07),
        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: errorColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Low OCR confidence',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Very few fields were detected. Please:\n'
            '• Retake the photo in better lighting\n'
            '• Keep the document flat and avoid reflections\n'
            '• Or fill in the fields manually below',
            style: TextStyle(fontSize: 13, color: errorColor.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Retake photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: BorderSide(color: errorColor.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGuidance extends StatelessWidget {
  const _PhotoGuidance();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (Icons.wb_sunny_outlined, 'Good lighting — avoid shadows'),
      (Icons.straighten_outlined, 'Keep the document flat on a surface'),
      (Icons.flash_off_outlined, 'Avoid camera flash reflection'),
      (Icons.crop_free_outlined, 'Place the document inside the camera frame'),
      (Icons.front_hand_outlined, 'Hold the camera still when shooting'),
    ];
    return Column(
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(tip.$1, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip.$2, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
