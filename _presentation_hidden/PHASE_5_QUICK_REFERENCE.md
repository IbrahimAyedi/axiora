# Phase 5 Quick Reference: Two-Party Completion

## Overview
Party B must complete their driver, vehicle, and insurance information before accepting a constat.

---

## Data Model

### Constat Party B Fields
```dart
final Map<String, dynamic>? partyBDriverSnapshot;
final Map<String, dynamic>? partyBVehicleSnapshot;
final Map<String, dynamic>? partyBInsuranceSnapshot;
final DateTime? partyBCompletedAt;
final String? partyBCompletedByUid;
```

---

## Key Methods

### 1. Check Completion
**File**: `lib/core/providers/app_session_provider.dart`

```dart
bool isPartyBInfoComplete(Constat constat)
```

**Validates**:
- Driver: fullName and licenseNumber not empty
- Vehicle: plateNumber and brand not empty
- Insurance: insuranceNumber and companyName not empty

---

### 2. Save Party B Driver Info
```dart
Future<bool> savePartyBDriverInfo({
  required String constatId,
  required String fullName,
  required String licenseNumber,
  required String nationalId,
  required String phoneNumber,
})
```

---

### 3. Save Party B Vehicle Info
```dart
Future<bool> savePartyBVehicleInfo({
  required String constatId,
  required String plateNumber,
  required String brand,
  required String model,
  required String vin,
})
```

---

### 4. Save Party B Insurance Info
```dart
Future<bool> savePartyBInsuranceInfo({
  required String constatId,
  required String insuranceNumber,
  required String companyName,
  required String policyHolderName,
  required String policyType,
})
```

**Note**: This method also marks completion with `partyBCompletedAt` and `partyBCompletedByUid`.

---

### 5. Modified Accept Validation
```dart
Future<bool> respondToConstatApproval({
  required String constatId,
  required bool accepted,
})
```

**Added Check**:
```dart
if (accepted && !isPartyBInfoComplete(constat)) {
  return false; // Cannot accept without Party B info
}
```

---

## UI Components

### Party B Completion Section
**File**: `lib/features/history/presentation/screens/constat_detail_screen.dart`

**Visibility**:
```dart
if (constat.approvalStatus == 'pending' &&
    constat.approvalRequestedToUid == session.currentUser.id)
```

**Components**:
- Blue info banner
- Completion status (checkmarks)
- "Complete my information" button

---

### Party B Info Screen
**File**: `lib/features/history/presentation/screens/party_b_info_screen.dart`

**Route**: `/history/constat/{id}/party-b-info`

**Sections**:
1. Driver Information (Permis OCR)
2. Vehicle Information (Carte Grise OCR)
3. Insurance Information (Assurance OCR)

**OCR Methods**:
- `_scanPermis()` - Reuses `parseDriverLicense()`
- `_scanCarteGrise()` - Reuses `parseVehicleDocument()`
- `_scanAssurance()` - Reuses `parseInsuranceDocument()`

---

## Firestore Structure

### Party B Snapshots
```json
{
  "partyBDriverSnapshot": {
    "fullName": "Mohamed Ben Ali",
    "licenseNumber": "DL-123456",
    "nationalId": "12345678",
    "phoneNumber": "+216 12 345 678"
  },
  "partyBVehicleSnapshot": {
    "plateNumber": "123 TUN 456",
    "brand": "Peugeot",
    "model": "208",
    "vin": "VF3XXXXXXXXXXXX"
  },
  "partyBInsuranceSnapshot": {
    "insuranceNumber": "INS-2026-0002",
    "companyName": "STAR Assurances",
    "policyHolderName": "Mohamed Ben Ali",
    "policyType": "Auto"
  },
  "partyBCompletedAt": "2026-05-08T14:30:00Z",
  "partyBCompletedByUid": "user_456"
}
```

---

## User Flow

1. **User B** receives notification
2. **User B** opens constat detail
3. **User B** sees "Complete your information" section
4. **User B** taps "Complete my information"
5. **System** navigates to Party B Info screen
6. **User B** scans permis, carte grise, assurance
7. **User B** taps "Save and return"
8. **System** saves all info and marks completion
9. **User B** returns to constat detail
10. **User B** sees completion checkmarks
11. **User B** taps Accept (now functional)
12. **System** validates completion and accepts constat

---

## Validation Rules

### Accept Button
- **Enabled**: Only if `isPartyBInfoComplete()` returns true
- **Disabled**: Shows orange SnackBar with message

### Reject Button
- **Always Enabled**: No Party B info required

### Completion Status
- **Driver**: ✅ if fullName and licenseNumber exist
- **Vehicle**: ✅ if plateNumber and brand exist
- **Insurance**: ✅ if insuranceNumber and companyName exist

---

## Testing Commands

```bash
# Format changed files
dart format lib/core/models/constat.dart lib/core/providers/app_session_provider.dart lib/features/history/presentation/screens/constat_detail_screen.dart lib/features/history/presentation/screens/party_b_info_screen.dart lib/app/router/app_router.dart

# Analyze
flutter analyze

# Run app
flutter run
```

---

## Common Issues

### Issue: Accept button not working
**Check**:
1. Party B info is complete (all three sections)
2. Current user is `approvalRequestedToUid`
3. Approval status is "pending"

### Issue: Completion status not updating
**Check**:
1. All three save methods called successfully
2. Firestore write succeeded
3. Screen refreshed after save

### Issue: OCR not filling fields
**Check**:
1. OCR service provider is available
2. Image quality is good
3. Document type matches scan button

---

## Files Changed

1. `lib/core/models/constat.dart` - Added Party B fields
2. `lib/core/providers/app_session_provider.dart` - Added Party B methods
3. `lib/features/history/presentation/screens/constat_detail_screen.dart` - Added Party B UI
4. `lib/app/router/app_router.dart` - Added Party B route

## Files Created

1. `lib/features/history/presentation/screens/party_b_info_screen.dart` - Party B completion screen

---

**End of Quick Reference**
