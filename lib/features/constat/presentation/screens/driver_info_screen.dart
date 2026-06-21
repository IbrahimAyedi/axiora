import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/ocr_result.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/providers/ocr_provider.dart';
import '../../../../core/services/ocr_text_cleaner.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 driver information
// user y3abi driver info w ينجم yscan permis b OCR
class DriverInfoScreen extends ConsumerStatefulWidget {
  const DriverInfoScreen({super.key});

  @override
  ConsumerState<DriverInfoScreen> createState() => _DriverInfoScreenState();
}

class _DriverInfoScreenState extends ConsumerState<DriverInfoScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // image picker bech na5dhou permis men camera wala gallery
  final ImagePicker _imagePicker = ImagePicker();

  // controllers mte3 driver fields
  late final TextEditingController _fullNameController;
  late final TextEditingController _licenseNumberController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _phoneNumberController;

  // true waqt OCR permis yekhdem
  bool _isScanningPermis = false;

  @override
  void initState() {
    super.initState();

    // njibou session data
    final session = ref.read(appSessionProvider);

    // profile conducteur principal
    final profile = session.mainDriverProfile;

    // snapshot saved fi active constat ken mawjoud
    final snapshot = session.activeConstat?.driverSnapshot;

    // n3abbiw full name men snapshot, profile wala current user
    _fullNameController = TextEditingController(
      text:
          snapshot?['fullName'] as String? ??
          profile?.fullName ??
          session.currentUser.fullName ??
          '',
    );

    // n3abbiw license number
    _licenseNumberController = TextEditingController(
      text:
          snapshot?['licenseNumber'] as String? ?? profile?.licenseNumber ?? '',
    );

    // n3abbiw national id
    _nationalIdController = TextEditingController(
      text: snapshot?['nationalId'] as String? ?? profile?.nationalId ?? '',
    );

    // n3abbiw phone number
    _phoneNumberController = TextEditingController(
      text:
          snapshot?['phoneNumber'] as String? ??
          profile?.phoneNumber ??
          session.currentUser.phoneNumber ??
          '',
    );
  }

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _fullNameController.dispose();
    _licenseNumberController.dispose();
    _nationalIdController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // tsajel driver draft w temchi lel vehicle step
  void _continueToVehicle() {
    // nvalidiw form 9bal ma nkamlou
    if (!_formKey.currentState!.validate()) return;

    // nsajlou driver info fi active constat/session
    ref
        .read(appSessionProvider.notifier)
        .saveConstatDriverDraft(
          fullName: _fullNameController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
        );

    // nemchiw lel vehicle info screen
    context.push(RouteNames.vehicleInfoPath);
  }

  // t7el bottom sheet bech user ya5tar camera wala gallery
  Future<void> _choosePermisImageSource() async {
    // nsakrou keyboard ken mawjoud
    FocusScope.of(context).unfocus();

    // nwarriw source sheet
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const _PermisSourceSheet(),
    );

    // ken user cancel, nوقفou
    if (!mounted || source == null) return;

    // nebdew scan permis
    await _scanPermis(source);
  }

  // ta3mel OCR scan lel permis
  Future<void> _scanPermis(ImageSource source) async {
    // ken deja fama scan yekhdem, nوقفou
    if (_isScanningPermis) return;

    // njibou OCR service men provider
    final ocrService = ref.read(ocrServiceProvider);

    // nbadlou state l scanning
    setState(() {
      _isScanningPermis = true;
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
          _isScanningPermis = false;
        });
        return;
      }

      // ML Kit ya9ra text men image
      final rawOcrResult = await ocrService.recognizeFromFile(
        File(pickedFile.path),
      );

      // clean OCR text before parsing (fixes common character errors)
      final ocrResult = OcrTextCleaner.clean(rawOcrResult);

      // nparsew cleaned OCR text l DriverLicenseData
      final driverData = ocrService.parseDriverLicense(ocrResult);
      if (!mounted) return;

      // ncheckiw ken OCR l9a driver identity
      final hasDriverIdentity =
          _hasText(driverData.displayName) ||
          _hasText(driverData.licenseNumber) ||
          _hasText(driverData.nationalId);

      // n3abbiw fields b data extracted
      _applyDriverLicenseData(driverData);

      // message حسب OCR result
      final message = hasDriverIdentity
          ? 'Permis scanned successfully'
          : 'OCR completed, but no driver information was detected';

      // nwarriw feedback lel user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      // error message ken OCR tfشل
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan permis. Please try again.'),
        ),
      );
    } finally {
      // nرجعou scanning false
      if (mounted) {
        setState(() {
          _isScanningPermis = false;
        });
      }
    }
  }

  // t3abbi controllers b data extracted mel permis
  void _applyDriverLicenseData(DriverLicenseData data) {
    _fillController(_fullNameController, data.displayName);
    _fillController(_licenseNumberController, data.licenseNumber);
    _fillController(_nationalIdController, data.nationalId);
  }

  // t3abbi controller ken value mahech fergha
  bool _fillController(TextEditingController controller, String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return false;

    controller.value = TextEditingValue(
      text: trimmedValue,
      selection: TextSelection.collapsed(offset: trimmedValue.length),
    );
    return true;
  }

  // true ken string mahech null w mahech fergha
  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Conducteur',
      subtitle: 'Informations conducteur',
      currentStep: 3,
      totalSteps: 8,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // hero card mte3 driver step
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5EA), Color(0xFFFFFCF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // driver icon
                  const Icon(Icons.person_outline_rounded, size: 40),
                  const SizedBox(height: 20),

                  // title
                  Text(
                    'Conducteur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Renseignez les informations du conducteur impliqué : identité, permis et coordonnées.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // checklist mte3 step
            const SectionCard(
              title: 'Préparez ces éléments',
              subtitle: 'Essentiels pour avancer dans la déclaration',
              child: Column(
                children: [
                  _ChecklistRow(
                    'Identité et coordonnées du conducteur de chaque partie.',
                  ),
                  _ChecklistRow(
                    'Numéro de permis ou informations de l\'assureur si disponibles.',
                  ),
                  _ChecklistRow(
                    'Prêt pour renseigner les informations du véhicule ensuite.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 driver details
            SectionCard(
              title: 'Informations conducteur',
              subtitle: 'Pré-rempli depuis votre profil sauvegardé',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DocumentScanCard(
                    title: 'Permis de conduire',
                    subtitle:
                        'Scanner ou renseigner les informations du conducteur.',
                    isScanned:
                        _licenseNumberController.text.trim().isNotEmpty ||
                        _fullNameController.text.trim().isNotEmpty,
                    isScanning: _isScanningPermis,
                    onPressed: _isScanningPermis
                        ? null
                        : _choosePermisImageSource,
                  ),

                  if (_isScanningPermis) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Traitement de l\'image en cours...',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),

                  AppTextInput(
                    label: 'Nom complet',
                    controller: _fullNameController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Nom complet'),
                  ),
                  const SizedBox(height: 16),

                  AppTextInput(
                    label: 'Numéro de permis',
                    controller: _licenseNumberController,
                    validator: (value) => Validators.requiredField(
                      value,
                      label: 'Numéro de permis',
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppTextInput(
                    label: 'CIN / Carte nationale',
                    controller: _nationalIdController,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  AppTextInput(
                    label: 'Téléphone',
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Téléphone'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Actions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: 'Continuer vers le véhicule',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _continueToVehicle,
                  ),
                  const SizedBox(height: 12),

                  AppButton(
                    label: 'Retour aux informations accident',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(RouteNames.accidentInfoPath),
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

class _DocumentScanCard extends StatelessWidget {
  const _DocumentScanCard({
    required this.title,
    required this.subtitle,
    required this.isScanned,
    required this.isScanning,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool isScanned;
  final bool isScanning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isScanned ? AppColors.success : AppColors.trustBlue;
    final statusBackground = isScanned
        ? AppColors.successLight
        : AppColors.primaryLight;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ScanStatusChip(
                      label: isScanned ? 'Scanne' : 'Non scanne',
                      color: statusColor,
                      background: statusBackground,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              isScanning
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.primary,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanStatusChip extends StatelessWidget {
  const _ScanStatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// bottom sheet bech user ya5tar source mte3 permis image
class _PermisSourceSheet extends StatelessWidget {
  const _PermisSourceSheet();

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
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),

            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

// row sghira mte3 checklist
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow(this.text);

  // text mte3 checklist item
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // check icon
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: 10),

          // checklist text
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
