import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import 'app_session_provider.dart';

// provider mte3 notifications
// fih liste notifications, loading w error
final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );

// state mte3 notifications screen
class NotificationsState {
  const NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.error,
  });

  // liste mte3 notifications
  final List<AppNotification> notifications;

  // true waqt app tloadi notifications
  final bool isLoading;

  // message erreur ken fama problem
  final String? error;

  // nombre mte3 notifications non lues
  int get unreadCount =>
      notifications.where((notification) => !notification.read).length;

  // copyWith ta3mel state jdida m3a changement mte3 fields mou3ayna
  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

// valeur speciala bech nfar9ou bin error ma tbadalch w error=null
const _unset = Object();

// controller mte3 notifications
class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  // build tet3ayyet ki provider yabda
  // tloadi notifications ken user connecte
  NotificationsState build() {
    // nwatchiw auth state bech provider يتعاود يبني rou7ou ki user yetbadel
    final authAsync = ref.watch(firebaseAuthUserProvider);
    final authUser =
        authAsync.asData?.value ?? FirebaseAuth.instance.currentUser;

    debugPrint(
      'NotificationsNotifier.build() — uid: ${authUser?.uid ?? 'null'}',
    );

    // ki provider يتنحى, nprintiw debug message
    ref.onDispose(() {
      debugPrint('NotificationsNotifier disposed (uid: ${authUser?.uid})');
    });

    // ken fama user connecte, nloadiw notifications mte3ou
    if (authUser != null) {
      Future.microtask(() async {
        debugPrint(
          '[Notifications] Starting async load for uid=${authUser.uid}',
        );
        await loadNotifications();
      });
    }

    // initial state
    return NotificationsState(
      notifications: const <AppNotification>[],
      isLoading: authUser != null,
    );
  }

  // tloadi notifications mel Firestore
  Future<void> loadNotifications() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      debugPrint('[Notifications] loadNotifications: no authenticated user');
      state = state.copyWith(isLoading: false);
      return;
    }

    // path mte3 notifications fi Firestore
    final queryPath = 'users/${authUser.uid}/notifications';
    debugPrint(
      '[Notifications] loadNotifications — uid=${authUser.uid}, path=$queryPath',
    );

    try {
      // njibou notifications mte3 current user, sorted by createdAt
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint(
        '[Notifications] Firestore returned ${snapshot.docs.length} doc(s) from $queryPath',
      );

      // n7awlou Firestore docs l AppNotification models
      final loadedNotifications = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              final notif = AppNotification.fromJson({'id': doc.id, ...data});
              debugPrint(
                '[Notifications]   id=${notif.id} type=${notif.type} read=${notif.read} constatId=${notif.constatId}',
              );
              return notif;
            } catch (e) {
              debugPrint('[Notifications]   parse error for ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();

      // n7sbou notifications non lues
      final unreadCount = loadedNotifications.where((n) => !n.read).length;
      debugPrint(
        '[Notifications] Loaded ${loadedNotifications.length} notification(s), $unreadCount unread',
      );

      // nupdatew state
      state = state.copyWith(
        notifications: loadedNotifications,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Notifications] Error loading from $queryPath: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications',
      );
    }
  }

  // tmarki notification wa7da comme read
  Future<void> markAsRead(String notificationId) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      debugPrint('Cannot mark notification as read: no authenticated user');
      return;
    }

    try {
      // nupdatew Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      // nupdatew local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(read: true);
        }
        return notification;
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);

      debugPrint('Marked notification $notificationId as read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // tmarki kol notifications comme read
  Future<void> markAllAsRead() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      debugPrint(
        'Cannot mark all notifications as read: no authenticated user',
      );
      return;
    }

    try {
      // batch yupdate barcha documents f mara wa7da
      final batch = FirebaseFirestore.instance.batch();

      // njibou notifications eli mazalou unread
      final unreadNotifications = state.notifications.where(
        (notification) => !notification.read,
      );

      // nzidou updates lel batch
      for (final notification in unreadNotifications) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .collection('notifications')
            .doc(notification.id);
        batch.update(docRef, {'read': true});
      }

      // ncommit batch
      await batch.commit();

      // nupdatew local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(read: true);
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);

      debugPrint('Marked all notifications as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Dev/test helper: Create a sample notification
  // function mte3 dev/test bech ncreatew notification test
  Future<void> createTestNotification({String? constatId}) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      debugPrint('Cannot create test notification: no authenticated user');
      return;
    }

    try {
      final now = DateTime.now();

      // doc jdida fi notifications mte3 current user
      final notificationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .collection('notifications')
          .doc();

      // notification test
      final notification = AppNotification(
        id: notificationRef.id,
        userId: authUser.uid,
        type: 'info',
        title: 'Test Notification',
        body: 'This is a test notification created for development purposes.',
        constatId: constatId,
        read: false,
        createdAt: now,
      );

      // nsajlou notification fi Firestore
      await notificationRef.set(notification.toJson());

      // n3awdou nloadiw notifications
      await loadNotifications();

      debugPrint('Created test notification: ${notification.id}');
    } catch (e) {
      debugPrint('Error creating test notification: $e');
    }
  }
}
