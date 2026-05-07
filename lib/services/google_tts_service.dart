import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class GoogleTtsService {
  static const String _apiKey = String.fromEnvironment('GOOGLE_TTS_API_KEY');
  static final Uri _endpoint = Uri.parse(
    'https://texttospeech.googleapis.com/v1/text:synthesize',
  );

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<Uint8List> synthesize({
    required String text,
    required String languageCode,
    String? voiceName,
    double speakingRate = 1.0,
    double pitch = 0.0,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Google TTS key missing. Run with --dart-define=GOOGLE_TTS_API_KEY=YOUR_KEY',
      );
    }
    if (text.trim().isEmpty) {
      throw Exception('Text is empty.');
    }

    final uri = _endpoint.replace(
      queryParameters: {'key': _apiKey},
    );

    final body = {
      'input': {'text': text},
      'voice': {
        'languageCode': languageCode,
        if (voiceName != null && voiceName.isNotEmpty) 'name': voiceName,
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
        'speakingRate': speakingRate,
        'pitch': pitch,
      },
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Google TTS failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final audioBase64 = json['audioContent'] as String?;
    if (audioBase64 == null || audioBase64.isEmpty) {
      throw Exception('Google TTS returned empty audio.');
    }

    return base64Decode(audioBase64);
  }
}
