import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _practiceHourKey = 'practice_reminder_hour';
  static const String _practiceMinuteKey = 'practice_reminder_minute';
  static const String _practiceEnabledKey = 'practice_reminder_enabled';

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final iOSPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iOSPlugin != null) {
      final bool? granted = await iOSPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final bool? granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  Future<void> scheduleDailyReminder(bool enabled) async {
    if (kIsWeb || !_initialized) return;

    await cancelAllNotifications();

    if (!enabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily practice reminders to keep your streak',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Time to Practice!',
      body: 'Keep your streak alive. Spend 5 minutes practicing today.',
      scheduledDate: _nextInstanceOf8PM(),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a notification 5 minutes before the user's chosen practice time.
  Future<void> scheduleAtUserTime(TimeOfDay time) async {
    if (kIsWeb || !_initialized) return;

    // Persist the chosen time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_practiceHourKey, time.hour);
    await prefs.setInt(_practiceMinuteKey, time.minute);
    await prefs.setBool(_practiceEnabledKey, true);

    await cancelAllNotifications();

    // Fire 5 minutes before the user's chosen time
    int reminderHour = time.hour;
    int reminderMinute = time.minute - 5;
    if (reminderMinute < 0) {
      reminderMinute += 60;
      reminderHour = (reminderHour - 1) % 24;
    }

    const platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'practice_reminder_channel',
        'Practice Reminders',
        channelDescription: 'Reminds you before your scheduled practice time',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, reminderHour, reminderMinute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1,
      title: 'Practice time in 5 minutes! ⏰',
      body: 'Get ready for your speaking practice session.',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Get the saved practice time, or null if not set.
  Future<TimeOfDay?> getSavedPracticeTime() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_practiceEnabledKey) ?? false;
    if (!enabled) return null;
    final hour = prefs.getInt(_practiceHourKey);
    final minute = prefs.getInt(_practiceMinuteKey);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Cancel the user's scheduled practice reminder.
  Future<void> cancelPracticeReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_practiceEnabledKey, false);
    if (kIsWeb || !_initialized) return;
    await _flutterLocalNotificationsPlugin.cancel(id: 1);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || !_initialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOf8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20); // 8 PM
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
