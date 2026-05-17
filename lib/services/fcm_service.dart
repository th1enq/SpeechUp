import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'firestore_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_isFirebaseSupportedForFcm) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

bool get _isFirebaseSupportedForFcm {
  if (kIsWeb) return false;
  return Platform.isAndroid;
}

class FcmService {
  static final FcmService _instance = FcmService._internal();

  factory FcmService() => _instance;

  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  String? _registeredUid;
  String? _registeredToken;

  static void registerBackgroundHandler() {
    if (!_isFirebaseSupportedForFcm) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> startForCurrentUser() async {
    if (!_isFirebaseSupportedForFcm) return;
    if (!await NotificationService().areNotificationsEnabled()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_registeredUid == user.uid) return;

    await stop();
    _registeredUid = user.uid;

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FcmService] Notification permission denied.');
      return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    await _saveCurrentToken(user.uid);
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _saveToken(user.uid, token);
    });
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleOpenedMessage(initialMessage);
    }
  }

  Future<void> stop() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _registeredUid = null;
    _registeredToken = null;
  }

  Future<void> removeCurrentToken() async {
    final uid = _registeredUid ?? FirebaseAuth.instance.currentUser?.uid;
    final token = _registeredToken ?? await _messaging.getToken();
    if (uid == null || token == null) return;
    await _firestoreService.deleteFcmToken(uid: uid, token: token);
    _registeredToken = null;
  }

  Future<void> _saveCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _saveToken(uid, token);
  }

  Future<void> _saveToken(String uid, String token) async {
    _registeredToken = token;
    await _firestoreService.saveFcmToken(
      uid: uid,
      token: token,
      platform: _platformName(),
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null || body == null) return;

    await NotificationService().showNow(
      id:
          message.messageId?.hashCode.toUnsigned(31) ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title,
      body: body,
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final notificationId = message.data['notificationId']?.toString();
    if (notificationId == null || notificationId.isEmpty) return;
    await _firestoreService.markNotificationRead(notificationId);
  }

  String _platformName() {
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
