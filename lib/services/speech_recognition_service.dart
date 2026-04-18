import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognitionService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  String? _lastError;

  bool get isAvailable => _initialized && _speech.isAvailable;
  bool get isListening => _speech.isListening;
  String? get lastError => _lastError;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String message)? onError,
  }) async {
    _lastError = null;
    _initialized = await _speech.initialize(
      onStatus: onStatus,
      onError: (SpeechRecognitionError error) {
        _lastError = error.errorMsg;
        onError?.call(error.errorMsg);
      },
    );
    return isAvailable;
  }

  Future<List<LocaleName>> locales() async {
    if (!_initialized) {
      await initialize();
    }
    return _speech.locales();
  }

  Future<void> listen({
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(double level)? onSoundLevelChange,
    String? localeId,
  }) async {
    if (!isAvailable) {
      final available = await initialize();
      if (!available) {
        throw StateError(_lastError ?? 'Speech recognition is not available.');
      }
    }

    await _speech.listen(
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
      onSoundLevelChange: onSoundLevelChange,
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
