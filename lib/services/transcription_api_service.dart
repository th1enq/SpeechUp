import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TranscriptionApiService {
  static const _endpoint = String.fromEnvironment('SPEECHUP_TRANSCRIBE_ENDPOINT');
  static const _apiKey = String.fromEnvironment('SPEECHUP_TRANSCRIBE_API_KEY');

  bool get hasEndpoint => _endpoint.trim().isNotEmpty;

  Future<String> transcribe({
    required File audioFile,
    required String languageCode,
  }) async {
    if (!hasEndpoint) {
      throw StateError(
        'Missing SPEECHUP_TRANSCRIBE_ENDPOINT. Run with '
        '--dart-define=SPEECHUP_TRANSCRIBE_ENDPOINT=https://your-api/transcribe',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.fields['language'] = languageCode;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
    );

    if (_apiKey.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_apiKey';
    }

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Transcription API returned ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final text = decoded['text'] ?? decoded['transcript'] ?? decoded['result'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    }
    if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();

    throw StateError('Transcription API response did not contain text.');
  }
}
