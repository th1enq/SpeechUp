import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemini-powered LLM chat service for dynamic roleplay conversations.
///
/// Requires `--dart-define=GEMINI_API_KEY=<key>` at build time.
///
/// Usage:
/// ```dart
/// final service = LlmChatService();
/// service.startScenario(
///   scenarioId: 'shopping',
///   scenarioPrompt: 'You are a friendly shopkeeper...',
/// );
/// final reply = await service.sendMessage('Xin chào!');
/// ```
class LlmChatService {
  static final LlmChatService _instance = LlmChatService._internal();

  factory LlmChatService() => _instance;

  LlmChatService._internal();

  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Whether the service has valid configuration.
  bool get isConfigured => _apiKey.isNotEmpty;

  /// The Gemini REST endpoint.
  static const String _model = 'gemini-2.0-flash';
  static final Uri _endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
  );

  /// Conversation history for the current session.
  final List<Map<String, dynamic>> _history = [];

  /// System instruction for the current scenario.
  String _systemInstruction = '';

  /// Current scenario ID.
  String? currentScenarioId;

  /// Base system prompt that makes the AI stuttering-supportive.
  static const String _baseSystemPrompt = '''
Bạn là một trợ lý luyện nói thân thiện dành cho người nói lắp hoặc muốn cải thiện kỹ năng giao tiếp tiếng Việt.

Nguyên tắc quan trọng:
- Luôn kiên nhẫn, không vội vàng
- Trả lời ngắn gọn (2-4 câu) để người dùng có thời gian phản hồi
- Sử dụng ngôn ngữ đơn giản, rõ ràng
- Nếu người dùng nói lắp hoặc lặp từ, KHÔNG bao giờ nhắc đến điều đó
- Khuyến khích và động viên khi người dùng trả lời tốt
- Giữ vai trò nhất quán trong suốt cuộc hội thoại
- Trả lời bằng tiếng Việt
''';

  /// Pre-defined scenario system prompts.
  static const Map<String, String> scenarioPrompts = {
    'shopping': '''
Bạn đóng vai nhân viên bán hàng tại một cửa hàng tiện lợi.
Chào đón khách hàng, hỏi họ cần gì, giới thiệu sản phẩm, và hỗ trợ thanh toán.
Hãy thân thiện và chuyên nghiệp.
''',
    'interview': '''
Bạn đóng vai nhà tuyển dụng đang phỏng vấn ứng viên cho vị trí nhân viên văn phòng.
Hỏi về kinh nghiệm, điểm mạnh, điểm yếu, và mục tiêu nghề nghiệp.
Tạo không khí thoải mái nhưng chuyên nghiệp.
''',
    'doctor': '''
Bạn đóng vai bác sĩ đa khoa tại phòng khám.
Hỏi bệnh nhân về triệu chứng, tiền sử bệnh, và đưa ra lời khuyên sức khỏe chung.
Hãy ân cần và dễ hiểu. Lưu ý: không đưa ra chẩn đoán y khoa thật.
''',
    'phone': '''
Bạn đóng vai nhân viên hỗ trợ khách hàng qua điện thoại.
Trả lời các câu hỏi về dịch vụ, xử lý khiếu nại, và hỗ trợ kỹ thuật.
Giữ giọng điệu lịch sự và kiên nhẫn.
''',
    'cafe': '''
Bạn đóng vai nhân viên quán cà phê.
Chào đón khách, giới thiệu menu, gợi ý đồ uống, và xử lý đơn hàng.
Hãy vui vẻ và nhiệt tình.
''',
    'present': '''
Bạn đóng vai đồng nghiệp đang nghe thuyết trình và đặt câu hỏi.
Hỏi về chi tiết kế hoạch, số liệu, và đề xuất ý kiến.
Hãy tích cực và xây dựng.
''',
  };

  /// Start a new conversation scenario.
  void startScenario({
    required String scenarioId,
    String? customPrompt,
  }) {
    _history.clear();
    currentScenarioId = scenarioId;

    final scenarioContext =
        customPrompt ?? scenarioPrompts[scenarioId] ?? '';

    _systemInstruction = '$_baseSystemPrompt\n\n'
        'Tình huống hiện tại:\n$scenarioContext';
  }

  /// Send a user message and get the AI response.
  ///
  /// Returns the AI response text. Throws on network/API errors.
  Future<String> sendMessage(String userMessage) async {
    if (!isConfigured) {
      throw StateError(
        'Gemini API is not configured. '
        'Pass --dart-define=GEMINI_API_KEY=<key> at build time.',
      );
    }

    // Add user message to history
    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    // Build the request body
    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': _systemInstruction}
        ],
      },
      'contents': _history,
      'generationConfig': {
        'temperature': 0.8,
        'topP': 0.95,
        'topK': 40,
        'maxOutputTokens': 256,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };

    final uri = _endpoint.replace(
      queryParameters: {'key': _apiKey},
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      debugPrint('[LlmChat] ${response.statusCode}: ${response.body}');
      // Remove the failed user message from history
      _history.removeLast();
      throw Exception(
        'Gemini API error (${response.statusCode}): ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      _history.removeLast();
      throw Exception('Gemini returned no candidates.');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.firstOrNull?['text'] as String? ?? '';

    if (text.isEmpty) {
      _history.removeLast();
      throw Exception('Gemini returned empty response.');
    }

    // Add assistant response to history
    _history.add({
      'role': 'model',
      'parts': [
        {'text': text}
      ],
    });

    return text.trim();
  }

  /// Get the opening message for a scenario (AI starts the conversation).
  Future<String> getOpeningMessage() async {
    if (!isConfigured) {
      return _getFallbackOpening();
    }

    try {
      return await sendMessage(
        'Bắt đầu cuộc hội thoại. Hãy chào và mở đầu theo đúng vai trò của bạn. '
        'Chỉ trả lời 1-2 câu ngắn.',
      );
    } catch (e) {
      debugPrint('[LlmChat] Opening message failed: $e');
      // Remove the meta-prompt from history so it doesn't pollute the conversation
      _history.clear();
      return _getFallbackOpening();
    }
  }

  String _getFallbackOpening() {
    switch (currentScenarioId) {
      case 'shopping':
        return 'Xin chào! Chào mừng bạn đến cửa hàng. Bạn cần tìm gì ạ?';
      case 'interview':
        return 'Chào bạn, cảm ơn bạn đã đến phỏng vấn. Bạn có thể giới thiệu về bản thân không?';
      case 'doctor':
        return 'Xin chào, tôi là bác sĩ. Hôm nay bạn đến khám vì lý do gì ạ?';
      case 'phone':
        return 'Alô, xin chào! Đây là trung tâm hỗ trợ. Tôi có thể giúp gì cho bạn?';
      case 'cafe':
        return 'Xin chào! Chào mừng bạn đến quán cà phê. Bạn muốn dùng gì ạ?';
      case 'present':
        return 'Chào mọi người! Bạn có thể bắt đầu bài thuyết trình khi sẵn sàng.';
      default:
        return 'Xin chào! Bạn muốn bắt đầu nói về chủ đề gì?';
    }
  }

  /// Generate a conversation summary at the end of a session.
  Future<ConversationSummary> generateSummary() async {
    if (!isConfigured || _history.length < 2) {
      return ConversationSummary.placeholder();
    }

    try {
      final summaryPrompt =
          'Dựa trên cuộc hội thoại vừa rồi, hãy đánh giá hiệu quả giao tiếp '
          'của người dùng theo thang 0-100. Trả lời theo format JSON chính xác này:\n'
          '{"score": <number>, "feedback": "<1-2 câu nhận xét bằng tiếng Việt>", '
          '"strengths": ["<điểm mạnh 1>", "<điểm mạnh 2>"], '
          '"improvements": ["<cần cải thiện 1>"]}\n'
          'Chỉ trả lời JSON, không thêm text khác.';

      final response = await sendMessage(summaryPrompt);

      // Try to parse JSON from response
      final jsonStr = _extractJson(response);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return ConversationSummary(
          score: (data['score'] as num?)?.toInt() ?? 70,
          feedback: data['feedback'] as String? ?? 'Bạn đã giao tiếp tốt!',
          strengths: (data['strengths'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['Tự tin'],
          improvements: (data['improvements'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['Tiếp tục luyện tập'],
        );
      }

      return ConversationSummary(
        score: 70,
        feedback: response,
        strengths: const ['Đã hoàn thành hội thoại'],
        improvements: const ['Tiếp tục luyện tập'],
      );
    } catch (e) {
      debugPrint('[LlmChat] Summary generation failed: $e');
      return ConversationSummary.placeholder();
    }
  }

  /// Extract JSON from a potentially messy LLM response.
  String? _extractJson(String text) {
    // Try the raw text first
    try {
      jsonDecode(text);
      return text;
    } catch (_) {}

    // Try extracting from markdown code block
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      final inner = match.group(1)?.trim();
      if (inner != null) {
        try {
          jsonDecode(inner);
          return inner;
        } catch (_) {}
      }
    }

    // Try finding { ... }
    final braceRegex = RegExp(r'\{[\s\S]*\}');
    final braceMatch = braceRegex.firstMatch(text);
    if (braceMatch != null) {
      final inner = braceMatch.group(0);
      if (inner != null) {
        try {
          jsonDecode(inner);
          return inner;
        } catch (_) {}
      }
    }

    return null;
  }

  /// Clear the conversation history.
  void clearHistory() {
    _history.clear();
    currentScenarioId = null;
  }

  /// Get the number of messages in the current conversation.
  int get messageCount => _history.length;

  /// Get the conversation history for saving.
  List<Map<String, dynamic>> get historyForSave => List.unmodifiable(_history);
}

/// Summary of a completed conversation session.
class ConversationSummary {
  final int score;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;

  const ConversationSummary({
    required this.score,
    required this.feedback,
    required this.strengths,
    required this.improvements,
  });

  factory ConversationSummary.placeholder() {
    return const ConversationSummary(
      score: 0,
      feedback: 'Không thể tạo đánh giá. Hãy thử lại sau.',
      strengths: [],
      improvements: [],
    );
  }
}
