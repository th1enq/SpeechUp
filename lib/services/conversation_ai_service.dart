import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversationAiService {
  static const _endpoint = String.fromEnvironment('SPEECHUP_AI_ENDPOINT');
  static const _apiKey = String.fromEnvironment('SPEECHUP_AI_API_KEY');

  bool get hasRemoteEndpoint => _endpoint.trim().isNotEmpty;

  Future<String> nextReply({
    required String scenarioId,
    required String scenarioTitle,
    required List<Map<String, dynamic>> messages,
  }) async {
    if (!hasRemoteEndpoint) {
      return _fallbackReply(scenarioId, messages);
    }

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'scenarioId': scenarioId,
            'scenarioTitle': scenarioTitle,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI API returned ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final reply = data['reply'] ?? data['message'] ?? data['text'];
    if (reply is String && reply.trim().isNotEmpty) {
      return reply.trim();
    }
    throw StateError('AI API response does not contain a reply.');
  }

  String _fallbackReply(String scenarioId, List<Map<String, dynamic>> messages) {
    final userCount = messages.where((message) => message['isUser'] == true).length;
    final replies = _fallbackReplies[scenarioId] ?? _fallbackReplies['cafe']!;
    final index = userCount.clamp(0, replies.length - 1).toInt();
    return replies[index];
  }

  static const Map<String, List<String>> _fallbackReplies = {
    'cafe': [
      'Xin chào! Bạn muốn dùng gì hôm nay ạ?',
      'Dạ được ạ. Bạn muốn size vừa hay lớn?',
      'Mình nghe rõ rồi. Bạn muốn thêm đường hay ít đá không?',
      'Tốt lắm. Bạn đã nói rất tự nhiên trong tình huống này.',
    ],
    'interview': [
      'Chào bạn, bạn có thể giới thiệu đôi chút về bản thân mình không?',
      'Cảm ơn bạn. Điểm mạnh lớn nhất của bạn trong công việc là gì?',
      'Bạn có thể chia sẻ một dự án mà bạn tự hào không?',
      'Câu trả lời rõ ràng. Hãy thử thêm một khoảng dừng trước ý chính tiếp theo.',
    ],
    'phone': [
      'Alô, xin chào. Tôi có thể giúp gì cho bạn?',
      'Tôi đã nghe phần mở đầu. Bạn có thể tóm tắt mục đích cuộc gọi không?',
      'Rất rõ. Về bước tiếp theo, bạn muốn đề xuất điều gì?',
      'Bạn giữ nhịp nói tốt. Hãy tiếp tục với một câu kết ngắn.',
    ],
    'present': [
      'Mọi người đã sẵn sàng. Bạn có thể bắt đầu phần mở đầu.',
      'Phần mở đầu rõ. Bạn có thể giải thích ý chính đầu tiên không?',
      'Tốt. Hãy thử kết nối ý này với lợi ích cho người nghe.',
      'Bạn đang trình bày khá mạch lạc. Một khoảng dừng ngắn sẽ giúp nhấn mạnh hơn.',
    ],
  };
}
