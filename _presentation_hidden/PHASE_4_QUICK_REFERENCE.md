# Phase 4 Quick Reference: Approval Workflow

## Overview
Basic approval workflow between two users using insurance numbers.

---

## Data Model

### Constat Approval Fields
```dart
final String approvalStatus; // 'none', 'pending', 'accepted', 'rejected'
final String? approvalRequestedToUid;
final String? approvalRequestedToInsuranceNumber;
final DateTime? approvalRequestedAt;
final DateTime? approvalRespondedAt;
final String? approvalResponse; // 'accepted' or 'rejected'
```

---

## Key Methods

### 1. Create Approval Request
**File**: `lib/core/providers/app_session_provider.dart`

```dart
Future<void> createApprovalRequestIfPossible(Constat constat)
```

**Called by**: `submitConstat()` after submission

**Logic**:
1. Extract insurance number from constat
2. Check if insurance number belongs to current user (skip if true)
3. Lookup target user via `insurance_users/{insuranceNumber}`
4. Update constat with approval fields
5. Create notification for target user

**Edge Cases**:
- No insurance number → Skip
- Self-request → Skip
- User not found → Skip
- Firestore error → Log, don't crash

---

### 2. Respond to Approval
**File**: `lib/core/providers/app_session_provider.dart`

```dart
Future<bool> respondToConstatApproval({
  required String constatId,
  required bool accepted,
})
```

**Returns**: `true` if successful, `false` otherwise

**Validation**:
- Constat exists
- Current user is the requested approver
- Status is pending

**Updates**:
- `approvalStatus` → 'accepted' or 'rejected'
- `approvalResponse` → 'accepted' or 'rejected'
- `approvalRespondedAt` → now

---

## UI Components

### Approval Status Banner
**File**: `lib/features/history/presentation/screens/constat_detail_screen.dart`

**Widget**: `_ApprovalStatusBanner`

**Status Colors**:
- Pending: Orange
- Accepted: Green
- Rejected: Red

**Dark Mode**: All colors adapt automatically

---

### Accept/Reject Buttons

**Visibility**:
```dart
if (constat.approvalStatus == 'pending' &&
    constat.approvalRequestedToUid == session.currentUser.id)
```

**Handler**: `_handleApprovalResponse(context, ref, constatId, accepted: bool)`

---

## Firestore Structure

### Constat Document
**Path**: `users/{userId}/constats/{constatId}`

```json
{
  "approvalStatus": "pending",
  "approvalRequestedToUid": "user_123",
  "approvalRequestedToInsuranceNumber": "INS-2026-0002",
  "approvalRequestedAt": "2026-05-08T10:30:00Z",
  "approvalRespondedAt": null,
  "approvalResponse": null
}
```

### Notification Document
**Path**: `users/{targetUid}/notifications/{notificationId}`

```json
{
  "id": "notification_...",
  "type": "constat_request",
  "title": "New constat request",
  "body": "A constat is waiting for your review.",
  "constatId": "constat_...",
  "read": false,
  "createdAt": "timestamp"
}
```

---

## User Flow

1. **User A** submits constat with User B's insurance number
2. **System** creates approval request and notification
3. **User B** receives notification
4. **User B** taps notification → Constat detail screen
5. **User B** sees pending banner and Accept/Reject buttons
6. **User B** taps Accept or Reject
7. **System** updates constat and shows success message
8. **User A** sees updated approval status

---

## Testing Commands

```bash
# Format changed files
dart format lib/core/models/constat.dart lib/core/providers/app_session_provider.dart lib/features/history/presentation/screens/constat_detail_screen.dart lib/features/notifications/presentation/screens/notifications_screen.dart

# Analyze
flutter analyze

# Run app
flutter run
```

---

## Common Issues

### Issue: Approval request not created
**Check**:
1. Insurance number exists in `insuranceSnapshot`
2. Insurance number is not current user's
3. Target user exists in `insurance_users` collection
4. No Firestore errors in logs

### Issue: Accept/Reject buttons not showing
**Check**:
1. `approvalStatus == 'pending'`
2. `approvalRequestedToUid == currentUser.id`
3. User is viewing the correct constat

### Issue: Old constats crashing
**Check**:
1. `fromJson` has default values for approval fields
2. `approvalStatus` defaults to `'none'`
3. UI checks `if (constat.approvalStatus != 'none')`

---

## Files Changed

1. `lib/core/models/constat.dart` - Added approval fields
2. `lib/core/providers/app_session_provider.dart` - Added approval methods
3. `lib/features/history/presentation/screens/constat_detail_screen.dart` - Added approval UI
4. `lib/features/notifications/presentation/screens/notifications_screen.dart` - Added constat_request type

---

**End of Quick Reference**
