import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android speech recognizer that bypasses the
/// `SpeechRecognizer.isRecognitionAvailable()` check.
///
/// Uses a MethodChannel + EventChannel to communicate with
/// the Kotlin implementation in MainActivity.
class NativeSpeechService extends ChangeNotifier {
  static final NativeSpeechService _instance = NativeSpeechService._internal();

  factory NativeSpeechService() => _instance;

  NativeSpeechService._internal() {
    _eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        debugPrint('[NativeSpeech] Event stream error: $error');
        _lastError = error.toString();
        _isListening = false;
        notifyListeners();
      },
    );
  }

  static const MethodChannel _methodChannel =
      MethodChannel('com.speechup/speech');
  static const EventChannel _eventChannel =
      EventChannel('com.speechup/speech_events');

  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  String? _lastError;
  double _soundLevel = 0;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText.trim();
  String? get lastError => _lastError;
  double get soundLevel => _soundLevel;

  /// Whether this service is supported (Android only).
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Initialize the native speech recognizer.
  Future<bool> initialize() async {
    if (!isSupportedPlatform) return false;
    if (_isInitialized) return true;

    try {
      debugPrint('[NativeSpeech] Initializing...');
      final result = await _methodChannel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      debugPrint('[NativeSpeech] Init result: $_isInitialized');

      if (_isInitialized) {
        // Request permission proactively
        await _methodChannel.invokeMethod('requestPermission');
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('[NativeSpeech] Init error: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Start listening for speech.
  Future<bool> startListening({String locale = 'vi-VN'}) async {
    _lastError = null;
    _recognizedText = '';
    _soundLevel = 0;

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        _lastError = 'Could not initialize speech recognizer';
        notifyListeners();
        return false;
      }
    }

    try {
      debugPrint('[NativeSpeech] Starting listening with locale: $locale');
      await _methodChannel.invokeMethod('start', {'locale': locale});
      _isListening = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[NativeSpeech] Start error: $e');
      _lastError = e.toString();
      _isListening = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop listening (finalize current recognition).
  Future<void> stopListening() async {
    try {
      await _methodChannel.invokeMethod('stop');
    } catch (e) {
      debugPrint('[NativeSpeech] Stop error: $e');
    }
  }

  /// Cancel listening (discard results).
  Future<void> cancelListening() async {
    try {
      await _methodChannel.invokeMethod('cancel');
      _isListening = false;
      _recognizedText = '';
      notifyListeners();
    } catch (e) {
      debugPrint('[NativeSpeech] Cancel error: $e');
    }
  }

  /// Reset session state.
  void resetSession() {
    _recognizedText = '';
    _lastError = null;
    _soundLevel = 0;
    notifyListeners();
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['type'] as String?;
    final data = event['data'] as String?;

    switch (type) {
      case 'result':
        _recognizedText = data ?? '';
        _isListening = false;
        debugPrint('[NativeSpeech] Final result: $_recognizedText');
        notifyListeners();
        break;

      case 'partial':
        _recognizedText = data ?? '';
        notifyListeners();
        break;

      case 'status':
        if (data == 'listening') {
          _isListening = true;
        } else if (data == 'done') {
          _isListening = false;
        }
        notifyListeners();
        break;

      case 'soundLevel':
        _soundLevel = double.tryParse(data ?? '0') ?? 0;
        notifyListeners();
        break;

      case 'error':
        _lastError = data;
        _isListening = false;
        debugPrint('[NativeSpeech] Error: $data');
        notifyListeners();
        break;
    }
  }

  String get errorSummary => _lastError ?? 'Unknown error';
}
