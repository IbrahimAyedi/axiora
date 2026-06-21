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

// screen mte3 vehicle information
// user y3abi vehicle info w ينجم yscan carte grise b OCR
class VehicleInfoScreen extends ConsumerStatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  ConsumerState<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends ConsumerState<VehicleInfoScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // image picker bech na5dhou carte grise men camera wala gallery
  final ImagePicker _imagePicker = ImagePicker();

  // controllers mte3 vehicle fields
  late final TextEditingController _plateNumberController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _vinController;

  // true waqt OCR carte grise yekhdem
  bool _isScanningCarteGrise = false;

  @override
  void initState() {
    super.initState();

    // njibou session data
    final session = ref.read(appSessionProvider);

    // vehicle profile principal
    final profile = session.mainVehicleProfile;

    // vehicle snapshot saved fi active constat ken mawjoud
    final snapshot = session.activeConstat?.vehicleSnapshot;

    // n3abbiw plate number men snapshot wala profile
    _plateNumberController = TextEditingController(
      text: snapshot?['plateNumber'] as String? ?? profile?.plateNumber ?? '',
    );

    // n3abbiw brand
    _brandController = TextEditingController(
      text: snapshot?['brand'] as String? ?? profile?.brand ?? '',
    );

    // n3abbiw model
    _modelController = TextEditingController(
      text: snapshot?['model'] as String? ?? profile?.model ?? '',
    );

    // n3abbiw VIN
    _vinController = TextEditingController(
      text: snapshot?['vin'] as String? ?? profile?.vin ?? '',
    );
  }

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  // tsajel vehicle draft w temchi lel insurance step
  void _continueToInsurance() {
    // nvalidiw form 9bal ma nkamlou
    if (!_formKey.currentState!.validate()) return;

    // nsajlou vehicle info fi active constat/session
    ref
        .read(appSessionProvider.notifier)
        .saveConstatVehicleDraft(
          plateNumber: _plateNumberController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          vin: _vinController.text.trim(),
        );

    // nemchiw lel insurance info screen
    context.push(RouteNames.insuranceInfoPath);
  }

  // t7el bottom sheet bech user ya5tar camera wala gallery
  Future<void> _chooseCarteGriseImageSource() async {
    // nsakrou keyboard ken mawjoud
    FocusScope.of(context).unfocus();

    // nwarriw source sheet
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const _CarteGriseSourceSheet(),
    );

    // ken user cancel, nوقفou
    if (!mounted || source == null) return;

    // nebdew scan carte grise
    await _scanCarteGrise(source);
  }

  // ta3mel OCR scan lel carte grise
  Future<void> _scanCarteGrise(ImageSource source) async {
    // ken deja fama scan yekhdem, nوقفou
    if (_isScanningCarteGrise) return;

    // njibou OCR service men provider
    final ocrService = ref.read(ocrServiceProvider);

    // nbadlou state l scanning
    setState(() {
      _isScanningCarteGrise = true;
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
          _isScanningCarteGrise = false;
        });
        return;
      }

      // ML Kit ya9ra text men image
      final rawOcrResult = await ocrService.recognizeFromFile(
        File(pickedFile.path),
      );

      // clean OCR text before parsing (fixes common character errors)
      final ocrResult = OcrTextCleaner.clean(rawOcrResult);

      // nparsew cleaned OCR text l VehicleDocumentData
      final vehicleData = ocrService.parseVehicleDocument(ocrResult);
      if (!mounted) return;

      // ncheckiw ken OCR l9a vehicle info
      final hasVehicleInfo =
          _hasText(vehicleData.plateNumber) ||
          _hasText(vehicleData.brand) ||
          _hasText(vehicleData.model) ||
          _hasText(vehicleData.vin);

      // n3abbiw fields b data extracted
      _applyVehicleDocumentData(vehicleData);

      // message حسب OCR result
      final message = hasVehicleInfo
          ? vehicleData.confidence >= 0.75
                ? 'Carte grise scanned successfully'
                : 'Carte grise scanned partially. Please verify missing fields.'
          : 'OCR completed, but no vehicle information was detected.';

      // nwarriw feedback lel user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted) return;

      // error message ken OCR tfشل
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan carte grise. Please try again.'),
        ),
      );
    } finally {
      // nرجعou scanning false
      if (mounted) {
        setState(() {
          _isScanningCarteGrise = false;
        });
      }
    }
  }

  // t3abbi controllers b data extracted mel carte grise
  void _applyVehicleDocumentData(VehicleDocumentData data) {
    _fillController(_plateNumberController, data.plateNumber);
    _fillController(_brandController, data.brand);
    _fillController(_modelController, data.model);
    _fillController(_vinController, data.vin);
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
      title: 'Véhicule',
      subtitle: 'Informations véhicule',
      currentStep: 4,
      totalSteps: 8,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // hero card mte3 vehicle step
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
                  // vehicle icon
                  const Icon(Icons.directions_car_outlined, size: 40),
                  const SizedBox(height: 20),

                  // title
                  Text(
                    'Véhicule',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Renseignez les informations du véhicule : immatriculation, marque, modèle et numéro VIN.',
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
                    'Immatriculation, marque et modèle du véhicule.',
                  ),
                  _ChecklistRow(
                    'Références de propriété ou de contrat liées au véhicule.',
                  ),
                  _ChecklistRow('Prêt pour l\'étape photos et dégâts.'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 vehicle details
            SectionCard(
              title: 'Informations véhicule',
              subtitle: 'Pré-rempli depuis votre profil véhicule sauvegardé',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DocumentScanCard(
                    title: 'Carte grise',
                    subtitle:
                        'Scanner le document pour preremplir le vehicule.',
                    isScanned:
                        _plateNumberController.text.trim().isNotEmpty ||
                        _vinController.text.trim().isNotEmpty,
                    isScanning: _isScanningCarteGrise,
                    onPressed: _isScanningCarteGrise
                        ? null
                        : _chooseCarteGriseImageSource,
                  ),

                  if (_isScanningCarteGrise) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Traitement de la carte grise...',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),

                  AppTextInput(
                    label: 'Immatriculation',
                    controller: _plateNumberController,
                    validator: (value) => Validators.requiredField(
                      value,
                      label: 'Immatriculation',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextInput(
                          label: 'Marque',
                          controller: _brandController,
                          validator: (value) =>
                              Validators.requiredField(value, label: 'Marque'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextInput(
                          label: 'Modèle',
                          controller: _modelController,
                          validator: (value) =>
                              Validators.requiredField(value, label: 'Modèle'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextInput(
                    label: 'VIN',
                    controller: _vinController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'VIN'),
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
                    label: 'Continuer vers l\'assurance',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _continueToInsurance,
                  ),
                  const SizedBox(height: 12),

                  AppButton(
                    label: 'Retour aux informations conducteur',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(RouteNames.driverInfoPath),
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
                  Icons.directions_car_filled_outlined,
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

// bottom sheet bech user ya5tar source mte3 carte grise image
class _CarteGriseSourceSheet extends StatelessWidget {
  const _CarteGriseSourceSheet();

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
