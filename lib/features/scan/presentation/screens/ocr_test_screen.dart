import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/ocr_result.dart';
import '../../../../core/providers/ocr_provider.dart';

class OcrTestScreen extends ConsumerStatefulWidget {
  const OcrTestScreen({super.key});

  @override
  ConsumerState<OcrTestScreen> createState() => _OcrTestScreenState();
}

class _OcrTestScreenState extends ConsumerState<OcrTestScreen> {
  File? _selectedImage;
  OcrTextResult? _ocrResult;
  VehicleDocumentData? _vehicleData;
  DriverLicenseData? _driverData;
  bool _isProcessing = false;
  String _selectedDocType = 'carte_grise'; // carte_grise or driver_license
  String? _errorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Test - Vehicle Document Scanner'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Type Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const <ButtonSegment<String>>[
                                ButtonSegment<String>(
                                  value: 'carte_grise',
                                  label: Text('Carte Grise'),
                                ),
                                ButtonSegment<String>(
                                  value: 'driver_license',
                                  label: Text('Driver License'),
                                ),
                              ],
                              selected: <String>{_selectedDocType},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _selectedDocType = newSelection.first;
                                  _resetResults();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.image),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selected Image Preview
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              if (_selectedImage != null) const SizedBox(height: 16),

              // Process Button
              if (_selectedImage != null && !_isProcessing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _processImage,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Process with OCR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // Loading Indicator
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing image...'),
                      ],
                    ),
                  ),
                ),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                ),

              // Results Display
              if (_ocrResult != null) ...[
                const SizedBox(height: 24),
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs for Raw Text and Structured Data
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Raw Text'),
                  Tab(text: 'Extracted Data'),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    // Raw Text Tab
                    _buildRawTextView(),
                    // Extracted Data Tab
                    _buildExtractedDataView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRawTextView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detected Text:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _ocrResult!.rawText.isEmpty
                    ? 'No text detected'
                    : _ocrResult!.rawText,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lines Detected: ${_ocrResult!.lines.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedDataView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _selectedDocType == 'carte_grise'
            ? _buildVehicleDataView()
            : _buildDriverDataView(),
      ),
    );
  }

  Widget _buildVehicleDataView() {
    if (_vehicleData == null) {
      return const Center(child: Text('No vehicle data extracted'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataField('Owner Name', _vehicleData!.ownerName),
        _buildDataField('Plate Number', _vehicleData!.plateNumber),
        _buildDataField('VIN', _vehicleData!.vin),
        _buildDataField(
          'Registration Number',
          _vehicleData!.registrationNumber,
        ),
        _buildDataField('Brand', _vehicleData!.brand),
        _buildDataField('Model', _vehicleData!.model),
        _buildDataField('Registration Date', _vehicleData!.registrationDate),
        const SizedBox(height: 16),
        _buildConfidenceIndicator(_vehicleData!.confidence),
        const SizedBox(height: 12),
        Text(
          'Extracted Data: $_vehicleData',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverDataView() {
    if (_driverData == null) {
      return const Center(child: Text('No driver license data extracted'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataField('First Name', _driverData!.firstName),
        _buildDataField('Last Name', _driverData!.lastName),
        _buildDataField('Date of Birth', _driverData!.dateOfBirth),
        _buildDataField('License Number', _driverData!.licenseNumber),
        _buildDataField('Issuing Country', _driverData!.issuingCountry),
        _buildDataField('Expiry Date', _driverData!.expiryDate),
        const SizedBox(height: 16),
        _buildConfidenceIndicator(_driverData!.confidence),
        const SizedBox(height: 12),
        Text(
          'Extracted Data: $_driverData',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDataField(String label, String? value) {
    final hasValue = value != null && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasValue ? Colors.green[50] : Colors.orange[50],
              border: Border.all(
                color: hasValue ? Colors.green[300]! : Colors.orange[300]!,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? '(Not detected)',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasValue ? Colors.grey[800] : Colors.orange[700],
                    ),
                  ),
                ),
                if (hasValue)
                  Icon(Icons.check_circle, color: Colors.green[600], size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Extraction Confidence',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('$percentage%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence >= 0.75
                  ? Colors.green
                  : confidence >= 0.5
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.camera);
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
          _resetResults();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
          _resetResults();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gallery error: $e';
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final ocrService = ref.read(ocrServiceProvider);

      // Process with OCR
      final result = await ocrService.recognizeFromFile(_selectedImage!);
      setState(() {
        _ocrResult = result;
      });

      // Parse based on document type
      if (_selectedDocType == 'carte_grise') {
        final vehicleData = ocrService.parseVehicleDocument(result);
        setState(() {
          _vehicleData = vehicleData;
          _driverData = null;
        });
      } else {
        final driverData = ocrService.parseDriverLicense(result);
        setState(() {
          _driverData = driverData;
          _vehicleData = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing image: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _resetResults() {
    setState(() {
      _ocrResult = null;
      _vehicleData = null;
      _driverData = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
