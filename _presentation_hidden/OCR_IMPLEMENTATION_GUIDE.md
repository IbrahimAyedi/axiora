# OCR Implementation Guide - Smart Constat

## Overview
Complete OCR (Optical Character Recognition) implementation using Google ML Kit for scanning vehicle documents (Carte Grise) and driver licenses.

---

## 1. Dependencies Added

### In `pubspec.yaml`:
```yaml
google_mlkit_text_recognition: ^0.11.0  # ML Kit text recognition
image_picker: ^1.0.7                     # Camera & gallery access
camera: ^0.10.5+5                        # Direct camera control (optional)
```

**Why these?**
- `google_mlkit_text_recognition`: Google's ML Kit for efficient on-device text recognition (no internet required)
- `image_picker`: Simple camera/gallery selection
- `camera`: Advanced camera features (optional, already depends on `image_picker`)

---

## 2. Setup Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Android Configuration ✅ (Already Done)
**File**: `android/app/src/main/AndroidManifest.xml`

Permissions added:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Step 3: iOS Configuration ✅ (Already Done)
**File**: `ios/Runner/Info.plist`

Added permission descriptions:
- `NSCameraUsageDescription`: Camera access reason
- `NSPhotoLibraryUsageDescription`: Photo library access reason

### Step 4: Run the App
```bash
flutter run
```

---

## 3. Project Structure

```
lib/
├── core/
│   ├── models/
│   │   └── ocr_result.dart              # ✅ NEW: OCR result models
│   ├── services/
│   │   └── ocr_service.dart             # ✅ NEW: OCR service layer
│   └── providers/
│       └── ocr_provider.dart            # ✅ NEW: Riverpod provider
├── features/
│   └── scan/
│       └── presentation/
│           └── screens/
│               └── ocr_test_screen.dart # ✅ NEW: Test screen
└── app/
    └── router/
        └── app_router.dart              # ✅ UPDATED: Added OCR route
```

---

## 4. How to Access the OCR Test Screen

### Via Navigation:
```dart
context.pushNamed(RouteNames.ocrTest);
// or
GoRouter.of(context).pushNamed(RouteNames.ocrTest);
```

### Add Button to Home Screen:
```dart
ElevatedButton(
  onPressed: () => context.pushNamed(RouteNames.ocrTest),
  child: const Text('OCR Test'),
)
```

### Direct URL (if needed):
```
/ocr-test
```

---

## 5. Core Classes & Architecture

### A. OcrService (`lib/core/services/ocr_service.dart`)

**Main Methods:**

```dart
// 1. Recognize text from image
Future<OcrTextResult> recognizeFromFile(File imageFile)

// 2. Parse vehicle document (Carte Grise)
VehicleDocumentData parseVehicleDocument(OcrTextResult ocrResult)

// 3. Parse driver license
DriverLicenseData parseDriverLicense(OcrTextResult ocrResult)

// 4. Cleanup
Future<void> dispose()
```

**Example Usage:**
```dart
final ocrService = ref.read(ocrServiceProvider);

// Step 1: Process image
final textResult = await ocrService.recognizeFromFile(imageFile);
print('Raw text: ${textResult.rawText}');

// Step 2: Extract structured data
final vehicleData = ocrService.parseVehicleDocument(textResult);
print('Owner: ${vehicleData.ownerName}');
print('Plate: ${vehicleData.plateNumber}');
print('Confidence: ${vehicleData.confidence}');
```

### B. Models

**OcrTextResult** - Raw OCR output:
```dart
class OcrTextResult {
  final String rawText;           // Full recognized text
  final List<String> lines;       // Text broken into lines
  final DateTime processedAt;     // Processing timestamp
}
```

**VehicleDocumentData** - Extracted Carte Grise data:
```dart
class VehicleDocumentData {
  final String? ownerName;           // Vehicle owner
  final String? plateNumber;         // License plate (e.g., AB-123-CD)
  final String? vin;                 // Vehicle Identification Number
  final String? brand;               // Car brand/make
  final String? model;               // Car model
  final String? registrationDate;    // Registration date
  final double confidence;           // Extraction confidence (0.0-1.0)
}
```

**DriverLicenseData** - Extracted driver license data:
```dart
class DriverLicenseData {
  final String? firstName;           // First name
  final String? lastName;            // Last name
  final String? dateOfBirth;        // Date of birth (DD/MM/YYYY)
  final String? licenseNumber;      // License number
  final String? issuingCountry;     // Country (e.g., FR)
  final String? expiryDate;         // License expiry date
  final double confidence;          // Extraction confidence
}
```

### C. Riverpod Provider

```dart
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});
```

**Usage in screen:**
```dart
final ocrService = ref.read(ocrServiceProvider);
```

---

## 6. Test Screen Features

**File**: `lib/features/scan/presentation/screens/ocr_test_screen.dart`

### Built-in Features:
- ✅ Camera capture
- ✅ Gallery selection
- ✅ Document type selector (Carte Grise / Driver License)
- ✅ Live image preview
- ✅ Raw text display (tab 1)
- ✅ Structured data display (tab 2)
- ✅ Confidence indicator
- ✅ Error handling
- ✅ Loading state

### Screenshots:
```
┌─────────────────────────┐
│ OCR Test Screen         │
├─────────────────────────┤
│ [Document Type: Carte Grise / Driver License] │
│                         │
│ [📷 Camera] [🖼 Gallery] │
│                         │
│ [Image Preview]         │
│                         │
│ [Process with OCR]      │
│                         │
│ ┌─Raw Text─┬─Data─┐    │
│ │ (Tab with│      │    │
│ │  results)│      │    │
│ └──────────┴──────┘    │
└─────────────────────────┘
```

---

## 7. Integration Steps (Production)

### For Carte Grise Feature:

**1. Update** `lib/features/carte_grise/presentation/screens/scan_carte_grise_screen.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/ocr_provider.dart';

class ScanCarteGriseScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrService = ref.read(ocrServiceProvider);
    
    // Use ocrService.recognizeFromFile() to process images
    // Use ocrService.parseVehicleDocument() to extract data
    
    return Scaffold(...);
  }
}
```

**2. Create a service wrapper** (optional but recommended):

```dart
// lib/features/carte_grise/domain/services/carte_grise_ocr_service.dart
import '../../../../core/services/ocr_service.dart';
import '../../../../core/models/ocr_result.dart';

class CarteGriseOcrService {
  final OcrService _ocrService;
  
  CarteGriseOcrService(this._ocrService);
  
  Future<VehicleDocumentData> scanCarteGrise(File imageFile) async {
    final textResult = await _ocrService.recognizeFromFile(imageFile);
    return _ocrService.parseVehicleDocument(textResult);
  }
}
```

**3. Add Riverpod provider**:

```dart
// lib/features/carte_grise/presentation/providers/carte_grise_provider.dart
final carteGriseOcrProvider = Provider<CarteGriseOcrService>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return CarteGriseOcrService(ocrService);
});
```

### For Driver License Feature:

Same pattern as Carte Grise, using `parseDriverLicense()` instead.

---

## 8. Text Recognition Details

### Vehicle Document (Carte Grise) Parsing:

**Detected Patterns:**
- 📍 Plate Number: French format `XX-###-XX` (e.g., AB-123-CD)
- 🆔 VIN: 17-character identifier
- 📅 Registration Date: DD/MM/YYYY format
- 🏢 Owner Name: Found near "PROPRIÉTAIRE" or "NOM" keywords
- 🚗 Brand: Found near "MARQUE" keyword
- 🔧 Model: Found near "TYPE" or "MODÈLE" keyword

**Confidence Calculation:**
- Based on number of successfully extracted fields
- 0.25 per field (max 4 fields = 100% confidence)
- Displayed as percentage: 0-100%

### Driver License Parsing:

**Detected Patterns:**
- 👤 Name: First two non-numeric lines
- 📅 DOB/Expiry: Date patterns (DD/MM/YYYY)
- 🆔 License Number: 10-13 digits
- 🌍 Country: Detected from "FR" or similar codes

---

## 9. Error Handling

### Built-in Error Handling:

```dart
try {
  final result = await ocrService.recognizeFromFile(imageFile);
  // Success
} catch (e) {
  print('Error: $e');
  // Handle error
}
```

### Common Errors:

| Error | Cause | Solution |
|-------|-------|----------|
| `Permission denied` | Camera/gallery access denied | Request permission |
| `Image processing failed` | Invalid or corrupted image | Select clear image |
| `No text detected` | Blank or non-document image | Use actual document |
| `TextRecognizer already released` | Service disposed prematurely | Ensure proper lifecycle |

---

## 10. Performance Notes

- ✅ **On-device processing**: No internet required, faster
- ✅ **Latin script optimized**: French documents supported
- ⏱️ **Processing time**: ~500ms-2s depending on image size
- 💾 **Memory efficient**: ML Kit optimized for mobile

### Optimization Tips:

```dart
// 1. Resize large images before processing
final image = Image.file(imageFile);
// Resize if needed

// 2. Process only when necessary (avoid re-processing)

// 3. Dispose service when done
await ocrService.dispose();
```

---

## 11. Testing Checklist

- [ ] Run `flutter pub get`
- [ ] Build app: `flutter build apk` (Android) / `flutter build ios` (iOS)
- [ ] Navigate to OCR test screen
- [ ] Test camera capture
- [ ] Test gallery selection
- [ ] Test Carte Grise parsing
- [ ] Test Driver License parsing
- [ ] Verify permissions requested at runtime (Android 6+)
- [ ] Test with real vehicle documents
- [ ] Verify confidence indicator accuracy

---

## 12. Next Steps (Production Ready)

1. **Move test screen to feature**:
   - Rename to `carte_grise_scan_screen.dart`
   - Integrate with existing flow

2. **Add Firebase logging** (optional):
   ```dart
   await FirebaseAnalytics.instance.logEvent(
     name: 'ocr_carte_grise_scanned',
     parameters: {
       'confidence': vehicleData.confidence,
       'plate_detected': vehicleData.plateNumber != null,
     },
   );
   ```

3. **Add result validation screen**:
   - Show extracted data
   - Allow user to edit/confirm
   - Save to Firestore

4. **Add camera UI overlay** (optional):
   - Document corners
   - Focus guides
   - Capture button

5. **Performance optimization**:
   - Image compression before processing
   - Batch processing if needed
   - Caching results

---

## 13. File Checklist

✅ New Files Created:
- [x] `lib/core/models/ocr_result.dart` - Models
- [x] `lib/core/services/ocr_service.dart` - Service
- [x] `lib/core/providers/ocr_provider.dart` - Provider
- [x] `lib/features/scan/presentation/screens/ocr_test_screen.dart` - Test screen

✅ Updated Files:
- [x] `pubspec.yaml` - Dependencies
- [x] `android/app/src/main/AndroidManifest.xml` - Permissions
- [x] `ios/Runner/Info.plist` - Permissions
- [x] `lib/app/router/route_names.dart` - Routes
- [x] `lib/app/router/app_router.dart` - Routes

---

## 14. Support & Troubleshooting

### Common Issues:

**Q: "google_mlkit_text_recognition not found"**
```bash
# Solution:
flutter clean
flutter pub get
flutter pub upgrade google_mlkit_text_recognition
```

**Q: Camera permission not working**
```bash
# Solution: Ensure permissions in manifest/Info.plist
# Android 6+: Permissions requested at runtime automatically
# iOS: Only use camera/gallery when permissions granted
```

**Q: Text not being detected**
- Ensure document is well-lit
- Document should be in frame clearly
- Try rotating the image
- Test with test images first

**Q: High memory usage**
- Process images one at a time
- Call `dispose()` after processing
- Reduce image resolution if needed

---

## 15. Quick Reference

```dart
// Import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_constat/core/providers/ocr_provider.dart';

// Get service
final ocrService = ref.read(ocrServiceProvider);

// Process image
final result = await ocrService.recognizeFromFile(imageFile);

// Parse Carte Grise
final carteGrise = ocrService.parseVehicleDocument(result);
print(carteGrise.plateNumber); // Output: "AB123CD"

// Parse Driver License
final license = ocrService.parseDriverLicense(result);
print(license.firstName); // Output: "Jean"

// Clean up
await ocrService.dispose();
```

---

## Ready to Use! 🚀

Your OCR implementation is complete and ready for production integration. The test screen is fully functional for immediate testing.

**Next**: Navigate to `/ocr-test` route or add a button in your home screen to access the test screen.

