import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';
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
  final List<_BellNotification> _notifications = [
    _BellNotification(
      title: 'Daily practice reminder',
      body: 'Spend a few minutes speaking today to keep your streak.',
    ),
    _BellNotification(
      title: 'Guided speaking tip',
      body: 'Try a short guided scenario to warm up your voice.',
    ),
  ];

  Timer? _incomingTimer;

  @override
  void initState() {
    super.initState();
    // Mock "incoming" notifications while the user has not opened the list.
    // This lets the badge increase if the user hasn't viewed notifications yet.
    _incomingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      if (_notifications.any((n) => !n.read)) {
        setState(() {
          _notifications.insert(
            0,
            _BellNotification(
              title: 'New practice idea',
              body: 'Pick a daily scenario and speak for 2 minutes.',
            ),
          );
          if (_notifications.length > 15) {
            _notifications.removeRange(15, _notifications.length);
          }
        });
      } else {
        // If everything is read, don't keep adding noise.
      }
    });
  }

  @override
  void dispose() {
    _incomingTimer?.cancel();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> _openNotifications() async {
    final messenger = ScaffoldMessenger.of(context);

    final granted = await NotificationService().requestPermissions();
    if (!mounted) return;

    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification permission is required.')),
      );
      // Even if OS notifications are not granted, still show in-app notifications.
    }

    await NotificationService().scheduleDailyReminder(true);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final c = context.colors;
        final sheetHeight = MediaQuery.of(context).size.height * 0.45;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: c.textHeading,
                          ),
                    ),
                    if (_unreadCount > 0)
                      Text(
                        _unreadCount > 9 ? '9+' : '$_unreadCount new',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.accentBlue,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_notifications.isEmpty)
                  Text(
                    'No notifications yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: c.textMuted,
                        ),
                  )
                else
                  SizedBox(
                    height: sheetHeight,
                    child: ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: n.read
                                ? c.cardBg
                                : c.accentBlue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.borderColor.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                n.read
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_active_rounded,
                                size: 22,
                                color:
                                    n.read ? c.textMuted : c.accentBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: c.textHeading,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: c.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconColor = widget.iconColor ?? c.textHeading;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _openNotifications,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            Icons.notifications_none_rounded,
            color: iconColor,
            size: widget.iconSize,
          ),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
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
  }
}

class _BellNotification {
  final String title;
  final String body;
  bool read = false;

  _BellNotification({
    required this.title,
    required this.body,
  });
}

