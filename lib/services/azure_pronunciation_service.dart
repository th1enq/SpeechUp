import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pronunciation_result.dart';

/// Azure Speech SDK – Pronunciation Assessment via REST.
///
/// Requires two `--dart-define` values at build time:
///   • `AZURE_SPEECH_KEY`   – your Azure subscription key
///   • `AZURE_SPEECH_REGION` – e.g. `southeastasia`
///
/// Usage:
/// ```dart
/// final result = await AzurePronunciationService().assess(
///   audioBytes: wavBytes,
///   referenceText: 'Xin chào các bạn',
///   language: 'vi-VN',
/// );
/// ```
class AzurePronunciationService {
  static final AzurePronunciationService _instance =
      AzurePronunciationService._internal();

  factory AzurePronunciationService() => _instance;

  AzurePronunciationService._internal();

  // Keys injected via --dart-define or --dart-define-from-file=.env.
  static const String _azureSpeechKey = String.fromEnvironment(
    'AZURE_SPEECH_KEY',
    defaultValue: '',
  );
  static const String _azureSpeechRegion = String.fromEnvironment(
    'AZURE_SPEECH_REGION',
    defaultValue: '',
  );
  static const String _key1 = String.fromEnvironment('KEY_1', defaultValue: '');
  static const String _regionAlias = String.fromEnvironment(
    'REGION',
    defaultValue: '',
  );

  String get _apiKey => _azureSpeechKey.isNotEmpty ? _azureSpeechKey : _key1;
  String get _region =>
      _azureSpeechRegion.isNotEmpty ? _azureSpeechRegion : _regionAlias;

  /// Whether the service has valid configuration.
  bool get isConfigured => _apiKey.isNotEmpty && _region.isNotEmpty;

  /// The REST endpoint for speech recognition + pronunciation assessment.
  String get _endpoint =>
      'https://$_region.stt.speech.microsoft.com/speech/recognition/'
      'conversation/cognitiveservices/v1';

  /// Assess pronunciation of [audioBytes] (16-bit PCM WAV) against
  /// [referenceText].
  ///
  /// Returns a [PronunciationResult] with accuracy, fluency, completeness,
  /// and prosody scores.
  ///
  /// Throws on network / API errors.
  Future<PronunciationResult> assess({
    required Uint8List audioBytes,
    required String referenceText,
    String language = 'vi-VN',
  }) async {
    if (!isConfigured) {
      throw StateError(
        'Azure Pronunciation Assessment is not configured. '
        'Pass --dart-define=AZURE_SPEECH_KEY=<key> and '
        '--dart-define=AZURE_SPEECH_REGION=<region> at build time.',
      );
    }

    // Build the pronunciation assessment config as base64-encoded JSON.
    final assessmentConfig = {
      'ReferenceText': referenceText,
      'GradingSystem': 'HundredMark',
      'Granularity': 'Word',
      'Dimension': 'Comprehensive',
      'EnableProsodyAssessment': true,
    };
    final configBase64 = base64Encode(
      utf8.encode(jsonEncode(assessmentConfig)),
    );

    final uri = Uri.parse('$_endpoint?language=$language&format=detailed');
    debugPrint(
      '[AzurePronunciation] POST $uri | audioBodyBytes=${audioBytes.length} | referenceTextInAssessmentHeader="$referenceText"',
    );

    final response = await http.post(
      uri,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Pronunciation-Assessment': configBase64,
        'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
        'Accept': 'application/json',
      },
      body: audioBytes,
    );
    debugPrint(
      '[AzurePronunciation] response status=${response.statusCode} bytes=${response.bodyBytes.length}',
    );
    debugPrint('[AzurePronunciation] response body=${response.body}');

    if (response.statusCode != 200) {
      debugPrint(
        '[AzurePronunciation] ${response.statusCode}: ${response.body}',
      );
      throw HttpException(
        'Azure Pronunciation Assessment failed '
        '(${response.statusCode}): ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = PronunciationResult.fromAzureJson(
      json,
      referenceText: referenceText,
    );
    debugPrint(
      '[AzurePronunciation] recognized="${result.recognizedText}" accuracy=${result.accuracyScore} fluency=${result.fluencyScore} completeness=${result.completenessScore} overall=${result.overallScore.toStringAsFixed(1)}',
    );

    return result;
  }

  /// Quick health-check: sends a tiny silent WAV to verify credentials.
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    try {
      // Minimal valid WAV header (44 bytes) + 160 bytes of silence (16-bit PCM).
      final wavHeader = _buildMinimalWavHeader(160);
      final silence = Uint8List(160); // zeros = silence
      final wav = Uint8List(wavHeader.length + silence.length);
      wav.setAll(0, wavHeader);
      wav.setAll(wavHeader.length, silence);

      await assess(audioBytes: wav, referenceText: 'test', language: 'en-US');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Build a minimal 44-byte WAV header for PCM 16-bit mono 16 kHz.
  Uint8List _buildMinimalWavHeader(int dataSize) {
    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little); // file size - 8
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, 16000, Endian.little); // sample rate
    header.setUint32(28, 32000, Endian.little); // byte rate
    header.setUint16(32, 2, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bits per sample

    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }
}

/// Simple HTTP exception for Azure API errors.
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
