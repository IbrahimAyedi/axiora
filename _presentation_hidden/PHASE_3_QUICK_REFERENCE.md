# Phase 3 Quick Reference: In-App Notifications

## What Was Added

### New Model
```dart
AppNotification
```
- Location: `lib/core/models/app_notification.dart`
- Fields: id, userId, type, title, body, constatId, read, createdAt
- JSON serialization support

### New Provider
```dart
NotificationsProvider
```
- Location: `lib/core/providers/notifications_provider.dart`
- Methods: loadNotifications(), markAsRead(), markAllAsRead(), createTestNotification()
- State: notifications list, isLoading, error, unreadCount

### New Screen
```dart
NotificationsScreen
```
- Location: `lib/features/notifications/presentation/screens/notifications_screen.dart`
- Features: list view, empty state, loading state, error state, mark as read, navigation

### Modified Files
- `lib/features/home/presentation/screens/home_screen.dart` - Added bell icon with badge
- `lib/app/router/app_router.dart` - Added notifications route
- `lib/app/router/route_names.dart` - Added notifications route constants

## How It Works

### Flow Diagram
```
App starts
    ↓
NotificationsProvider initializes
    ↓
Load notifications from Firestore
    ↓
Display unread count on Home bell icon
    ↓
User taps bell icon
    ↓
Navigate to Notifications screen
    ↓
Display notifications list
    ↓
User taps notification
    ↓
Mark as read
    ↓
Navigate to constat detail (if constatId exists)
```

## Firestore Structure

### Collection Path
```
users/{uid}/notifications/{notificationId}
```

### Document Structure
```json
{
  "id": "notification_abc123",
  "userId": "user_xyz789",
  "type": "info",
  "title": "Notification Title",
  "body": "Notification body text",
  "constatId": "constat_123",
  "read": false,
  "createdAt": "2026-05-08T10:00:00Z"
}
```

### Notification Types
- `info` - General information (default)
- `success` - Success messages
- `warning` - Warning messages
- `error` - Error messages
- `constat` - Constat-related notifications

## Key Features

### Bell Icon with Badge
- Location: Home screen app bar
- Shows unread count
- Red badge for visibility
- Displays "9+" for 10+ notifications
- Tappable to open notifications screen

### Notifications Screen
- Lists all notifications (newest first)
- Visual distinction for unread notifications
- Tap to mark as read and navigate
- "Mark all read" button (if unread exist)
- Empty state for no notifications
- Loading and error states

### Mark as Read
- **Single:** Tap notification
- **All:** Tap "Mark all read" button
- Updates Firestore and local state
- Badge updates automatically

### Navigation
- If notification has constatId → navigate to constat detail
- If no constatId → just mark as read
- Graceful handling of invalid constatIds

## Code Examples

### Load Notifications
```dart
final notificationsState = ref.watch(notificationsProvider);
final unreadCount = notificationsState.unreadCount;
final notifications = notificationsState.notifications;
```

### Mark Notification as Read
```dart
await ref
    .read(notificationsProvider.notifier)
    .markAsRead(notificationId);
```

### Mark All as Read
```dart
await ref
    .read(notificationsProvider.notifier)
    .markAllAsRead();
```

### Create Test Notification (Dev Helper)
```dart
await ref
    .read(notificationsProvider.notifier)
    .createTestNotification(constatId: 'constat_123');
```

### Navigate to Notifications Screen
```dart
context.push(RouteNames.notificationsPath);
```

### Navigate to Constat Detail from Notification
```dart
if (notification.constatId != null) {
  context.push(RouteNames.constatDetailPath(notification.constatId!));
}
```

## Testing Checklist

- [ ] Bell icon visible on Home screen
- [ ] Badge shows correct unread count
- [ ] Badge disappears when all read
- [ ] Notifications screen opens from bell icon
- [ ] Empty state displays correctly
- [ ] Notifications list displays correctly
- [ ] Unread notifications visually distinct
- [ ] Tap notification marks as read
- [ ] Tap notification navigates to constat (if constatId exists)
- [ ] "Mark all read" button works
- [ ] Badge updates after marking as read
- [ ] Notifications persist across app restarts
- [ ] Dark mode displays correctly
- [ ] Loading state displays correctly
- [ ] Error state displays correctly with retry

## Common Issues & Solutions

### Issue: Badge not showing
**Solution:** Check if notifications are loaded. Verify Firestore permissions. Check if unreadCount > 0.

### Issue: Notifications not loading
**Solution:** Check Firestore permissions. Verify user is authenticated. Check network connection. Look for errors in console.

### Issue: Mark as read not working
**Solution:** Check Firestore write permissions. Verify user is authenticated. Check network connection.

### Issue: Navigation not working
**Solution:** Verify constatId exists in notification. Check if constat exists in Firestore. Verify route is defined.

### Issue: Badge count incorrect
**Solution:** Reload notifications. Check Firestore data. Verify read field is boolean.

## Firestore Security Rules

Add these rules to your Firestore security rules:

```javascript
match /users/{userId}/notifications/{notificationId} {
  // Users can read their own notifications
  allow read: if request.auth != null && request.auth.uid == userId;
  
  // Users can update their own notifications (mark as read)
  allow update: if request.auth != null 
                && request.auth.uid == userId
                && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
  
  // Users can create their own notifications (for testing)
  allow create: if request.auth != null && request.auth.uid == userId;
  
  // Users can delete their own notifications (future feature)
  allow delete: if request.auth != null && request.auth.uid == userId;
}
```

## Creating Notifications

### Manual (Firestore Console)
1. Navigate to Firestore console
2. Go to `users/{uid}/notifications`
3. Add document with auto-generated ID
4. Set fields: type, title, body, constatId (optional), read: false, createdAt: timestamp

### Programmatic (Dev Helper)
```dart
await ref
    .read(notificationsProvider.notifier)
    .createTestNotification(constatId: 'optional_constat_id');
```

### Future (Server-Side)
- Cloud Functions triggered by events
- Admin SDK to create notifications
- Scheduled notifications
- Batch notifications

## Performance Considerations

- **Firestore Reads:** 1 read per notification on load
- **Firestore Writes:** 1 write per mark as read, batch write for mark all
- **Local State:** Notifications cached in provider state
- **UI Updates:** Reactive updates via Riverpod
- **Network Calls:** Only on load and mark as read operations

## Limitations

- No real-time updates (requires manual refresh)
- No pagination (all notifications loaded at once)
- No push notifications (FCM not implemented)
- No notification actions (delete, archive)
- No notification filtering or search
- No offline support

## Future Enhancements

- Firebase Cloud Messaging (FCM) for push notifications
- Real-time updates using Firestore listeners
- Pagination for large notification lists
- Notification actions (delete, archive, snooze)
- Notification filtering and search
- Offline support with local caching
- Notification preferences and settings
- Accept/reject approval workflow (Phase 4)

## Support

For questions or issues:
1. Check `PHASE_3_IMPLEMENTATION_REPORT.md` for detailed documentation
2. Review test scenarios for expected behavior
3. Check Firestore console for data verification
4. Review flutter analyze output for code issues
5. Check provider state for debugging

## Phase 4 Preview

Phase 4 will add:
- Accept/reject approval workflow
- Notification actions (approve/reject buttons)
- Approval request notifications
- Approval status tracking
- Real-time approval updates
- Approval history
