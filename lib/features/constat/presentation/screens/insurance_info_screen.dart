import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/models/ocr_result.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/providers/ocr_provider.dart';
import '../../../../core/services/ocr_text_cleaner.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/insurance_number_update_dialog.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 insurance information
// fih Party A assurance w Party B assurance, w ينجم يعمل OCR scan lel assurance
class InsuranceInfoScreen extends ConsumerStatefulWidget {
  const InsuranceInfoScreen({super.key});

  @override
  ConsumerState<InsuranceInfoScreen> createState() =>
      _InsuranceInfoScreenState();
}

class _InsuranceInfoScreenState extends ConsumerState<InsuranceInfoScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // image picker bech na5dhou assurance image men camera wala gallery
  final ImagePicker _imagePicker = ImagePicker();

  // Party A — my own insurance
  // controllers mte3 assurance mte3 current user
  late final TextEditingController _insuranceNumberController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _policyHolderNameController;
  late final TextEditingController _policyTypeController;

  // true waqt OCR mte3 Party A yekhdem
  bool _isScanningPartyA = false;

  // Party B target — other party insurance
  // controllers mte3 assurance mte3 other party
  late final TextEditingController _partyBInsuranceNumberController;
  late final TextEditingController _partyBCompanyNameController;
  late final TextEditingController _partyBPolicyHolderNameController;
  late final TextEditingController _partyBPolicyTypeController;

  // true waqt OCR mte3 Party B yekhdem
  bool _isScanningPartyB = false;

  @override
  void initState() {
    super.initState();

    // njibou session data
    final session = ref.read(appSessionProvider);

    // assurance profile mte3 current user
    final profile = session.mainInsuranceProfile;

    // active constat
    final constat = session.activeConstat;

    // Party A: prefer partyAInsuranceSnapshot, fallback insuranceSnapshot, fallback profile
    // n3abbiw fields mte3 Party A mel draft, sinon mel profile
    final partyASnap =
        constat?.partyAInsuranceSnapshot ?? constat?.insuranceSnapshot;
    _insuranceNumberController = TextEditingController(
      text:
          partyASnap?['insuranceNumber'] as String? ??
          profile?.insuranceNumber ??
          '',
    );
    _companyNameController = TextEditingController(
      text: partyASnap?['companyName'] as String? ?? profile?.companyName ?? '',
    );
    _policyHolderNameController = TextEditingController(
      text:
          partyASnap?['policyHolderName'] as String? ??
          profile?.policyHolderName ??
          '',
    );
    _policyTypeController = TextEditingController(
      text: partyASnap?['policyType'] as String? ?? profile?.policyType ?? '',
    );

    // Party B: from partyBTargetInsuranceSnapshot if already filled
    // n3abbiw fields mte3 Party B ken deja mawjoudin fil draft
    final partyBSnap = constat?.partyBTargetInsuranceSnapshot;
    _partyBInsuranceNumberController = TextEditingController(
      text: partyBSnap?['insuranceNumber'] as String? ?? '',
    );
    _partyBCompanyNameController = TextEditingController(
      text: partyBSnap?['companyName'] as String? ?? '',
    );
    _partyBPolicyHolderNameController = TextEditingController(
      text: partyBSnap?['policyHolderName'] as String? ?? '',
    );
    _partyBPolicyTypeController = TextEditingController(
      text: partyBSnap?['policyType'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _insuranceNumberController.dispose();
    _companyNameController.dispose();
    _policyHolderNameController.dispose();
    _policyTypeController.dispose();
    _partyBInsuranceNumberController.dispose();
    _partyBCompanyNameController.dispose();
    _partyBPolicyHolderNameController.dispose();
    _partyBPolicyTypeController.dispose();
    super.dispose();
  }

  // tsajel assurance info w temchi lel photos/damage step
  void _continueToPhotos() {
    // nvalidiw form
    if (!_formKey.currentState!.validate()) return;

    // nsajlou Party A w Party B assurance data fi active constat
    ref
        .read(appSessionProvider.notifier)
        .saveConstatInsuranceDraft(
          insuranceNumber: _insuranceNumberController.text.trim(),
          companyName: _companyNameController.text.trim(),
          policyHolderName: _policyHolderNameController.text.trim(),
          policyType: _policyTypeController.text.trim(),
          partyBInsuranceNumber: _partyBInsuranceNumberController.text.trim(),
          partyBCompanyName: _partyBCompanyNameController.text.trim(),
          partyBPolicyHolderName: _partyBPolicyHolderNameController.text.trim(),
          partyBPolicyType: _partyBPolicyTypeController.text.trim(),
        );

    // nemchiw lel photos and damage screen
    context.push(RouteNames.photosDamagePath);
  }

  // ── Scan helpers ────────────────────────────────────────────────────────────

  // t5alli user ya5tar camera wala gallery
  Future<void> _chooseImageSource({required bool isPartyA}) async {
    // nsakrou keyboard ken mawjoud
    FocusScope.of(context).unfocus();

    // n7ellou bottom sheet mte3 image source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const _AssuranceSourceSheet(),
    );

    // ken user cancel, nوقفou
    if (!mounted || source == null) return;

    // nebdew scan assurance
    await _scanAssurance(source, isPartyA: isPartyA);
  }

  // ta3mel OCR scan lel assurance image
  Future<void> _scanAssurance(
    ImageSource source, {
    required bool isPartyA,
  }) async {
    // nمنعو double scan
    if (isPartyA && _isScanningPartyA) return;
    if (!isPartyA && _isScanningPartyB) return;

    // njibou OCR service
    final ocrService = ref.read(ocrServiceProvider);

    // nbadlou scanning state حسب Party A wala Party B
    setState(() {
      if (isPartyA) {
        _isScanningPartyA = true;
      } else {
        _isScanningPartyB = true;
      }
    });

    try {
      // na5dhou image men camera wala gallery
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted) return;

      // ken user cancel image picker
      if (pickedFile == null) {
        setState(() {
          if (isPartyA) {
            _isScanningPartyA = false;
          } else {
            _isScanningPartyB = false;
          }
        });
        return;
      }

      // ML Kit ya9ra text men assurance image
      final rawOcrResult = await ocrService.recognizeFromFile(
        File(pickedFile.path),
      );

      // clean OCR text before parsing (fixes common character errors)
      final ocrResult = OcrTextCleaner.clean(rawOcrResult);

      // nparsew cleaned OCR result l InsuranceDocumentData
      final insuranceData = ocrService.parseInsuranceDocument(ocrResult);
      if (!mounted) return;

      // ncheckiw ken OCR l9a assurance info
      final hasInfo =
          _hasText(insuranceData.insuranceNumber) ||
          _hasText(insuranceData.companyName) ||
          _hasText(insuranceData.policyHolderName) ||
          _hasText(insuranceData.policyType);

      if (isPartyA) {
        // n3abbiw fields mte3 Party A
        _applyToPartyA(insuranceData);

        // Only offer profile update for Party A
        // ken scan jey men assurance mte3i, n9ترحو update profile insurance number
        if (_hasText(insuranceData.insuranceNumber)) {
          await _maybePromptProfileInsuranceUpdate(
            insuranceData.insuranceNumber!,
          );
        }
      } else {
        // n3abbiw fields mte3 Party B
        _applyToPartyB(insuranceData);

        // Never offer profile update for other party assurance
      }

      // message حسب result w confidence
      final message = hasInfo
          ? insuranceData.confidence >= 0.75
                ? 'Assurance scanned successfully'
                : 'Assurance scanned partially. Please verify missing fields.'
          : 'OCR completed, but no insurance information was detected.';

      // nwarriw feedback lel user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      // ken OCR scan tfشل
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan assurance. Please try again.'),
        ),
      );
    } finally {
      // nرجعou scanning false
      if (mounted) {
        setState(() {
          if (isPartyA) {
            _isScanningPartyA = false;
          } else {
            _isScanningPartyB = false;
          }
        });
      }
    }
  }

  // t3abbi Party A fields b data extracted mel assurance
  void _applyToPartyA(InsuranceDocumentData data) {
    _fill(_insuranceNumberController, data.insuranceNumber);
    _fill(_companyNameController, data.companyName);
    _fill(_policyHolderNameController, data.policyHolderName);
    _fill(_policyTypeController, data.policyType);
  }

  // t3abbi Party B fields b data extracted mel assurance
  void _applyToPartyB(InsuranceDocumentData data) {
    _fill(_partyBInsuranceNumberController, data.insuranceNumber);
    _fill(_partyBCompanyNameController, data.companyName);
    _fill(_partyBPolicyHolderNameController, data.policyHolderName);
    _fill(_partyBPolicyTypeController, data.policyType);
  }

  // t3abbi controller ken value mahech fergha
  bool _fill(TextEditingController c, String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return false;
    c.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
    return true;
  }

  // true ken string mahech null w mahech fergha
  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;

  // t9ترح update profile insurance number ken scanned number يختلف
  Future<void> _maybePromptProfileInsuranceUpdate(String scannedNumber) async {
    final session = ref.read(appSessionProvider);

    // insurance number actuel fil profile
    final current = session.currentUser.insuranceNumber;

    // scanned number men OCR
    final trimmed = scannedNumber.trim();

    // ken profile ma fihouch insurance number, n9ترحو save
    if (current == null || current.isEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => InsuranceNumberUpdateDialog(
          currentInsuranceNumber: null,
          scannedInsuranceNumber: trimmed,
        ),
      );
      if (ok == true && mounted) await _updateProfileInsuranceNumber(trimmed);
      return;
    }

    // ken number kif kif, nwarriw message
    if (current == trimmed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insurance number matches your profile.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // ken number different, n9ترحو update
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => InsuranceNumberUpdateDialog(
        currentInsuranceNumber: current,
        scannedInsuranceNumber: trimmed,
      ),
    );
    if (ok == true && mounted) await _updateProfileInsuranceNumber(trimmed);
  }

  // tupdate insurance number fi profile w insurance_users lookup
  Future<void> _updateProfileInsuranceNumber(String number) async {
    try {
      final ok = await ref
          .read(appSessionProvider.notifier)
          .updateProfileInsuranceNumber(number);
      if (!mounted) return;

      // feedback lel user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Profile insurance number updated successfully.'
                : 'Insurance number already registered.',
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    } catch (_) {
      // error message ken update profile tfشل
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken app fi dark mode
    final isDark = theme.brightness == Brightness.dark;

    return AppPageScaffold(
      // title mte3 page
      title: 'Insurance information',

      // subtitle mte3 page
      subtitle: 'Step 4 of 8',

      // body mte3 page
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: My insurance ──────────────────────────────────
            // section mte3 assurance Party A
            _InsuranceSectionCard(
              icon: Icons.shield_outlined,
              title: 'My insurance information',
              subtitle: 'Scan or enter your own insurance details.',
              accentColor: const Color(0xFF1565C0),
              isDark: isDark,
              theme: theme,
              isScanning: _isScanningPartyA,
              scanLabel: 'Scan my assurance',
              onScan: () => _chooseImageSource(isPartyA: true),
              child: Column(
                children: [
                  // insurance number Party A
                  AppTextInput(
                    label: 'Insurance number',
                    controller: _insuranceNumberController,
                    validator: (v) =>
                        Validators.requiredField(v, label: 'Insurance number'),
                  ),
                  const SizedBox(height: 14),

                  // company name Party A
                  AppTextInput(
                    label: 'Company name',
                    controller: _companyNameController,
                    validator: (v) =>
                        Validators.requiredField(v, label: 'Company name'),
                  ),
                  const SizedBox(height: 14),

                  // policy holder Party A
                  AppTextInput(
                    label: 'Policy holder name',
                    controller: _policyHolderNameController,
                  ),
                  const SizedBox(height: 14),

                  // policy type Party A
                  AppTextInput(
                    label: 'Policy type',
                    controller: _policyTypeController,
                    hint: 'Optional',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 2: Other party insurance ────────────────────────
            // section mte3 assurance Party B
            _InsuranceSectionCard(
              icon: Icons.person_search_outlined,
              title: 'Other party insurance',
              subtitle:
                  'Used to identify the second party and send the approval request.',
              accentColor: const Color(0xFF2E7D32),
              isDark: isDark,
              theme: theme,
              isScanning: _isScanningPartyB,
              scanLabel: 'Scan other party assurance',
              onScan: () => _chooseImageSource(isPartyA: false),
              infoNote:
                  'Leave empty if the other party is unknown — no approval request will be created.',
              child: Column(
                children: [
                  // insurance number Party B
                  AppTextInput(
                    label: 'Insurance number',
                    controller: _partyBInsuranceNumberController,
                    hint: 'Optional',
                  ),
                  const SizedBox(height: 14),

                  // company name Party B
                  AppTextInput(
                    label: 'Company name',
                    controller: _partyBCompanyNameController,
                    hint: 'Optional',
                  ),
                  const SizedBox(height: 14),

                  // policy holder Party B
                  AppTextInput(
                    label: 'Policy holder name',
                    controller: _partyBPolicyHolderNameController,
                    hint: 'Optional',
                  ),
                  const SizedBox(height: 14),

                  // policy type Party B
                  AppTextInput(
                    label: 'Policy type',
                    controller: _partyBPolicyTypeController,
                    hint: 'Optional',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Next action ──────────────────────────────────────────────
            // section mte3 next action
            SectionCard(
              title: 'Next action',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // save assurance info w continue
                  AppButton(
                    label: 'Continue to photos and damage',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _continueToPhotos,
                  ),
                  const SizedBox(height: 12),

                  // back lel vehicle details
                  AppButton(
                    label: 'Back to vehicle details',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(RouteNames.vehicleInfoPath),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable insurance section card
// ---------------------------------------------------------------------------

// widget reusable ywarri section assurance b header, scan button w inputs
class _InsuranceSectionCard extends StatelessWidget {
  const _InsuranceSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.theme,
    required this.isScanning,
    required this.scanLabel,
    required this.onScan,
    required this.child,
    this.infoNote,
  });

  // icon mte3 section
  final IconData icon;

  // title mte3 section
  final String title;

  // subtitle mte3 section
  final String subtitle;

  // couleur principale mte3 section
  final Color accentColor;

  // true ken dark mode
  final bool isDark;

  // theme mte3 app
  final ThemeData theme;

  // true waqt OCR scan yekhdem
  final bool isScanning;

  // label mte3 scan button
  final String scanLabel;

  // action mte3 scan button
  final VoidCallback onScan;

  // content mte3 section
  final Widget child;

  // note optionnelle
  final String? infoNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration mte3 card
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            // header fih icon, title w subtitle
            Row(
              children: [
                // icon container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),

                // title w subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // subtitle
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Scan button
            // button ybda OCR scan
            AppButton(
              label: isScanning ? 'Scanning...' : scanLabel,
              icon: Icons.document_scanner_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: isScanning ? null : onScan,
            ),

            // loading indicator waqt scan
            if (isScanning) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                color: accentColor,
                backgroundColor: accentColor.withValues(
                  alpha: isDark ? 0.2 : 0.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Processing assurance image...',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 14),

            // inputs/content mte3 section
            child,

            // info note ken mawjoud
            if (infoNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    // info icon
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),

                    // info text
                    Expanded(
                      child: Text(
                        infoNote!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image source bottom sheet
// ---------------------------------------------------------------------------

// bottom sheet bech user ya5tar camera wala gallery lel assurance image
class _AssuranceSourceSheet extends StatelessWidget {
  const _AssuranceSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // camera option
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),

            // gallery option
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
