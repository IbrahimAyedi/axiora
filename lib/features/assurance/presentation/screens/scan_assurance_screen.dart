import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/providers/ocr_provider.dart';
import '../../../../core/services/ocr_text_cleaner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

/// Scan screen for the attestation d'assurance (insurance certificate).
/// Flow: camera/gallery → ML Kit OCR → OcrTextCleaner → parseInsuranceDocument
/// → completeAssuranceScan → assurance result/confirmation screen.
class ScanAssuranceScreen extends ConsumerStatefulWidget {
  const ScanAssuranceScreen({super.key});

  @override
  ConsumerState<ScanAssuranceScreen> createState() =>
      _ScanAssuranceScreenState();
}

class _ScanAssuranceScreenState extends ConsumerState<ScanAssuranceScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String _selectedSource = 'camera';
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: "Scan attestation d'assurance",
      subtitle: 'Insurance document OCR auto-fill',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview zone
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(24),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 52,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 12),
                      Text('Aucune image selectionnee'),
                      SizedBox(height: 8),
                      Text(
                        'Placez le document dans le cadre.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          const SectionCard(
            icon: Icons.crop_free_outlined,
            title: 'Instruction',
            subtitle: 'Placez le document dans le cadre.',
            child: Text(
              'Gardez l\'attestation lisible, complete et sans reflet.',
            ),
          ),
          const SizedBox(height: 16),

          // Camera / gallery buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Camera',
                  icon: Icons.camera_alt_outlined,
                  onPressed: _isProcessing ? null : () => _pickImage(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Galerie',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.photo_library_outlined,
                  onPressed: _isProcessing ? null : () => _pickImage(false),
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),

          // Expected fields
          const SectionCard(
            title: 'Fields to be extracted',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insurance company'),
                SizedBox(height: 6),
                Text('Insurance / policy number'),
                SizedBox(height: 6),
                Text('Policy holder name'),
                SizedBox(height: 6),
                Text('Usage / policy type'),
                SizedBox(height: 6),
                Text('Validity dates (from / to)'),
              ],
            ),
          ),

          // Photo tips
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Tips for best results',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TipRow(Icons.wb_sunny_outlined, 'Good lighting — no shadows'),
                SizedBox(height: 4),
                _TipRow(
                  Icons.crop_free_outlined,
                  'Entire document inside the frame',
                ),
                SizedBox(height: 4),
                _TipRow(Icons.flash_off_outlined, 'Avoid flash reflection'),
                SizedBox(height: 4),
                _TipRow(Icons.straighten_outlined, 'Keep the document flat'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AppButton(
            label: 'Continue to OCR preview',
            icon: Icons.auto_fix_high_outlined,
            onPressed: _selectedImage == null || _isProcessing
                ? null
                : _processSelectedImage,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final file = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (file == null) return;
      setState(() {
        _selectedImage = File(file.path);
        _selectedSource = fromCamera ? 'camera' : 'gallery';
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Unable to pick image: $e');
    }
  }

  Future<void> _processSelectedImage() async {
    final image = _selectedImage;
    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      ref
          .read(appSessionProvider.notifier)
          .startAssuranceScan(source: _selectedSource);

      final ocrService = ref.read(ocrServiceProvider);
      final rawResult = await ocrService.recognizeFromFile(image);
      final cleanedResult = OcrTextCleaner.clean(rawResult);
      final insuranceData = ocrService.parseInsuranceDocument(cleanedResult);

      ref
          .read(appSessionProvider.notifier)
          .completeAssuranceScan(
            insuranceNumber: insuranceData.insuranceNumber ?? '',
            companyName: insuranceData.companyName ?? '',
            policyHolderName: insuranceData.policyHolderName ?? '',
            policyType: insuranceData.policyType ?? '',
            validFrom: insuranceData.validFrom ?? '',
            validTo: insuranceData.validTo ?? '',
            confidence: insuranceData.confidence,
            debugRawText: rawResult.rawText,
            debugCleanedText: cleanedResult.rawText,
          );

      if (!mounted) return;
      context.push(RouteNames.assuranceResultPath);
    } catch (e) {
      setState(() => _error = 'OCR processing failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
