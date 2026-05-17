import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

enum AppNotificationMode { sound, vibrate, silent }

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
  static const String _notificationsEnabledKey =
      'profile_notifications_enabled';
  static const String _notificationModeKey = 'notification_alert_mode';
  static const String _legacyPracticeNotificationModeKey =
      'practice_notification_mode';

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

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await _createAndroidNotificationChannels(androidPlugin);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final iOSPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
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
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final bool? granted = await androidPlugin
          .requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
      return granted ?? false;
    }

    return true;
  }

  Future<void> scheduleDailyReminder(bool enabled) async {
    if (kIsWeb || !_initialized) return;

    await _flutterLocalNotificationsPlugin.cancel(id: 0);

    if (!enabled || !await areNotificationsEnabled()) return;
    final mode = await getNotificationMode();

    await _zonedScheduleNotification(
      id: 0,
      title: 'Time to Practice!',
      body:
          'Your SpeechUp session is ready. Spend at least 5 focused minutes speaking today to keep your streak active and improve your weekly progress.',
      scheduledDate: _nextInstanceOf8PM(),
      notificationDetails: _notificationDetails(mode),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;
    if (!await areNotificationsEnabled()) return;

    final mode = await getNotificationMode();

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(mode),
    );
  }

  /// Schedule a notification at the user's chosen practice time.
  Future<bool> scheduleAtUserTime(TimeOfDay time) async {
    final notificationMode = await getNotificationMode();

    // Persist the chosen time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_practiceHourKey, time.hour);
    await prefs.setInt(_practiceMinuteKey, time.minute);
    await prefs.setBool(_practiceEnabledKey, true);

    if (kIsWeb || !_initialized) return false;

    await _flutterLocalNotificationsPlugin.cancel(id: 1);
    if (!await areNotificationsEnabled()) return false;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _zonedScheduleNotification(
      id: 1,
      title: 'Nhắc lịch tập luyện',
      body: 'Đến giờ tập luyện của bạn rồi.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(notificationMode),
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
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

  Future<AppNotificationMode> getNotificationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode =
        prefs.getString(_notificationModeKey) ??
        prefs.getString(_legacyPracticeNotificationModeKey);
    return AppNotificationMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => AppNotificationMode.sound,
    );
  }

  Future<void> setNotificationMode(AppNotificationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationModeKey, mode.name);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    if (!enabled && !kIsWeb && _initialized) {
      await _flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  /// Cancel the user's scheduled practice reminder.
  Future<void> cancelPracticeReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_practiceEnabledKey, false);
    if (kIsWeb || !_initialized) return;
    await _flutterLocalNotificationsPlugin.cancel(id: 1);
  }

  NotificationDetails _notificationDetails(AppNotificationMode mode) {
    final playSound = mode == AppNotificationMode.sound;
    final enableVibration = mode != AppNotificationMode.silent;
    final isSilent = mode == AppNotificationMode.silent;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(mode),
        _channelName(mode),
        channelDescription:
            'SpeechUp notifications for practice reminders and social activity.',
        importance: isSilent ? Importance.low : Importance.high,
        priority: isSilent ? Priority.low : Priority.high,
        playSound: playSound,
        enableVibration: enableVibration,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
    );
  }

  Future<void> _createAndroidNotificationChannels(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) return;
    for (final mode in AppNotificationMode.values) {
      final isSilent = mode == AppNotificationMode.silent;
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId(mode),
          _channelName(mode),
          description:
              'SpeechUp notifications for practice reminders and social activity.',
          importance: isSilent ? Importance.low : Importance.high,
          playSound: mode == AppNotificationMode.sound,
          enableVibration: mode != AppNotificationMode.silent,
        ),
      );
    }
  }

  String _channelId(AppNotificationMode mode) {
    return 'speechup_notification_${mode.name}_channel';
  }

  String _channelName(AppNotificationMode mode) {
    return switch (mode) {
      AppNotificationMode.sound => 'SpeechUp Notifications - Sound',
      AppNotificationMode.vibrate => 'SpeechUp Notifications - Vibrate',
      AppNotificationMode.silent => 'SpeechUp Notifications - Silent',
    };
  }

  Future<void> _zonedScheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final scheduleMode = await _androidScheduleMode();
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      if (scheduleMode != AndroidScheduleMode.exactAllowWhileIdle) rethrow;
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      final canScheduleExact = await androidPlugin
          ?.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (_) {}
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || !_initialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOf8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
    ); // 8 PM
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
