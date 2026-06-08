# Phase 2 Quick Reference: Insurance Number Profile Sync

## What Was Added

### New Method in AppSessionProvider
```dart
Future<bool> updateProfileInsuranceNumber(String newInsuranceNumber)
```
- Updates user profile insurance number
- Manages Firestore `insurance_users` lookup collection
- Returns `true` on success, `false` if number already taken
- Handles duplicate prevention and old lookup cleanup

### New Widget
```dart
InsuranceNumberUpdateDialog
```
- Location: `lib/core/widgets/insurance_number_update_dialog.dart`
- Reusable confirmation dialog for insurance number updates
- Shows current vs scanned number
- Dark mode compatible

### Modified Screen
```dart
InsuranceInfoScreen
```
- Added `_maybePromptProfileInsuranceUpdate()` method
- Added `_updateProfileInsuranceNumber()` method
- Prompts user after OCR scan if insurance number detected

## How It Works

### Flow Diagram
```
User scans assurance
    ↓
OCR extracts insurance number
    ↓
Form fields autofilled (existing behavior)
    ↓
Check profile insurance number
    ↓
┌─────────────────────────────────────────┐
│ Case 1: Profile has no number          │
│ → Show "Save to profile?" dialog        │
│ → On confirm: Create lookup, update     │
├─────────────────────────────────────────┤
│ Case 2: Profile matches scanned        │
│ → Show "matches" SnackBar               │
│ → No dialog                             │
├─────────────────────────────────────────┤
│ Case 3: Profile differs from scanned   │
│ → Show "Update?" dialog with warning    │
│ → On confirm: Check duplicate           │
│   → If duplicate: Show error            │
│   → If free: Update, cleanup old lookup │
├─────────────────────────────────────────┤
│ Case 4: OCR didn't detect number       │
│ → No dialog                             │
│ → Form autofill continues normally      │
└─────────────────────────────────────────┘
```

## Firestore Structure

### users/{uid}
```json
{
  "insuranceNumber": "INS-2026-0001",
  "fullName": "John Doe",
  "email": "john@example.com",
  "phone": "+216 12 345 678",
  ...
}
```

### insurance_users/{insuranceNumber}
```json
{
  "uid": "user123",
  "fullName": "John Doe",
  "email": "john@example.com",
  "phone": "+216 12 345 678",
  "createdAt": "2026-05-08T10:00:00Z",
  "updatedAt": "2026-05-08T10:00:00Z"
}
```

## Key Business Rules

1. **User Confirmation Required:** Never silently update profile
2. **Duplicate Prevention:** Check `insurance_users` before updating
3. **Ownership Verification:** Only delete old lookup if owned by current user
4. **Form Autofill Preserved:** OCR still fills form regardless of profile update
5. **Graceful Degradation:** Errors don't crash app, show user-friendly messages

## Testing Checklist

- [ ] New user scans assurance → saves to profile
- [ ] Existing user scans matching number → shows "matches" message
- [ ] Existing user scans different number → updates with confirmation
- [ ] User tries to use already-registered number → shows error
- [ ] OCR doesn't detect number → no dialog, form works normally
- [ ] Network failure during update → shows error, doesn't crash
- [ ] Dark mode → dialog displays correctly
- [ ] Profile screen → shows updated insurance number

## Common Issues & Solutions

### Issue: Dialog not appearing after OCR scan
**Solution:** Check if `insuranceNumber` field is null in OCR result. Dialog only appears if number is detected.

### Issue: "Insurance number already registered" error
**Solution:** This is expected behavior. The number is already linked to another user. User must use a different number.

### Issue: Old lookup not deleted
**Solution:** Check if old lookup belongs to current user. Cleanup only happens if `uid` matches.

### Issue: Profile not updating
**Solution:** Check Firestore permissions. Ensure user has write access to `users/{uid}` and `insurance_users/{number}`.

## Code Examples

### Calling the update method
```dart
final success = await ref
    .read(appSessionProvider.notifier)
    .updateProfileInsuranceNumber('INS-2026-0001');

if (success) {
  // Show success message
} else {
  // Show "already registered" error
}
```

### Showing the dialog
```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => InsuranceNumberUpdateDialog(
    currentInsuranceNumber: 'INS-2026-0001', // or null
    scannedInsuranceNumber: 'INS-2026-0002',
  ),
);

if (confirmed == true) {
  // User confirmed, proceed with update
}
```

## Files Modified

1. `lib/core/providers/app_session_provider.dart` - Added update method
2. `lib/core/widgets/insurance_number_update_dialog.dart` - New dialog widget
3. `lib/features/constat/presentation/screens/insurance_info_screen.dart` - Added prompt logic

## Files NOT Modified (Confirmed Intact)

- `lib/core/services/ocr_service.dart` - OCR parsers unchanged
- `lib/core/mlkit/text_recognition_service.dart` - ML Kit unchanged
- `lib/features/constat/presentation/screens/driver_info_screen.dart` - Driver flow unchanged
- `lib/features/constat/presentation/screens/vehicle_info_screen.dart` - Vehicle flow unchanged
- `lib/features/constat/presentation/screens/photos_damage_screen.dart` - Damage detection unchanged

## Performance Considerations

- **Firestore Reads:** 1-2 reads per insurance number update (check duplicate, check old lookup)
- **Firestore Writes:** 2-3 writes per update (user doc, new lookup, delete old lookup)
- **Network Calls:** All Firestore operations are async, non-blocking
- **Local State:** Updated immediately after Firestore success
- **UI Responsiveness:** Dialog and SnackBars provide immediate feedback

## Security Notes

- Insurance number can only be updated by authenticated user
- Duplicate prevention ensures one number = one user
- Old lookup cleanup prevents orphaned data
- No admin override (by design for Phase 2)
- All Firestore operations respect security rules

## Future Enhancements (Not in Phase 2)

- Insurance number format validation
- Insurance company verification
- Policy expiry tracking
- Multiple insurance profiles
- Audit logging
- Admin override capability
- Undo functionality
- Change history

## Support

For questions or issues:
1. Check `PHASE_2_IMPLEMENTATION_REPORT.md` for detailed documentation
2. Review test scenarios for expected behavior
3. Check Firestore console for data verification
4. Review flutter analyze output for code issues
