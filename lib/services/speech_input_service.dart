import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechInputService extends ChangeNotifier {
  SpeechInputService._internal({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  static final SpeechInputService instance = SpeechInputService._internal();

  factory SpeechInputService() => instance;

  final SpeechToText _speech;
  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  String? _lastError;
  double _soundLevel = 0;
  DateTime? _startedAt;
  Timer? _durationTicker;
  Duration _elapsed = Duration.zero;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText.trim();
  String? get lastError => _lastError;
  double get soundLevel => _soundLevel;
  Duration get elapsed => _elapsed;
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<bool> initialize({String? localeId}) async {
    if (!isSupportedPlatform) {
      _setError('Microphone is only supported on Android and iOS.');
      _isAvailable = false;
      notifyListeners();
      return false;
    }

    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: false,
      );
      _isInitialized = true;
    } on PlatformException catch (error) {
      _isAvailable = false;
      _isInitialized = true;
      _setError(_mapPlatformException(error));
      notifyListeners();
      return false;
    } catch (_) {
      _isAvailable = false;
      _isInitialized = true;
      _setError('Speech recognition failed to initialize on this device.');
      notifyListeners();
      return false;
    }

    if (!_isAvailable) {
      _setError('Speech recognition is unavailable on this device.');
    } else if (localeId != null) {
      final matchedLocale = await resolveLocaleId(localeId);
      if (matchedLocale == null) {
        _setError('Selected speech locale is unavailable on this device.');
      }
    }

    notifyListeners();
    return _isAvailable;
  }

  Future<String?> resolveLocaleId(String preferredLocaleId) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    final locales = await _speech.locales();
    if (locales.isEmpty) return null;

    final exactMatch = locales.where(
      (locale) => locale.localeId == preferredLocaleId,
    );
    if (exactMatch.isNotEmpty) return exactMatch.first.localeId;

    final languageCode = preferredLocaleId.split('_').first;
    final languageMatch = locales.where(
      (locale) =>
          locale.localeId.toLowerCase().startsWith(languageCode.toLowerCase()),
    );
    if (languageMatch.isNotEmpty) return languageMatch.first.localeId;

    return locales.first.localeId;
  }

  Future<bool> startListening({
    required String localeId,
    Duration listenFor = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 4),
  }) async {
    _lastError = null;
    final available = await initialize(localeId: localeId);
    if (!available) {
      notifyListeners();
      return false;
    }

    final resolvedLocale = await resolveLocaleId(localeId);
    if (resolvedLocale == null) {
      _setError('No supported speech locale was found.');
      notifyListeners();
      return false;
    }

    _recognizedText = '';
    _soundLevel = 0;
    _elapsed = Duration.zero;
    _startedAt = DateTime.now();
    _durationTicker?.cancel();
    _durationTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_startedAt == null) return;
      _elapsed = DateTime.now().difference(_startedAt!);
      notifyListeners();
    });

    final didStart = await _speech.listen(
      onResult: _handleResult,
      localeId: resolvedLocale,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onSoundLevelChange: _handleSoundLevel,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
      ),
    );

    _isListening = didStart;
    if (!didStart) {
      _durationTicker?.cancel();
      _durationTicker = null;
      _startedAt = null;
      _setError('Unable to start microphone listening.');
    }
    notifyListeners();
    return didStart;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _finalizeListeningState();
    notifyListeners();
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _recognizedText = '';
    _finalizeListeningState(resetElapsed: true);
    notifyListeners();
  }

  void resetSession() {
    _recognizedText = '';
    _lastError = null;
    _soundLevel = 0;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void _handleResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    notifyListeners();
  }

  void _handleError(SpeechRecognitionError error) {
    _setError(error.errorMsg);
    if (error.permanent || !_speech.isListening) {
      _finalizeListeningState();
    }
    notifyListeners();
  }

  void _handleStatus(String status) {
    if (status == 'listening') {
      _isListening = true;
      notifyListeners();
      return;
    }

    if (status == 'done' || status == 'notListening') {
      _finalizeListeningState();
      notifyListeners();
    }
  }

  void _handleSoundLevel(double level) {
    _soundLevel = level;
    notifyListeners();
  }

  void _finalizeListeningState({bool resetElapsed = false}) {
    _isListening = false;
    _soundLevel = 0;
    _durationTicker?.cancel();
    _durationTicker = null;
    if (_startedAt != null && !resetElapsed) {
      _elapsed = DateTime.now().difference(_startedAt!);
    } else if (resetElapsed) {
      _elapsed = Duration.zero;
    }
    _startedAt = null;
  }

  void _setError(String message) {
    _lastError = message.trim();
  }

  String _mapPlatformException(PlatformException error) {
    switch (error.code) {
      case 'recognizerNotAvailable':
        return 'Speech recognition service is not installed or unavailable on this device.';
      case 'speechRecognizerDisabled':
        return 'Speech recognition is disabled on this device.';
      case 'audioRecording':
        return 'Microphone recording could not be started.';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'The selected speech recognition language is unavailable on this device.';
      default:
        final message = error.message?.trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return 'Speech recognition failed with platform error: ${error.code}.';
    }
  }

  String get errorSummary {
    final error = _lastError;
    if (error == null || error.isEmpty) {
      return 'Unknown speech recognition error.';
    }
    return error;
  }

  @override
  void dispose() {
    _durationTicker?.cancel();
    _speech.cancel();
    super.dispose();
  }
}
