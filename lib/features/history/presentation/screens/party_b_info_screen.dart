import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/ocr_result.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/providers/ocr_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/section_card.dart';

class PartyBInfoScreen extends ConsumerStatefulWidget {
  const PartyBInfoScreen({required this.constatId, this.ownerUid, super.key});

  final String constatId;

  /// UID of the user who owns the constat. Present when navigating from a
  /// cross-user approval notification so that Firestore saves go to the
  /// correct owner path. The constat is already loaded into session state by
  /// [ConstatDetailScreen] before this screen is pushed, so no fetch is
  /// needed here.
  final String? ownerUid;

  @override
  ConsumerState<PartyBInfoScreen> createState() => _PartyBInfoScreenState();
}

class _PartyBInfoScreenState extends ConsumerState<PartyBInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Driver controllers
  late final TextEditingController _driverFullNameController;
  late final TextEditingController _driverLicenseNumberController;
  late final TextEditingController _driverNationalIdController;
  late final TextEditingController _driverPhoneNumberController;

  // Vehicle controllers
  late final TextEditingController _vehiclePlateNumberController;
  late final TextEditingController _vehicleBrandController;
  late final TextEditingController _vehicleModelController;
  late final TextEditingController _vehicleVinController;

  // Insurance controllers
  late final TextEditingController _insuranceNumberController;
  late final TextEditingController _insuranceCompanyNameController;
  late final TextEditingController _insurancePolicyHolderNameController;
  late final TextEditingController _insurancePolicyTypeController;

  bool _isScanningPermis = false;
  bool _isScanningCarteGrise = false;
  bool _isScanningAssurance = false;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(appSessionProvider.notifier);
    final constat = notifier.getConstatById(widget.constatId);

    // Initialize driver controllers
    _driverFullNameController = TextEditingController(
      text: constat?.partyBDriverSnapshot?['fullName'] as String? ?? '',
    );
    _driverLicenseNumberController = TextEditingController(
      text: constat?.partyBDriverSnapshot?['licenseNumber'] as String? ?? '',
    );
    _driverNationalIdController = TextEditingController(
      text: constat?.partyBDriverSnapshot?['nationalId'] as String? ?? '',
    );
    _driverPhoneNumberController = TextEditingController(
      text: constat?.partyBDriverSnapshot?['phoneNumber'] as String? ?? '',
    );

    // Initialize vehicle controllers
    _vehiclePlateNumberController = TextEditingController(
      text: constat?.partyBVehicleSnapshot?['plateNumber'] as String? ?? '',
    );
    _vehicleBrandController = TextEditingController(
      text: constat?.partyBVehicleSnapshot?['brand'] as String? ?? '',
    );
    _vehicleModelController = TextEditingController(
      text: constat?.partyBVehicleSnapshot?['model'] as String? ?? '',
    );
    _vehicleVinController = TextEditingController(
      text: constat?.partyBVehicleSnapshot?['vin'] as String? ?? '',
    );

    // Initialize insurance controllers
    _insuranceNumberController = TextEditingController(
      text:
          constat?.partyBInsuranceSnapshot?['insuranceNumber'] as String? ?? '',
    );
    _insuranceCompanyNameController = TextEditingController(
      text: constat?.partyBInsuranceSnapshot?['companyName'] as String? ?? '',
    );
    _insurancePolicyHolderNameController = TextEditingController(
      text:
          constat?.partyBInsuranceSnapshot?['policyHolderName'] as String? ??
          '',
    );
    _insurancePolicyTypeController = TextEditingController(
      text: constat?.partyBInsuranceSnapshot?['policyType'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _driverFullNameController.dispose();
    _driverLicenseNumberController.dispose();
    _driverNationalIdController.dispose();
    _driverPhoneNumberController.dispose();
    _vehiclePlateNumberController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleVinController.dispose();
    _insuranceNumberController.dispose();
    _insuranceCompanyNameController.dispose();
    _insurancePolicyHolderNameController.dispose();
    _insurancePolicyTypeController.dispose();
    super.dispose();
  }

  Future<void> _saveAndReturn() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(appSessionProvider.notifier);

    // Save driver info
    await notifier.savePartyBDriverInfo(
      constatId: widget.constatId,
      fullName: _driverFullNameController.text.trim(),
      licenseNumber: _driverLicenseNumberController.text.trim(),
      nationalId: _driverNationalIdController.text.trim(),
      phoneNumber: _driverPhoneNumberController.text.trim(),
    );

    // Save vehicle info
    await notifier.savePartyBVehicleInfo(
      constatId: widget.constatId,
      plateNumber: _vehiclePlateNumberController.text.trim(),
      brand: _vehicleBrandController.text.trim(),
      model: _vehicleModelController.text.trim(),
      vin: _vehicleVinController.text.trim(),
    );

    // Save insurance info (this also marks completion)
    await notifier.savePartyBInsuranceInfo(
      constatId: widget.constatId,
      insuranceNumber: _insuranceNumberController.text.trim(),
      companyName: _insuranceCompanyNameController.text.trim(),
      policyHolderName: _insurancePolicyHolderNameController.text.trim(),
      policyType: _insurancePolicyTypeController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your information has been saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    context.pop();
  }

  // Permis OCR methods
  Future<void> _choosePermisImageSource() async {
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const _ImageSourceSheet(title: 'Scan permis'),
    );

    if (!mounted || source == null) return;
    await _scanPermis(source);
  }

  Future<void> _scanPermis(ImageSource source) async {
    if (_isScanningPermis) return;

    final ocrService = ref.read(ocrServiceProvider);

    setState(() {
      _isScanningPermis = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted) return;

      if (pickedFile == null) {
        setState(() {
          _isScanningPermis = false;
        });
        return;
      }

      final ocrResult = await ocrService.recognizeFromFile(
        File(pickedFile.path),
      );
      final driverData = ocrService.parseDriverLicense(ocrResult);
      if (!mounted) return;

      _applyDriverLicenseData(driverData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permis scanned successfully')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan permis. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanningPermis = false;
        });
      }
    }
  }

  void _applyDriverLicenseData(DriverLicenseData data) {
    _fillController(_driverFullNameController, data.displayName);
    _fillController(_driverLicenseNumberController, data.licenseNumber);
    _fillController(_driverNationalIdController, data.nationalId);
  }

  // Carte Grise OCR methods
  Future<void> _chooseCarteGriseImageSource() async {
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const _ImageSourceSheet(title: 'Scan carte grise'),
    );

    if (!mounted || source == null) return;
    await _scanCarteGrise(source);
  }

  Future<void> _scanCarteGrise(ImageSource source) async {
    if (_isScanningCarteGrise) return;

    final ocrService = ref.read(ocrServiceProvider);

    setState(() {
      _isScanningCarteGrise = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted) return;

      if (pickedFile == null) {
        setState(() {
          _isScanningCarteGrise = false;
        });
        return;
      }

      final ocrResult = await ocrService.recognizeFromFile(
        File(pickedFile.path),
      );
      final vehicleData = ocrService.parseVehicleDocument(ocrResult);
      if (!mounted) return;

      _applyVehicleDocumentData(vehicleData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte grise scanned successfully')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan carte grise. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanningCarteGrise = false;
        });
      }
    }
  }

  void _applyVehicleDocumentData(VehicleDocumentData data) {
    _fillController(_vehiclePlateNumberController, data.plateNumber);
    _fillController(_vehicleBrandController, data.brand);
    _fillController(_vehicleModelController, data.model);
    _fillController(_vehicleVinController, data.vin);
  }

  // Assurance OCR methods
  Future<void> _chooseAssuranceImageSource() async {
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => const _ImageSourceSheet(title: 'Scan assurance'),
    );

    if (!mounted || source == null) return;
    await _scanAssurance(source);
  }

  Future<void> _scanAssurance(ImageSource source) async {
    if (_isScanningAssurance) return;

    final ocrService = ref.read(ocrServiceProvider);

    setState(() {
      _isScanningAssurance = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted) return;

      if (pickedFile == null) {
        setState(() {
          _isScanningAssurance = false;
        });
        return;
      }

      final ocrResult = await ocrService.recognizeFromFile(
        File(pickedFile.path),
      );
      final insuranceData = ocrService.parseInsuranceDocument(ocrResult);
      if (!mounted) return;

      _applyInsuranceDocumentData(insuranceData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assurance scanned successfully')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan assurance. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanningAssurance = false;
        });
      }
    }
  }

  void _applyInsuranceDocumentData(InsuranceDocumentData data) {
    _fillController(_insuranceNumberController, data.insuranceNumber);
    _fillController(_insuranceCompanyNameController, data.companyName);
    _fillController(
      _insurancePolicyHolderNameController,
      data.policyHolderName,
    );
    _fillController(_insurancePolicyTypeController, data.policyType);
  }

  bool _fillController(TextEditingController controller, String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return false;

    controller.value = TextEditingValue(
      text: trimmedValue,
      selection: TextSelection.collapsed(offset: trimmedValue.length),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPageScaffold(
      title: 'Complete your information',
      subtitle: 'Party B details',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5EA), Color(0xFFFFFCF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_document, size: 40),
                  const SizedBox(height: 20),
                  Text(
                    'Complete your information',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please provide your driver, vehicle, and insurance information to complete the approval process.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Driver Information Section
            SectionCard(
              title: 'Driver information',
              subtitle: 'Your driver details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: _isScanningPermis
                        ? 'Scanning permis...'
                        : 'Scan permis',
                    icon: Icons.document_scanner_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: _isScanningPermis
                        ? null
                        : _choosePermisImageSource,
                  ),
                  if (_isScanningPermis) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Full name',
                    controller: _driverFullNameController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Full name'),
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'License number',
                    controller: _driverLicenseNumberController,
                    validator: (value) => Validators.requiredField(
                      value,
                      label: 'License number',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'CIN / National ID',
                    controller: _driverNationalIdController,
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Phone number',
                    controller: _driverPhoneNumberController,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Phone number'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Information Section
            SectionCard(
              title: 'Vehicle information',
              subtitle: 'Your vehicle details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  if (_isScanningCarteGrise) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Plate number',
                    controller: _vehiclePlateNumberController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Plate number'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextInput(
                          label: 'Brand',
                          controller: _vehicleBrandController,
                          validator: (value) =>
                              Validators.requiredField(value, label: 'Brand'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextInput(
                          label: 'Model',
                          controller: _vehicleModelController,
                          validator: (value) =>
                              Validators.requiredField(value, label: 'Model'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'VIN',
                    controller: _vehicleVinController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'VIN'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Insurance Information Section
            SectionCard(
              title: 'Insurance information',
              subtitle: 'Your insurance details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: _isScanningAssurance
                        ? 'Scanning assurance...'
                        : 'Scan assurance',
                    icon: Icons.document_scanner_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: _isScanningAssurance
                        ? null
                        : _chooseAssuranceImageSource,
                  ),
                  if (_isScanningAssurance) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Insurance number',
                    controller: _insuranceNumberController,
                    validator: (value) => Validators.requiredField(
                      value,
                      label: 'Insurance number',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Company name',
                    controller: _insuranceCompanyNameController,
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Company name'),
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Policy holder name',
                    controller: _insurancePolicyHolderNameController,
                    validator: (value) => Validators.requiredField(
                      value,
                      label: 'Policy holder name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Policy type',
                    controller: _insurancePolicyTypeController,
                    hint: 'Optional',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            SectionCard(
              title: 'Actions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: 'Save and return',
                    icon: Icons.check,
                    onPressed: _saveAndReturn,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Cancel',
                    icon: Icons.close,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.pop(),
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

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
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
