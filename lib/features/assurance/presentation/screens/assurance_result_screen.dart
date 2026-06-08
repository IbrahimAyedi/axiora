import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/ocr_debug_panel.dart';
import '../../../../core/widgets/section_card.dart';

/// Confirmation/edit screen shown after insurance document OCR.
/// The user can correct extracted fields before they are committed to the
/// insurance profile and the active constat draft.
class AssuranceResultScreen extends ConsumerStatefulWidget {
  const AssuranceResultScreen({super.key});

  @override
  ConsumerState<AssuranceResultScreen> createState() =>
      _AssuranceResultScreenState();
}

class _AssuranceResultScreenState extends ConsumerState<AssuranceResultScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _insuranceNumberController;
  late final TextEditingController _companyController;
  late final TextEditingController _policyHolderController;
  late final TextEditingController _policyTypeController;
  late final TextEditingController _validFromController;
  late final TextEditingController _validToController;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appSessionProvider).activeScan?.extractedData;
    _insuranceNumberController = TextEditingController(
      text: data?['insuranceNumber'] as String? ?? '',
    );
    _companyController = TextEditingController(
      text: data?['companyName'] as String? ?? '',
    );
    _policyHolderController = TextEditingController(
      text: data?['policyHolderName'] as String? ?? '',
    );
    _policyTypeController = TextEditingController(
      text: data?['policyType'] as String? ?? '',
    );
    _validFromController = TextEditingController(
      text: data?['validFrom'] as String? ?? '',
    );
    _validToController = TextEditingController(
      text: data?['validTo'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _insuranceNumberController.dispose();
    _companyController.dispose();
    _policyHolderController.dispose();
    _policyTypeController.dispose();
    _validFromController.dispose();
    _validToController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Confidence helpers
  // ---------------------------------------------------------------------------

  double _score(Map<String, dynamic>? d) {
    final v = d?['qualityScore'];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return 0.0;
  }

  String _level(Map<String, dynamic>? d) =>
      d?['confidenceLevel'] as String? ?? 'weak';

  Color _color(String level, BuildContext ctx) => switch (level) {
    'good' => Colors.green,
    'medium' => Colors.orange,
    _ => Theme.of(ctx).colorScheme.error,
  };

  String _levelLabel(String level) => switch (level) {
    'good' => 'Good',
    'medium' => 'Medium',
    _ => 'Weak',
  };

  IconData _levelIcon(String level) => switch (level) {
    'good' => Icons.check_circle_outline,
    'medium' => Icons.info_outline,
    _ => Icons.warning_amber_outlined,
  };

  // ---------------------------------------------------------------------------
  // Save confirmed data into insurance profile
  // ---------------------------------------------------------------------------

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(appSessionProvider.notifier).saveConstatInsuranceDraft(
      insuranceNumber: _insuranceNumberController.text.trim(),
      companyName: _companyController.text.trim(),
      policyHolderName: _policyHolderController.text.trim(),
      policyType: _policyTypeController.text.trim(),
    );

    // Return to insurance info form in the constat flow
    context.go(RouteNames.insuranceInfoPath);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appSessionProvider).activeScan?.extractedData;
    final level = _level(data);
    final score = _score(data);
    final color = _color(level, context);
    final isWeak = level == 'weak';
    final isMedium = level == 'medium';
    final pct = (score * 100).round();

    return AppPageScaffold(
      title: 'Assurance OCR result',
      subtitle: 'Review and correct before saving',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Confidence banner
            _ConfidenceBanner(
              label: _levelLabel(level),
              icon: _levelIcon(level),
              color: color,
              pct: pct,
              score: score,
              qualityLabel: data?['qualityLabel'] as String? ?? '',
            ),
            const SizedBox(height: 12),

            if (isWeak) ...[
              _WeakWarning(onRetake: () => context.pop()),
              const SizedBox(height: 12),
            ],

            if (isMedium && !isWeak) ...[
              _MediumHint(),
              const SizedBox(height: 12),
            ],

            const SectionCard(
              title: 'Extracted fields',
              subtitle: 'Correct anything that looks wrong',
              child: SizedBox.shrink(),
            ),
            const SizedBox(height: 8),

            AppTextInput(
              label: 'Insurance / policy number',
              controller: _insuranceNumberController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                  ? 'Insurance number is required'
                  : null,
            ),
            const SizedBox(height: 12),

            AppTextInput(
              label: 'Insurance company',
              controller: _companyController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                  ? 'Company name is required'
                  : null,
            ),
            const SizedBox(height: 12),

            AppTextInput(
              label: 'Policy holder name',
              controller: _policyHolderController,
            ),
            const SizedBox(height: 12),

            AppTextInput(
              label: 'Usage / policy type',
              controller: _policyTypeController,
              hint: 'e.g. Tous déplacements',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextInput(
                    label: 'Valid from',
                    controller: _validFromController,
                    hint: 'DD/MM/YYYY',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextInput(
                    label: 'Valid to',
                    controller: _validToController,
                    hint: 'DD/MM/YYYY',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            AppButton(
              label: 'Confirm and use in insurance form',
              icon: Icons.check_circle_outline,
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),

            AppButton(
              label: 'Retake photo',
              variant: AppButtonVariant.secondary,
              icon: Icons.camera_alt_outlined,
              onPressed: () => context.pop(),
            ),

            // Debug panel — only visible in kDebugMode builds
            OcrDebugPanel(extractedData: data),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local sub-widgets
// ---------------------------------------------------------------------------

class _ConfidenceBanner extends StatelessWidget {
  const _ConfidenceBanner({
    required this.label,
    required this.icon,
    required this.color,
    required this.pct,
    required this.score,
    required this.qualityLabel,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int pct;
  final double score;
  final String qualityLabel;

  @override
  Widget build(BuildContext context) {
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
          if (qualityLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              qualityLabel,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeakWarning extends StatelessWidget {
  const _WeakWarning({required this.onRetake});
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
            style: TextStyle(
              fontSize: 13,
              color: errorColor.withValues(alpha: 0.85),
            ),
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

class _MediumHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Some fields may be incorrect. Review carefully before confirming.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
