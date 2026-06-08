import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/ocr_provider.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/services/ocr_text_cleaner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

// screen mte3 scan carte grise
// user ya5tar image men camera wala gallery, ba3ed OCR ya9raha
class ScanCarteGriseScreen extends ConsumerStatefulWidget {
  const ScanCarteGriseScreen({super.key});

  @override
  ConsumerState<ScanCarteGriseScreen> createState() =>
      _ScanCarteGriseScreenState();
}

class _ScanCarteGriseScreenState extends ConsumerState<ScanCarteGriseScreen> {
  // image picker bech na5dhou image men camera/gallery
  final ImagePicker _imagePicker = ImagePicker();

  // image eli user اختارها
  File? _selectedImage;

  // source mte3 image: camera wala gallery
  String _selectedSource = 'camera';

  // true waqt OCR processing yekhdem
  bool _isProcessing = false;

  // error message ken fama problem
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      // title mte3 page
      title: 'Scan carte grise',

      // subtitle mte3 page
      subtitle: 'Prepare OCR auto-fill flow',

      // body mte3 page
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // preview zone mte3 image
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),

            // ken image selected, nwarriwha
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                // sinon nwarriw placeholder
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.document_scanner_outlined, size: 52),
                      SizedBox(height: 12),
                      Text('No image selected'),
                      SizedBox(height: 8),
                      Text('Capture or import a registration card image'),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // buttons camera w gallery
          Row(
            children: [
              // pick image from camera
              Expanded(
                child: AppButton(
                  label: 'Camera',
                  icon: Icons.camera_alt_outlined,
                  onPressed: _isProcessing ? null : () => _pickImage(true),
                ),
              ),
              const SizedBox(width: 12),

              // pick image from gallery
              Expanded(
                child: AppButton(
                  label: 'Gallery',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.photo_library_outlined,
                  onPressed: _isProcessing ? null : () => _pickImage(false),
                ),
              ),
            ],
          ),

          // error text ken fama problem
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),

          // fields eli OCR expected yest5arjhom
          const SectionCard(
            title: 'Expected extracted fields',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plate number'),
                SizedBox(height: 8),
                Text('Owner name'),
                SizedBox(height: 8),
                Text('Brand and model'),
                SizedBox(height: 8),
                Text('VIN'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // button ybda OCR processing w yemchi lel result preview
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

  // ta5tar image men camera wala gallery
  Future<void> _pickImage(bool fromCamera) async {
    try {
      // n7ellou camera wala gallery حسب fromCamera
      final file = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );

      // ken user cancel, ma na3mlou chay
      if (file == null) return;

      // nsajlou image selected w source mte3ha
      setState(() {
        _selectedImage = File(file.path);
        _selectedSource = fromCamera ? 'camera' : 'gallery';
        _error = null;
      });
    } catch (e) {
      // error fi image picker
      setState(() {
        _error = 'Unable to pick image: $e';
      });
    }
  }

  // ta3mel OCR processing lel image selected
  Future<void> _processSelectedImage() async {
    final image = _selectedImage;

    // ken ma famech image, nوقفou
    if (image == null) return;

    // nbadlou state l processing
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // nebdew scan carte grise fi app session
      ref
          .read(appSessionProvider.notifier)
          .startCarteGriseScan(source: _selectedSource);

      // njibou OCR service men provider
      final ocrService = ref.read(ocrServiceProvider);

      // ML Kit ya9ra text men image
      final rawResult = await ocrService.recognizeFromFile(image);

      // clean OCR text before parsing (fixes common character errors)
      final textResult = OcrTextCleaner.clean(rawResult);

      // nparsew cleaned OCR text l vehicle data
      final vehicleData = ocrService.parseVehicleDocument(textResult);

      // nkamlou scan w nsajlou extracted vehicle data + actual confidence
      ref
          .read(appSessionProvider.notifier)
          .completeCarteGriseScan(
            plateNumber: vehicleData.plateNumber ?? '',
            ownerName: vehicleData.ownerName ?? '',
            brand: vehicleData.brand ?? '',
            model: vehicleData.model ?? '',
            vin: vehicleData.vin ?? '',
            confidence: vehicleData.confidence,
            registrationDate: vehicleData.registrationDate,
            debugRawText: rawResult.rawText,
            debugCleanedText: textResult.rawText,
          );

      if (!mounted) return;

      // nemchiw lel OCR result preview screen
      context.push(RouteNames.carteGriseResultPath);
    } catch (e) {
      // ken OCR processing tfشل
      setState(() {
        _error = 'OCR processing failed: $e';
      });
    } finally {
      // nرجعou processing false
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
