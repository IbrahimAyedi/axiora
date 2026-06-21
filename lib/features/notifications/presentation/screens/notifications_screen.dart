import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/providers/notifications_provider.dart';
import '../../../../core/widgets/app_button.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            Text(
              notificationsState.unreadCount > 0
                  ? '${notificationsState.unreadCount} unread'
                  : 'All caught up',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (notificationsState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: notificationsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notificationsState.error != null
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        notificationsState.error!,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Retry',
                        icon: Icons.refresh,
                        onPressed: () {
                          ref
                              .read(notificationsProvider.notifier)
                              .loadNotifications();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : notificationsState.notifications.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surface
                              : const Color(0xFFF3F6FB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No notifications yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see updates about your constats here.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: notificationsState.notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = notificationsState.notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () =>
                        _handleNotificationTap(context, ref, notification),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.read) {
      await ref
          .read(notificationsProvider.notifier)
          .markAsRead(notification.id);
    }

    if (notification.constatId != null &&
        notification.constatId!.isNotEmpty &&
        context.mounted) {
      context.push(
        RouteNames.constatDetailPath(
          notification.constatId!,
          ownerUid: notification.ownerUid,
        ),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.read;

    final cardColor = isDark
        ? isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface
        : isUnread
        ? const Color(0xFFF3F6FB)
        : Colors.white;

    final borderColor = isDark
        ? isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.3)
        : isUnread
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : const Color(0xFFD7E0EA);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(
                    notification.type,
                    isDark,
                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type, isDark),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'constat':
        return Icons.assignment_outlined;
      case 'constat_request':
        return Icons.assignment_outlined;
      case 'constat_response':
        return Icons.check_circle_outline;
      case 'admin_approval':
        return Icons.verified_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor(String type, bool isDark) {
    switch (type) {
      case 'success':
        return isDark ? const Color(0xFF81C784) : AppColors.success;
      case 'warning':
        return isDark ? const Color(0xFFFFB74D) : AppColors.warning;
      case 'error':
        return isDark ? const Color(0xFFEF9A9A) : AppColors.error;
      case 'constat':
        return isDark ? const Color(0xFF64B5F6) : AppColors.trustBlue;
      case 'constat_request':
        return isDark ? const Color(0xFF64B5F6) : AppColors.trustBlue;
      case 'constat_response':
        return isDark ? const Color(0xFF81C784) : AppColors.success;
      case 'admin_approval':
        return isDark ? const Color(0xFF38BDF8) : AppColors.primary;
      default:
        return isDark ? const Color(0xFFB0BEC5) : AppColors.textSecondary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
