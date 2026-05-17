import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../main.dart' show isFirebaseSupported;
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class NotificationsBellButton extends StatefulWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationsBellButton({
    super.key,
    this.iconColor,
    this.iconSize = 26,
  });

  @override
  State<NotificationsBellButton> createState() =>
      _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends State<NotificationsBellButton> {
  final FirestoreService _firestoreService = FirestoreService();

  User? get _user =>
      isFirebaseSupported ? FirebaseAuth.instance.currentUser : null;

  Future<void> _openNotifications(String uid) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng thông báo',
      barrierColor: Colors.black.withValues(alpha: 0.34),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _NotificationsDialog(uid: uid, firestoreService: _firestoreService),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconColor = widget.iconColor ?? c.textHeading;
    final user = _user;

    if (user == null) {
      return IconButton(
        onPressed: null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: Icon(
          Icons.notifications_none_rounded,
          color: iconColor.withValues(alpha: 0.45),
          size: widget.iconSize,
        ),
      );
    }

    return StreamBuilder<List<AppNotification>>(
      stream: _firestoreService.streamNotifications(user.uid),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AppNotification>[];
        final unreadCount = notifications.where((n) => !n.read).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => _openNotifications(user.uid),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                Icons.notifications_none_rounded,
                color: iconColor,
                size: widget.iconSize,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationsDialog extends StatelessWidget {
  final String uid;
  final FirestoreService firestoreService;

  const _NotificationsDialog({
    required this.uid,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: firestoreService.streamNotifications(uid),
      builder: (context, snapshot) {
        final c = context.colors;
        final size = MediaQuery.sizeOf(context);
        final notifications = snapshot.data ?? const <AppNotification>[];
        final unreadCount = notifications.where((n) => !n.read).length;
        final dialogWidth = size.width < 560 ? size.width - 32 : 520.0;
        final listHeight = (size.height * 0.58).clamp(280.0, 520.0);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: dialogWidth,
                  constraints: BoxConstraints(maxHeight: size.height - 48),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: c.surfaceBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: c.borderColor.withValues(alpha: 0.75),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Thông báo',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: c.textHeading,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: c.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (unreadCount > 0)
                            TextButton(
                              onPressed: () => firestoreService
                                  .markAllNotificationsRead(uid),
                              child: const Text('Đọc tất cả'),
                            ),
                          TextButton(
                            onPressed: notifications.isEmpty
                                ? null
                                : () async {
                                    await firestoreService
                                        .deleteAllNotifications(uid);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: const Text('Xóa tất cả'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (notifications.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              'Chưa có thông báo.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: c.textMuted),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: listHeight,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: notifications.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _NotificationTile(
                                notification: notifications[index],
                                firestoreService: firestoreService,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final FirestoreService firestoreService;

  const _NotificationTile({
    required this.notification,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = !notification.read;
    final darkBlue = c.accentBlueDeep;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (unread) firestoreService.markNotificationRead(notification.id);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread ? c.accentBlue.withValues(alpha: 0.06) : c.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread ? darkBlue : c.borderColor.withValues(alpha: 0.7),
            width: unread ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unread) ...[
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: darkBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Icon(
              notification.type == AppNotificationType.friendRequest
                  ? Icons.person_add_alt_1_rounded
                  : Icons.notifications_rounded,
              size: 22,
              color: unread ? darkBlue : c.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: c.textHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: c.textMuted),
                  ),
                  if (notification.type == AppNotificationType.friendRequest)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                _declineFriendRequest(context, notification),
                            child: const Text('Từ chối'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                _acceptFriendRequest(context, notification),
                            child: const Text('Chấp nhận'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Xóa',
              onPressed: () =>
                  firestoreService.deleteNotification(notification.id),
              icon: Icon(Icons.close_rounded, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptFriendRequest(
    BuildContext context,
    AppNotification notification,
  ) async {
    final connectionId = notification.data['connectionId']?.toString();
    if (connectionId == null || connectionId.isEmpty) return;
    await firestoreService.acceptConnectionRequest(connectionId);
    await firestoreService.markNotificationRead(notification.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận kết bạn.')));
  }

  Future<void> _declineFriendRequest(
    BuildContext context,
    AppNotification notification,
  ) async {
    final connectionId = notification.data['connectionId']?.toString();
    if (connectionId == null || connectionId.isEmpty) return;
    await firestoreService.declineConnectionRequest(connectionId);
    await firestoreService.deleteNotification(notification.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã từ chối lời mời.')));
  }
}
