import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Cloud-based speech-to-text using Google Cloud Speech-to-Text API.
///
/// Records audio from the device microphone (which works even when
/// Android's SpeechRecognizer service is unavailable), then sends
/// the recording to Google Cloud for transcription.
class CloudSpeechService extends ChangeNotifier {
  static const String _apiKey =
      String.fromEnvironment('GOOGLE_TTS_API_KEY');

  static final Uri _endpoint = Uri.parse(
    'https://speech.googleapis.com/v1/speech:recognize',
  );

  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String? _lastError;
  String? _tempFilePath;

  bool get isConfigured => _apiKey.isNotEmpty;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  bool get isListening => _isRecording || _isProcessing;
  String get recognizedText => _recognizedText;
  String? get lastError => _lastError;
  String get errorSummary => _lastError ?? 'Unknown error';

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Check if microphone permission is granted.
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio from the microphone.
  Future<bool> startListening({String locale = 'vi-VN'}) async {
    _lastError = null;
    _recognizedText = '';

    if (!isConfigured) {
      _lastError = 'Google API key not configured';
      debugPrint('[CloudSpeech] API key missing');
      notifyListeners();
      return false;
    }

    final hasPerms = await _recorder.hasPermission();
    if (!hasPerms) {
      _lastError = 'Microphone permission denied';
      debugPrint('[CloudSpeech] No mic permission');
      notifyListeners();
      return false;
    }

    try {
      // Create temp file path for recording
      final dir = Directory.systemTemp;
      _tempFilePath =
          '${dir.path}/speechup_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      debugPrint('[CloudSpeech] Starting recording to $_tempFilePath');

      // Record as WAV (LINEAR16) which Google Speech API accepts
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: _tempFilePath!,
      );

      _isRecording = true;
      notifyListeners();
      debugPrint('[CloudSpeech] Recording started');
      return true;
    } catch (e) {
      _lastError = 'Failed to start recording: $e';
      debugPrint('[CloudSpeech] Start error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Stop recording and send audio to Google Cloud for transcription.
  Future<String> stopListening({String languageCode = 'vi-VN'}) async {
    if (!_isRecording) return '';

    try {
      debugPrint('[CloudSpeech] Stopping recording...');
      final path = await _recorder.stop();
      _isRecording = false;
      _isProcessing = true;
      notifyListeners();

      if (path == null || path.isEmpty) {
        _lastError = 'No audio recorded';
        _isProcessing = false;
        notifyListeners();
        return '';
      }

      debugPrint('[CloudSpeech] Recording saved to $path');

      // Read audio file
      final audioFile = File(path);
      if (!await audioFile.exists()) {
        _lastError = 'Audio file not found';
        _isProcessing = false;
        notifyListeners();
        return '';
      }

      final audioBytes = await audioFile.readAsBytes();
      debugPrint('[CloudSpeech] Audio size: ${audioBytes.length} bytes');

      if (audioBytes.length < 1000) {
        _lastError = 'Recording too short';
        _isProcessing = false;
        _cleanup(path);
        notifyListeners();
        return '';
      }

      // Send to Google Cloud Speech-to-Text API
      final result = await _transcribe(audioBytes, languageCode);
      _recognizedText = result;
      _isProcessing = false;
      _cleanup(path);
      notifyListeners();

      debugPrint('[CloudSpeech] Transcription: "$result"');
      return result;
    } catch (e) {
      _lastError = 'Transcription failed: $e';
      _isRecording = false;
      _isProcessing = false;
      debugPrint('[CloudSpeech] Stop/transcribe error: $e');
      notifyListeners();
      return '';
    }
  }

  /// Cancel recording without transcribing.
  Future<void> cancelListening() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        if (path != null) _cleanup(path);
      }
    } catch (_) {}
    _isRecording = false;
    _isProcessing = false;
    _recognizedText = '';
    notifyListeners();
  }

  void resetSession() {
    _recognizedText = '';
    _lastError = null;
    notifyListeners();
  }

  /// Send audio to Google Cloud Speech-to-Text API.
  Future<String> _transcribe(Uint8List audioBytes, String languageCode) async {
    final uri = _endpoint.replace(
      queryParameters: {'key': _apiKey},
    );

    final body = {
      'config': {
        'encoding': 'LINEAR16',
        'sampleRateHertz': 16000,
        'languageCode': languageCode,
        'enableAutomaticPunctuation': true,
        'model': 'default',
      },
      'audio': {
        'content': base64Encode(audioBytes),
      },
    };

    debugPrint('[CloudSpeech] Sending ${audioBytes.length} bytes to API...');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      debugPrint('[CloudSpeech] API error ${response.statusCode}: ${response.body}');
      throw Exception(
          'Speech API error (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>?;

    if (results == null || results.isEmpty) {
      debugPrint('[CloudSpeech] No transcription results');
      return '';
    }

    // Get the best transcript
    final alternatives = results.first['alternatives'] as List<dynamic>?;
    if (alternatives == null || alternatives.isEmpty) {
      return '';
    }

    final transcript = alternatives.first['transcript'] as String? ?? '';
    final confidence = alternatives.first['confidence'] as double? ?? 0;
    debugPrint(
        '[CloudSpeech] Transcript: "$transcript" (confidence: $confidence)');

    return transcript;
  }

  void _cleanup(String path) {
    try {
      File(path).deleteSync();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await cancelListening();
    _recorder.dispose();
    super.dispose();
  }
}
