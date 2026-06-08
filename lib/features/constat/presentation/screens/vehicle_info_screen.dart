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
      // title mte3 page
      title: 'Vehicle information',

      // subtitle mte3 page
      subtitle: 'Step 3 of 8',

      // body mte3 page
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
                    'Vehicle information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),

                  // description
                  Text(
                    'Use this step to gather registration, vehicle identity, and ownership details before documenting visible impact.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // checklist mte3 step
            const SectionCard(
              title: 'Checklist',
              subtitle: 'Keep the draft moving with the essentials below',
              child: Column(
                children: [
                  _ChecklistRow(
                    'Note the registration and make or model details.',
                  ),
                  _ChecklistRow(
                    'Collect ownership or policy references tied to the vehicle.',
                  ),
                  _ChecklistRow(
                    'Prepare the draft for the photo and damage evidence stage.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // section mte3 vehicle details
            SectionCard(
              title: 'Vehicle details',
              subtitle:
                  'Prefilled from your saved vehicle profile when available',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // button scan carte grise b OCR
                  AppButton(
                    label: _isScanningCarteGrise
                        ? 'Scanning carte grise...'
                        : 'Scan carte grise',
                    icon: Icons.document_scanner_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: _isScanningCarteGrise
                        ? null
                        : _chooseCarteGriseImageSource,
                  ),

                  // loading indicator waqt scan
                  if (_isScanningCarteGrise) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Processing carte grise image...',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // plate number input
                  AppTextInput(
                    label: 'Plate number',
                    controller: _plateNumberController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Plate number'),
                  ),
                  const SizedBox(height: 16),

                  // brand w model fi nafs row
                  Row(
                    children: [
                      Expanded(
                        child: AppTextInput(
                          label: 'Brand',
                          controller: _brandController,
                          validator: (value) =>
                              Validators.requiredField(value, label: 'Brand'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextInput(
                          label: 'Model',
                          controller: _modelController,
                          validator: (value) =>
                              Validators.requiredField(value, label: 'Model'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // VIN input
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

            // section mte3 next action
            SectionCard(
              title: 'Next action',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // save vehicle info w continue
                  AppButton(
                    label: 'Continue to insurance details',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _continueToInsurance,
                  ),
                  const SizedBox(height: 12),

                  // back lel driver details
                  AppButton(
                    label: 'Back to driver details',
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
