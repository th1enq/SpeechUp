import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// On-device TTS fallback using the system TTS engine.
///
/// Works without any API key. Uses whatever TTS engine is installed
/// on the device (e.g. Google TTS on Android, Apple TTS on iOS).
class LocalTtsService {
  static final LocalTtsService _instance = LocalTtsService._internal();

  factory LocalTtsService() => _instance;

  LocalTtsService._internal();

  FlutterTts? _tts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  List<String> _availableLanguages = [];

  bool get isSpeaking => _isSpeaking;

  /// Called when speech completes or is cancelled.
  void Function()? onComplete;

  Future<void> _ensureInitialized() async {
    if (_isInitialized && _tts != null) return;

    _tts = FlutterTts();

    _tts!.setCompletionHandler(() {
      debugPrint('[LocalTTS] Speech completed');
      _isSpeaking = false;
      onComplete?.call();
    });
    _tts!.setCancelHandler(() {
      debugPrint('[LocalTTS] Speech cancelled');
      _isSpeaking = false;
      onComplete?.call();
    });
    _tts!.setErrorHandler((msg) {
      debugPrint('[LocalTTS] Error: $msg');
      _isSpeaking = false;
      onComplete?.call();
    });
    _tts!.setStartHandler(() {
      debugPrint('[LocalTTS] Speech started');
    });

    // Get available languages
    try {
      final languages = await _tts!.getLanguages;
      if (languages is List) {
        _availableLanguages =
            languages.map((e) => e.toString()).toList();
        debugPrint('[LocalTTS] Available languages: $_availableLanguages');
      }
    } catch (e) {
      debugPrint('[LocalTTS] Failed to get languages: $e');
    }

    // Try to set Vietnamese, fall back chain: vi-VN → vi → en-US
    final viSet = await _trySetLanguage('vi-VN');
    if (!viSet) {
      debugPrint('[LocalTTS] vi-VN not available, trying vi');
      final viOnly = await _trySetLanguage('vi');
      if (!viOnly) {
        debugPrint('[LocalTTS] vi not available, falling back to en-US');
        await _trySetLanguage('en-US');
      }
    }

    await _tts!.setSpeechRate(0.5);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);

    // Check engines
    try {
      final engines = await _tts!.getEngines;
      debugPrint('[LocalTTS] Available engines: $engines');
    } catch (e) {
      debugPrint('[LocalTTS] Failed to get engines: $e');
    }

    _isInitialized = true;
    debugPrint('[LocalTTS] Initialized successfully');
  }

  Future<bool> _trySetLanguage(String lang) async {
    try {
      final result = await _tts!.setLanguage(lang);
      debugPrint('[LocalTTS] setLanguage($lang) result: $result');
      // flutter_tts returns 1 on success for Android
      return result == 1 || result == true;
    } catch (e) {
      debugPrint('[LocalTTS] setLanguage($lang) failed: $e');
      return false;
    }
  }

  /// Speak the given [text] using on-device TTS.
  ///
  /// [language] defaults to 'vi-VN'.
  /// [speakingRate] from 0.0 to 1.0, default 0.5.
  Future<void> speak(
    String text, {
    String language = 'vi-VN',
    double speakingRate = 0.5,
  }) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();

    // Try to set requested language, fallback to 'vi' then default
    if (!await _trySetLanguage(language)) {
      final langCode = language.split('-').first;
      if (langCode != language) {
        await _trySetLanguage(langCode);
      }
    }

    await _tts!.setSpeechRate(speakingRate.clamp(0.0, 1.0));
    _isSpeaking = true;
    debugPrint('[LocalTTS] Speaking: "${text.substring(0, text.length.clamp(0, 50))}..."');

    final result = await _tts!.speak(text);
    debugPrint('[LocalTTS] speak() result: $result');

    if (result != 1) {
      debugPrint('[LocalTTS] speak() did not return success');
      _isSpeaking = false;
      onComplete?.call();
    }
  }

  /// Stop any current speech.
  Future<void> stop() async {
    if (_tts == null) return;
    _isSpeaking = false;
    await _tts!.stop();
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _tts?.stop();
    _isSpeaking = false;
    _isInitialized = false;
  }
}
