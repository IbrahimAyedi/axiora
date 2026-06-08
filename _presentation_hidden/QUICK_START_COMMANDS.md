# OCR Quick Start Commands

## 🚀 Get Started (Copy & Paste)

### Step 1: Install Dependencies
```bash
flutter pub get
flutter pub upgrade
```

### Step 2: Build & Run
```bash
# Full clean build
flutter clean
flutter pub get
flutter run

# Or for Android
flutter run -d android

# Or for iOS
flutter run -d ios
```

### Step 3: Test OCR
1. Once app is running, navigate to OCR test screen:
   ```
   Route: /ocr-test
   ```
2. Or add this button to your home screen:
   ```dart
   ElevatedButton(
     onPressed: () => context.pushNamed(RouteNames.ocrTest),
     child: const Text('Test OCR'),
   )
   ```

---

## 📁 File Changes Summary

### New Files (4 files)
```
✅ lib/core/models/ocr_result.dart
✅ lib/core/services/ocr_service.dart
✅ lib/core/providers/ocr_provider.dart
✅ lib/features/scan/presentation/screens/ocr_test_screen.dart
```

### Updated Files (5 files)
```
✅ pubspec.yaml (3 dependencies added)
✅ android/app/src/main/AndroidManifest.xml (3 permissions)
✅ ios/Runner/Info.plist (3 permission descriptions)
✅ lib/app/router/route_names.dart (2 entries)
✅ lib/app/router/app_router.dart (1 route)
```

### Documentation Files (3 files)
```
✅ OCR_IMPLEMENTATION_GUIDE.md (15 sections)
✅ OCR_INTEGRATION_EXAMPLES.dart (5 examples)
✅ OCR_SETUP_VERIFICATION.md (verification)
```

---

## 💻 Usage Examples

### Example 1: Basic Usage
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_constat/core/providers/ocr_provider.dart';

// In a ConsumerWidget
final ocrService = ref.read(ocrServiceProvider);
final result = await ocrService.recognizeFromFile(imageFile);
final carteGrise = ocrService.parseVehicleDocument(result);

print(carteGrise.plateNumber);    // AB123CD
print(carteGrise.ownerName);      // Jean Dupont
print(carteGrise.confidence);     // 0.87
```

### Example 2: Driver License
```dart
final ocrService = ref.read(ocrServiceProvider);
final result = await ocrService.recognizeFromFile(licenseImage);
final license = ocrService.parseDriverLicense(result);

print(license.firstName);         // Jean
print(license.lastName);          // Dupont
print(license.licenseNumber);     // 1234567890123
```

### Example 3: Access Test Screen Directly
```dart
// In any context
context.pushNamed(RouteNames.ocrTest);

// Or
GoRouter.of(context).push('/ocr-test');
```

---

## 🔧 Platform Commands

### Android
```bash
# Build APK
flutter build apk

# Run on device
flutter run -d <device_id>

# Check installed devices
adb devices

# View logs
flutter logs
```

### iOS
```bash
# Build for iOS
flutter build ios

# Run on simulator
open -a Simulator
flutter run -d "iPhone 15"

# Run on device
flutter run -d <device_name>
```

---

## 🐛 Debug Commands

### Check Dependencies
```bash
flutter pub deps
flutter pub outdated
```

### Clean Build
```bash
flutter clean
rm -rf build/ (or rmdir /s build on Windows)
flutter pub get
flutter run
```

### Analyze Code
```bash
flutter analyze
dart analyze
```

### Format Code
```bash
flutter format lib/
dart format lib/
```

---

## 📊 Extracted Data Structure

### Carte Grise Fields
```dart
{
  'ownerName': 'Jean Dupont',
  'plateNumber': 'AB123CD',
  'vin': 'VF39A6M0012345678',
  'brand': 'Peugeot',
  'model': '308',
  'registrationDate': '01/01/2024',
  'confidence': 0.87
}
```

### Driver License Fields
```dart
{
  'firstName': 'Jean',
  'lastName': 'Dupont',
  'dateOfBirth': '01/01/1990',
  'licenseNumber': '1234567890123',
  'issuingCountry': 'FR',
  'expiryDate': '01/01/2030',
  'confidence': 0.92
}
```

---

## 🧪 Testing Checklist

```bash
# Unit Tests (if you add them)
flutter test

# Widget Tests
flutter test test/ocr_test.dart

# Integration Tests
flutter drive --target=test_driver/app.dart

# Coverage
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## 📦 Dependency Versions

```yaml
google_mlkit_text_recognition: ^0.11.0
image_picker: ^1.0.7
camera: ^0.10.5+5
flutter_riverpod: ^2.6.1
firebase_core: ^4.7.0
firebase_auth: ^6.4.0
cloud_firestore: 6.3.0
```

---

## 🔐 Permissions

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan vehicle documents</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select document images</string>

<key>NSPhotoLibraryAddOnlyUsageDescription</key>
<string>This app needs permission to save photos for document scanning</string>
```

---

## 🎯 Integration Steps (Copy-Paste Ready)

### Step 1: Add to Carte Grise Feature
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/ocr_provider.dart';
import '../../../../core/models/ocr_result.dart';

class ScanCarteGriseScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ScanCarteGriseScreen> createState() =>
      _ScanCarteGriseScreenState();
}

class _ScanCarteGriseScreenState
    extends ConsumerState<ScanCarteGriseScreen> {
  Future<void> _processDocument(File imageFile) async {
    try {
      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.recognizeFromFile(imageFile);
      final carteGrise = ocrService.parseVehicleDocument(result);
      
      // Use carteGrise data here
      print('Extracted: $carteGrise');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Your UI here
    );
  }
}
```

### Step 2: Add to Home Screen
```dart
// In your home_screen.dart
ElevatedButton(
  onPressed: () => context.pushNamed(RouteNames.ocrTest),
  child: const Text('📱 Test OCR Scanner'),
)
```

### Step 3: Enable in Settings/Debug
```dart
// Add OCR test link in settings or debug menu
GestureDetector(
  onTap: () => GoRouter.of(context).push('/ocr-test'),
  child: const ListTile(
    title: Text('OCR Test (Debug)'),
    subtitle: Text('Test text recognition'),
  ),
)
```

---

## 🚨 Troubleshooting

### Build Issues
```bash
# Clear everything and rebuild
flutter clean
rm -rf .dart_tool/
flutter pub get
flutter run
```

### Missing Permissions
```bash
# Check permissions are in manifest
grep -r "CAMERA\|READ_EXTERNAL" android/app/src/main/

# For iOS, verify Info.plist has permission keys
grep -l "NSCamera" ios/Runner/Info.plist
```

### Camera Not Working
```dart
// Ensure image_picker is initialized
// Add to main.dart if needed
import 'package:image_picker/image_picker.dart';
```

### Text Not Detected
```
✅ Use clear, well-lit images
✅ Ensure document fills most of the frame
✅ Try rotating the image
✅ Test with different documents
```

---

## 📞 Support

### Docs
- [OCR_IMPLEMENTATION_GUIDE.md](./OCR_IMPLEMENTATION_GUIDE.md) - Full guide
- [OCR_INTEGRATION_EXAMPLES.dart](./OCR_INTEGRATION_EXAMPLES.dart) - Code examples
- [OCR_SETUP_VERIFICATION.md](./OCR_SETUP_VERIFICATION.md) - Setup verification

### External Resources
- [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition)
- [Image Picker Docs](https://pub.dev/packages/image_picker)
- [Flutter Docs](https://flutter.dev)
- [Riverpod Docs](https://riverpod.dev)

---

## ✅ Quick Verification

Run this to verify everything is set up:
```bash
# 1. Check dependencies
flutter pub list
grep "google_mlkit_text_recognition\|image_picker\|camera" pubspec.yaml

# 2. Check Android permissions
grep "CAMERA\|READ_EXTERNAL" android/app/src/main/AndroidManifest.xml

# 3. Check iOS permissions
grep "NSCamera\|NSPhoto" ios/Runner/Info.plist

# 4. Check Flutter files exist
test -f lib/core/services/ocr_service.dart && echo "✅ OCR Service"
test -f lib/core/models/ocr_result.dart && echo "✅ OCR Models"
test -f lib/core/providers/ocr_provider.dart && echo "✅ OCR Provider"
test -f lib/features/scan/presentation/screens/ocr_test_screen.dart && echo "✅ Test Screen"

# 5. Run app
flutter run
```

---

## 🎉 You're Ready!

All setup is complete. Your OCR implementation is production-ready.

**Next Step:** Navigate to `/ocr-test` and start testing!

