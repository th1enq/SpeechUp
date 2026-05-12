import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../services/speech_input_service.dart';
import '../services/cloud_speech_service.dart';
import '../services/native_speech_service.dart';
import '../services/google_tts_service.dart';
import '../services/local_tts_service.dart';
import '../services/llm_chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/screen_header.dart';
import '../services/firestore_service.dart';

class ConversationScreen extends StatefulWidget {
  final String? initialCustomPrompt;
  final VoidCallback? onInitialPromptConsumed;
  final VoidCallback? onNavigateProfile;

  const ConversationScreen({
    super.key,
    this.initialCustomPrompt,
    this.onInitialPromptConsumed,
    this.onNavigateProfile,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _inConversation = false;
  String? _selectedScenario;
  String? _customPrompt;
  final TextEditingController _customTopicController = TextEditingController();

  final List<_Scenario> _scenarios = [
    _Scenario(
      id: 'cafe',
      title: 'Gọi đồ uống tại quán cà phê',
      description: 'Luyện tập gọi đồ uống và giao tiếp với nhân viên',
      icon: Icons.coffee_rounded,
      color: AppColors.onboardingBlueDeep,
    ),
    _Scenario(
      id: 'shopping',
      title: 'Mua sắm tại cửa hàng',
      description: 'Luyện hỏi giá, chọn đồ và thanh toán',
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFF059669),
    ),
    _Scenario(
      id: 'interview',
      title: 'Phỏng vấn xin việc',
      description: 'Tập trả lời các câu hỏi phỏng vấn một cách tự tin',
      icon: Icons.work_rounded,
      color: AppColors.progressAccentBlue,
    ),
    _Scenario(
      id: 'doctor',
      title: 'Khám bệnh tại phòng khám',
      description: 'Luyện mô tả triệu chứng và hỏi bác sĩ',
      icon: Icons.local_hospital_rounded,
      color: const Color(0xFFDC2626),
    ),
    _Scenario(
      id: 'phone',
      title: 'Gọi điện cho khách hàng',
      description: 'Tập giao tiếp qua điện thoại chuyên nghiệp',
      icon: Icons.phone_in_talk_rounded,
      color: AppColors.onboardingBlue,
    ),
    _Scenario(
      id: 'present',
      title: 'Thuyết trình trước nhóm',
      description: 'Chuẩn bị cho bài thuyết trình trước đồng nghiệp',
      icon: Icons.present_to_all_rounded,
      color: AppColors.progressMilestonePurple,
    ),
  ];

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeInitialPrompt();
    });
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCustomPrompt != oldWidget.initialCustomPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _consumeInitialPrompt();
      });
    }
  }

  void _consumeInitialPrompt() {
    final prompt = widget.initialCustomPrompt?.trim();
    if (prompt == null || prompt.isEmpty || !mounted) return;
    setState(() {
      _selectedScenario = 'custom';
      _customPrompt = prompt;
      _customTopicController.text = prompt;
      _inConversation = true;
    });
    widget.onInitialPromptConsumed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_inConversation && _selectedScenario != null) {
      return _ConversationChat(
        scenario: _scenarios.firstWhere(
          (s) => s.id == _selectedScenario,
          orElse: () => _Scenario(
            id: 'custom',
            title: _customPrompt ?? 'Chủ đề tự do',
            description: 'Hội thoại tự do với AI',
            icon: Icons.chat_rounded,
            color: AppColors.onboardingBlue,
          ),
        ),
        customPrompt: _customPrompt,
        onExit: () {
          setState(() {
            _inConversation = false;
            _selectedScenario = null;
            _customPrompt = null;
          });
        },
        onSaveConversation: (scenarioId, messages, metadata) async {
          if (!isFirebaseSupported) return;
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final firestoreService = FirestoreService();
            await firestoreService.saveConversation(
              userId: user.uid,
              scenarioId: scenarioId,
              messages: messages,
              sessionId: metadata.sessionId,
              scenarioTitle: metadata.scenarioTitle,
              customPrompt: metadata.customPrompt,
              provider: metadata.provider,
              startedAt: metadata.startedAt,
              endedAt: metadata.endedAt,
            );
          }
        },
      );
    }

    final base = GoogleFonts.plusJakartaSans();
    final t = appLanguage.t;
    final compact = MediaQuery.sizeOf(context).width < 370;
    final bottomPadding = 16 + MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, compact ? 6 : 8, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: t('chat.title'),
              subtitle: t('chat.subtitle'),
              onAvatarTap: widget.onNavigateProfile,
            ),
            const SizedBox(height: 22),

            // ── Custom topic input ──
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dashboardNavy.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.edit_rounded,
                    color: AppColors.onboardingBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _customTopicController,
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dashboardNavy,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hoặc nhập chủ đề riêng...',
                        hintStyle: base.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dashboardTextMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.onboardingBlue,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        final topic = _customTopicController.text.trim();
                        if (topic.isEmpty) return;
                        setState(() {
                          _selectedScenario = 'custom';
                          _customPrompt = topic;
                          _inConversation = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scenario grid ──
            ..._scenarios.map(
              (scenario) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScenarioCard(
                  scenario: scenario,
                  onTap: () {
                    setState(() {
                      _selectedScenario = scenario.id;
                      _inConversation = true;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dashboardNavy.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showVoiceSettings(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.dashboardNavPill,
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.onboardingBlueDeep,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cài đặt giọng nói AI',
                                style: base.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dashboardNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tùy chỉnh giọng, tốc độ phản hồi',
                                style: base.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.dashboardTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.dashboardTextMuted.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _VoiceSettingsSheet(),
    );
  }
}

class _Scenario {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ConversationSessionMetadata {
  final String sessionId;
  final String scenarioTitle;
  final String? customPrompt;
  final String provider;
  final DateTime startedAt;
  final DateTime endedAt;

  const ConversationSessionMetadata({
    required this.sessionId,
    required this.scenarioTitle,
    required this.customPrompt,
    required this.provider,
    required this.startedAt,
    required this.endedAt,
  });
}

class _ScenarioCard extends StatelessWidget {
  final _Scenario scenario;
  final VoidCallback onTap;

  const _ScenarioCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: scenario.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(scenario.icon, color: scenario.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        style: base.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: c.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scenario.description,
                        style: base.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scenario.color.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: scenario.color,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Conversation Chat Screen
class _ConversationChat extends StatefulWidget {
  final _Scenario scenario;
  final String? customPrompt;
  final VoidCallback onExit;
  final Future<void> Function(
    String scenarioId,
    List<Map<String, dynamic>> messages,
    ConversationSessionMetadata metadata,
  )?
  onSaveConversation;

  const _ConversationChat({
    required this.scenario,
    this.customPrompt,
    required this.onExit,
    this.onSaveConversation,
  });

  @override
  State<_ConversationChat> createState() => _ConversationChatState();
}

class _ConversationChatState extends State<_ConversationChat> {
  final List<_ChatMessage> _messages = [];
  late final String _sessionId;
  late final DateTime _sessionStartedAt;
  bool _isTyping = false;
  bool _isUserRecording = false;
  bool _isAiSpeaking = false;
  int _nextTurnIndex = 0;
  String? _currentUserPrompt;
  late final SpeechInputService _speechService;
  final GoogleTtsService _ttsService = GoogleTtsService();
  final LocalTtsService _localTtsService = LocalTtsService();
  final AudioPlayer _ttsPlayer = AudioPlayer();
  String? _lastSpeechError;
  final ScrollController _scrollController = ScrollController();
  final LlmChatService _llmService = LlmChatService();
  bool _useLlm = false;
  final TextEditingController _textInputController = TextEditingController();
  bool _showTextInput = false;
  final CloudSpeechService _cloudSpeechService = CloudSpeechService();
  final NativeSpeechService _nativeSpeechService = NativeSpeechService();
  bool _useCloudSpeech = false;
  bool _useNativeSpeech = false;

  // Scripted conversation flows (AI + User full turns).
  static const Map<String, List<_ScriptTurn>> _conversationFlows = {
    'cafe': [
      _ScriptTurn.ai(
        'Xin chào! Chào mừng bạn đến quán cà phê. Bạn muốn dùng gì ạ?',
      ),
      _ScriptTurn.user('Cho mình một ly cà phê sữa đá nhé.'),
      _ScriptTurn.ai('Dạ vâng ạ! Bạn muốn size vừa hay lớn ạ?'),
      _ScriptTurn.user('Size vừa thôi, và cho mình thêm ít đường nhé.'),
      _ScriptTurn.ai(
        'Dạ được ạ! Bạn có muốn dùng thêm bánh ngọt không ạ? Hôm nay quán có croissant bơ mới ra lò rất thơm.',
      ),
      _ScriptTurn.user(
        'Nghe hấp dẫn quá, cho mình một cái croissant luôn nhé!',
      ),
      _ScriptTurn.ai(
        'Tuyệt vời ạ! Một cà phê sữa đá size vừa ít đường và một croissant bơ. Tổng cộng 75 nghìn ạ. Bạn thanh toán bằng tiền mặt hay chuyển khoản ạ?',
      ),
      _ScriptTurn.user('Mình chuyển khoản nhé, cảm ơn bạn.'),
    ],
    'interview': [
      _ScriptTurn.ai(
        'Chào bạn, cảm ơn bạn đã đến phỏng vấn hôm nay. Bạn có thể giới thiệu đôi chút về bản thân mình không?',
      ),
      _ScriptTurn.user(
        'Dạ vâng, em xin chào. Em tên là Mai, em có 3 năm kinh nghiệm trong lĩnh vực truyền thông.',
      ),
      _ScriptTurn.ai(
        'Rất tốt! Vậy điểm mạnh lớn nhất của bạn trong công việc là gì?',
      ),
      _ScriptTurn.user(
        'Điểm mạnh của em là khả năng lên kế hoạch nội dung và quản lý đa nhiệm.',
      ),
      _ScriptTurn.ai(
        'Bạn có thể chia sẻ về một dự án mà bạn tự hào nhất không?',
      ),
      _ScriptTurn.user(
        'Dự án em tự hào nhất là chiến dịch ra mắt sản phẩm mới, giúp tăng 35% lượng khách hàng tiềm năng chỉ sau 2 tháng.',
      ),
    ],
    'phone': [
      _ScriptTurn.ai(
        'Alô, xin chào! Đây là công ty ABC, tôi có thể giúp gì cho anh/chị?',
      ),
      _ScriptTurn.user(
        'Dạ chào anh, em là Mai từ công ty XYZ. Em gọi để trao đổi về đề xuất hợp tác mà bên em đã gửi.',
      ),
      _ScriptTurn.ai(
        'À vâng, tôi đã nhận được đề xuất. Bạn có thể tóm tắt lại các điểm chính không?',
      ),
      _ScriptTurn.user(
        'Dạ vâng. Đề xuất chính là chương trình marketing liên kết, giúp tăng nhận diện thương hiệu cho cả hai bên.',
      ),
      _ScriptTurn.ai('Nghe khá thú vị. Về ngân sách dự kiến thì sao?'),
      _ScriptTurn.user(
        'Ngân sách dự kiến là 200 triệu trong 3 tháng đầu, sau đó sẽ tối ưu theo hiệu quả thực tế.',
      ),
    ],
    'present': [
      _ScriptTurn.ai(
        'Chào mọi người, buổi thuyết trình bắt đầu nhé. Bạn có thể bắt đầu khi sẵn sàng.',
      ),
      _ScriptTurn.user(
        'Kính chào ban giám đốc, hôm nay em xin trình bày về chiến lược phát triển quý 3.',
      ),
      _ScriptTurn.ai(
        'Phần tổng quan rất rõ ràng. Bạn có thể giải thích thêm về mục tiêu doanh thu không?',
      ),
      _ScriptTurn.user(
        'Dạ mục tiêu doanh thu quý 3 là tăng 20% so với quý 2, tập trung vào nhóm khách hàng doanh nghiệp vừa và nhỏ.',
      ),
    ],
  };

  static const Map<String, List<_ScriptTurn>> _englishConversationFlows = {
    'cafe': [
      _ScriptTurn.ai(
        'Hello! Welcome to the coffee shop. What would you like to order today?',
      ),
      _ScriptTurn.user('I would like an iced latte, please.'),
      _ScriptTurn.ai('Of course. Would you like a regular or large size?'),
      _ScriptTurn.user('Regular size, and not too sweet, please.'),
      _ScriptTurn.ai(
        'No problem. Would you like anything to eat with your drink?',
      ),
      _ScriptTurn.user('A butter croissant sounds good. I will take one.'),
    ],
    'interview': [
      _ScriptTurn.ai(
        'Hello, thanks for coming in today. Could you briefly introduce yourself?',
      ),
      _ScriptTurn.user(
        'Yes, my name is Mai. I have three years of experience in communications.',
      ),
      _ScriptTurn.ai('Great. What would you say is your biggest strength?'),
      _ScriptTurn.user(
        'My biggest strength is planning content and managing multiple tasks.',
      ),
    ],
    'phone': [
      _ScriptTurn.ai('Hello, this is ABC Company. How can I help you today?'),
      _ScriptTurn.user(
        'Hello, this is Mai from XYZ Company. I am calling about the proposal we sent.',
      ),
      _ScriptTurn.ai('Sure. Could you summarize the main points for me?'),
      _ScriptTurn.user(
        'The proposal is a partnership campaign to increase brand awareness for both companies.',
      ),
    ],
    'present': [
      _ScriptTurn.ai(
        'Hello everyone. You can start your presentation whenever you are ready.',
      ),
      _ScriptTurn.user(
        'Good morning, everyone. Today I will present our strategy for the next quarter.',
      ),
      _ScriptTurn.ai(
        'The overview is clear. Could you explain the revenue target in more detail?',
      ),
      _ScriptTurn.user(
        'Our target is to increase revenue by 20 percent compared with last quarter.',
      ),
    ],
    'shopping': [
      _ScriptTurn.ai('Hello! Welcome to the store. What are you looking for?'),
      _ScriptTurn.user('I am looking for a comfortable shirt for work.'),
      _ScriptTurn.ai('Sure. Do you prefer a formal or casual style?'),
      _ScriptTurn.user('Something formal, but still easy to wear.'),
    ],
    'doctor': [
      _ScriptTurn.ai('Hello, I am the doctor. What brings you in today?'),
      _ScriptTurn.user('I have had a sore throat for two days.'),
      _ScriptTurn.ai('I see. Do you also have a fever or a cough?'),
      _ScriptTurn.user('I have a mild cough, but no fever.'),
    ],
  };

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _sessionStartedAt = DateTime.now();
    _sessionId =
        '${userId}_${widget.scenario.id}_${_sessionStartedAt.millisecondsSinceEpoch}';
    _speechService = SpeechInputService()..addListener(_handleSpeechUpdate);
    _nativeSpeechService.addListener(_handleNativeSpeechUpdate);
    _ttsPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isAiSpeaking = false);
    });
    _localTtsService.onComplete = () {
      if (!mounted) return;
      setState(() => _isAiSpeaking = false);
    };

    // Pre-check mic availability
    _checkMicAvailability();

    // Custom topics require Gemini because there is no fixed script to follow.
    _useLlm = _llmService.isConfigured;

    if (_useLlm) {
      _llmService.startScenario(
        scenarioId: widget.scenario.id,
        customPrompt: widget.customPrompt,
      );
      _startLlmConversation();
    } else if (widget.customPrompt != null && widget.customPrompt!.isNotEmpty) {
      _showTextInput = true;
      _messages.add(
        _ChatMessage(
          text: appLanguage.locale.languageCode == 'vi'
              ? 'Chủ đề riêng cần GEMINI_API_KEY để tạo hội thoại động. Hãy thêm key vào .env rồi chạy lại ứng dụng.'
              : 'Custom topics require GEMINI_API_KEY to create a dynamic conversation. Add the key to .env and restart the app.',
          isUser: false,
        ),
      );
    } else {
      _pushNextAiTurn();
    }
  }

  Future<void> _checkMicAvailability() async {
    // Try speech_to_text plugin first
    if (_speechService.isSupportedPlatform) {
      final available = await _speechService.initialize(
        localeId: _localeIdForApp(),
      );
      if (available) {
        debugPrint('[Conversation] speech_to_text plugin available');
        _useCloudSpeech = false;
        _useNativeSpeech = false;
        return;
      }
    }

    // Plugin failed → try NativeSpeechService (free, on-device Android SpeechRecognizer)
    debugPrint('[Conversation] Plugin unavailable, trying native speech...');
    if (_nativeSpeechService.isSupportedPlatform) {
      final nativeOk = await _nativeSpeechService.initialize();
      if (nativeOk) {
        debugPrint('[Conversation] Native speech ready! (on-device, free)');
        _useNativeSpeech = true;
        _useCloudSpeech = false;
        return;
      }
    }

    // Native failed → try Cloud Speech-to-Text (records mic + sends to Google API)
    debugPrint('[Conversation] Native unavailable, trying cloud speech...');
    if (_cloudSpeechService.isSupportedPlatform &&
        _cloudSpeechService.isConfigured) {
      final hasMic = await _cloudSpeechService.hasPermission();
      if (hasMic) {
        debugPrint('[Conversation] Cloud speech ready! (mic + Google API)');
        _useCloudSpeech = true;
        _useNativeSpeech = false;
        return;
      }
    }

    // All failed → show text input
    debugPrint('[Conversation] All speech methods failed, showing text input');
    if (mounted) setState(() => _showTextInput = true);
  }

  Future<void> _startLlmConversation() async {
    setState(() => _isTyping = true);
    try {
      final opening = await _llmService.getOpeningMessage();
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: opening, isUser: false));
      });
      _scrollToBottom();
      unawaited(_speakAiMessage(opening));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      debugPrint('[Conversation] LLM opening failed: $e');
    }
  }

  List<_ScriptTurn> get _scriptFlow {
    final flows = appLanguage.locale.languageCode == 'vi'
        ? _conversationFlows
        : _englishConversationFlows;
    return flows[widget.scenario.id] ?? flows['cafe']!;
  }

  void _pushNextAiTurn() {
    if (_nextTurnIndex >= _scriptFlow.length) {
      setState(() => _currentUserPrompt = null);
      return;
    }
    final turn = _scriptFlow[_nextTurnIndex];
    if (!turn.isAi) {
      setState(() => _currentUserPrompt = turn.text);
      return;
    }

    setState(() => _isTyping = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final aiText = _scriptFlow[_nextTurnIndex].text;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: aiText, isUser: false));
        _nextTurnIndex++;
        if (_nextTurnIndex < _scriptFlow.length &&
            !_scriptFlow[_nextTurnIndex].isAi) {
          _currentUserPrompt = _scriptFlow[_nextTurnIndex].text;
        } else {
          _currentUserPrompt = null;
        }
      });
      _scrollToBottom();
      unawaited(_speakAiMessage(aiText));
    });
  }

  Future<void> _toggleRecording() async {
    if (_isTyping) return;
    if (!_useLlm && _currentUserPrompt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không còn câu mẫu để luyện ở kịch bản này.'),
        ),
      );
      return;
    }

    // Stop recording
    if (_isUserRecording) {
      if (_useNativeSpeech) {
        // Native speech auto-delivers results via event stream
        await _nativeSpeechService.stopListening();
        setState(() => _isUserRecording = false);
      } else if (_useCloudSpeech) {
        // Stop recording and transcribe via cloud
        setState(() => _isUserRecording = false);
        final text = await _cloudSpeechService.stopListening(
          languageCode: appLanguage.speechLanguageCode,
        );
        if (text.isNotEmpty) {
          debugPrint('[Conversation] Cloud speech result: $text');
          _submitCloudRecognizedMessage(text);
        } else if (mounted) {
          final err = _cloudSpeechService.lastError;
          if (err != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Nhận dạng lỗi: $err')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không nhận được giọng nói')),
            );
          }
        }
      } else {
        await _speechService.stopListening();
      }
      return;
    }

    if (_isAiSpeaking) {
      await _stopAiVoice();
    }

    // Start recording with native speech (on-device, free)
    if (_useNativeSpeech) {
      _nativeSpeechService.resetSession();
      _lastSpeechError = null;
      final didStart = await _nativeSpeechService.startListening(
        locale: appLanguage.speechLanguageCode,
      );
      if (didStart) {
        setState(() => _isUserRecording = true);
        debugPrint('[Conversation] Native speech recording started');
      } else if (mounted) {
        setState(() => _showTextInput = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mic lỗi: ${_nativeSpeechService.errorSummary}'),
          ),
        );
      }
      return;
    }

    // Start recording with cloud speech
    if (_useCloudSpeech) {
      _cloudSpeechService.resetSession();
      _lastSpeechError = null;
      final didStart = await _cloudSpeechService.startListening(
        locale: appLanguage.speechLanguageCode,
      );
      if (didStart) {
        setState(() => _isUserRecording = true);
        debugPrint('[Conversation] Cloud recording started');
      } else if (mounted) {
        setState(() => _showTextInput = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mic lỗi: ${_cloudSpeechService.errorSummary}'),
          ),
        );
      }
      return;
    }

    // Try plugin speech service
    if (!_speechService.isSupportedPlatform) {
      if (mounted) {
        setState(() => _showTextInput = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mic không khả dụng — hãy dùng bàn phím để nhập tin nhắn.',
            ),
          ),
        );
      }
      return;
    }

    _speechService.resetSession();
    _lastSpeechError = null;
    final didStart = await _speechService.startListening(
      localeId: _localeIdForApp(),
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 3),
    );
    if (!didStart && mounted) {
      setState(() => _showTextInput = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể bật mic — hãy dùng bàn phím để nhập tin nhắn.',
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Save conversation before disposing
    if (_messages.isNotEmpty && widget.onSaveConversation != null) {
      final messageMaps = _messages
          .map(
            (m) => {
              'text': m.text,
              'isUser': m.isUser,
              'role': m.isUser ? 'user' : 'assistant',
            },
          )
          .toList();
      widget.onSaveConversation!(
        widget.scenario.id,
        messageMaps,
        ConversationSessionMetadata(
          sessionId: _sessionId,
          scenarioTitle: widget.scenario.title,
          customPrompt: widget.customPrompt,
          provider: _useLlm ? 'gemini' : 'scripted',
          startedAt: _sessionStartedAt,
          endedAt: DateTime.now(),
        ),
      );
    }
    _speechService
      ..removeListener(_handleSpeechUpdate)
      ..cancelListening();
    _nativeSpeechService.removeListener(_handleNativeSpeechUpdate);
    unawaited(_nativeSpeechService.cancelListening());
    unawaited(_cloudSpeechService.cancelListening());
    unawaited(_stopAiVoice());
    _ttsPlayer.dispose();
    _localTtsService.stop();
    _scrollController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.surfaceBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textHeading),
          onPressed: widget.onExit,
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.scenario.color.withValues(alpha: 0.12),
              ),
              child: Icon(
                widget.scenario.icon,
                color: widget.scenario.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scenario.title,
                    style: base.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isTyping)
                    Text(
                      _isAiSpeaking ? 'Đang phát giọng...' : 'Đang trả lời...',
                      style: base.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.accentBlue,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, size: 22, color: c.textHeading),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const _VoiceSettingsSheet(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 22, color: c.textHeading),
            onPressed: widget.onExit,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const TypingIndicator();
                }
                final msg = _messages[index];
                return ChatBubble(message: msg.text, isUser: msg.isUser);
              },
            ),
          ),
          if (_isUserRecording || _activeRecognizedText.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.accentBlue.withValues(alpha: 0.18)),
              ),
              child: Text(
                _activeRecognizedText.isEmpty
                    ? appLanguage.t('practice.listening')
                    : _activeRecognizedText,
                style: base.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _activeRecognizedText.isEmpty
                      ? c.textMuted
                      : c.textHeading,
                  height: 1.4,
                ),
              ),
            ),
          if (_currentUserPrompt != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: c.accentPurple.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Câu mẫu cần đọc',
                    style: base.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentUserPrompt!,
                    style: base.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textHeading,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          // ── Text input area (shown when mic unavailable) ──
          if (_showTextInput)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: c.surfaceBg,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textInputController,
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textHeading,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: base.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: c.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: c.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: c.accentBlue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: c.cardBg,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: c.accentBlue,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _submitTextMessage,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: c.surfaceBg,
              boxShadow: [
                BoxShadow(
                  color: c.shadowColor.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: const Color(0xFFFFEBEE),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: widget.onExit,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                MicButton(
                  isRecording: _isUserRecording,
                  onTap: () => _toggleRecording(),
                  size: 64,
                ),
                const SizedBox(width: 14),
                // Toggle text input button
                Material(
                  color: _showTextInput
                      ? c.accentBlue.withValues(alpha: 0.15)
                      : AppColors.dashboardNavPill,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      setState(() => _showTextInput = !_showTextInput);
                    },
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        _showTextInput
                            ? Icons.keyboard_hide_rounded
                            : Icons.keyboard_rounded,
                        color: _showTextInput
                            ? c.accentBlue
                            : AppColors.onboardingBlueDeep,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Material(
                  color: AppColors.dashboardNavPill,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const _VoiceSettingsSheet(),
                      );
                    },
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.onboardingBlueDeep,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the currently recognized text from whichever speech service is active.
  String get _activeRecognizedText {
    if (_useNativeSpeech) return _nativeSpeechService.recognizedText;
    if (_useCloudSpeech) return _cloudSpeechService.recognizedText;
    return _speechService.recognizedText;
  }

  void _handleSpeechUpdate() {
    if (!mounted) return;
    final isListening = _speechService.isListening;
    final error = _speechService.lastError;
    final justFinishedRecording = _isUserRecording && !isListening;
    if (_isUserRecording != isListening) {
      setState(() {
        _isUserRecording = isListening;
      });
    } else {
      setState(() {});
    }

    if (justFinishedRecording) {
      _submitRecognizedMessage();
    }

    if (error != null &&
        error.isNotEmpty &&
        !isListening &&
        error != _lastSpeechError) {
      _lastSpeechError = error;
      if (!_showTextInput) {
        setState(() => _showTextInput = true);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mic lỗi: $error')));
    }
  }

  /// Handle updates from native Android speech recognizer.
  void _handleNativeSpeechUpdate() {
    if (!mounted) return;
    final isListening = _nativeSpeechService.isListening;
    final error = _nativeSpeechService.lastError;
    final text = _nativeSpeechService.recognizedText;

    // Update recording state
    if (_isUserRecording != isListening) {
      setState(() => _isUserRecording = isListening);
    } else {
      setState(() {});
    }

    // If we got a final result and stopped listening, submit it
    if (!isListening && text.isNotEmpty && !_isUserRecording) {
      debugPrint('[Conversation] Native speech result: $text');
      _submitCloudRecognizedMessage(text); // Reuse same submission logic
      _nativeSpeechService.resetSession();
      return;
    }

    // Handle errors
    if (error != null &&
        error.isNotEmpty &&
        !isListening &&
        error != _lastSpeechError) {
      _lastSpeechError = error;
      if (!_showTextInput) {
        setState(() => _showTextInput = true);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mic lỗi: $error')));
    }
  }

  /// Submit text recognized by cloud speech service.
  void _submitCloudRecognizedMessage(String text) {
    if (text.isEmpty) return;
    _cloudSpeechService.resetSession();

    if (_useLlm) {
      _submitLlmMessage(text);
      return;
    }

    // Scripted flow
    if (_currentUserPrompt == null || _nextTurnIndex >= _scriptFlow.length) {
      return;
    }
    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _nextTurnIndex++;
      _currentUserPrompt = null;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pushNextAiTurn();
    });
  }

  void _submitRecognizedMessage() {
    final transcript = _speechService.recognizedText;
    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLanguage.t('practice.noSpeechDetected'))),
      );
      _speechService.resetSession();
      return;
    }

    if (_useLlm) {
      _submitLlmMessage(transcript);
      return;
    }

    // Scripted flow
    if (_currentUserPrompt == null || _nextTurnIndex >= _scriptFlow.length) {
      _speechService.resetSession();
      return;
    }

    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) {
      _speechService.resetSession();
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: expected.text, isUser: true));
      _nextTurnIndex++;
      _currentUserPrompt = null;
    });
    _speechService.resetSession();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pushNextAiTurn();
    });
  }

  void _submitTextMessage() {
    final text = _textInputController.text.trim();
    if (text.isEmpty || _isTyping) return;
    _textInputController.clear();

    if (_useLlm) {
      _submitLlmMessage(text);
      return;
    }

    // Scripted flow: just add user text and push next AI turn
    if (_currentUserPrompt == null || _nextTurnIndex >= _scriptFlow.length) {
      return;
    }

    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _nextTurnIndex++;
      _currentUserPrompt = null;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pushNextAiTurn();
    });
  }

  Future<void> _submitLlmMessage(String userText) async {
    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _isTyping = true;
    });
    _speechService.resetSession();
    _scrollToBottom();

    try {
      final reply = await _llmService.sendMessage(userText);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
      unawaited(_speakAiMessage(reply));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI error: $e')));
    }
  }

  String _localeIdForApp() {
    return appLanguage.speechLocaleId;
  }

  Future<void> _speakAiMessage(String text) async {
    if (text.trim().isEmpty) return;
    debugPrint(
      '[Conversation] _speakAiMessage called, text length: ${text.length}',
    );

    // Try Google TTS first (cloud, higher quality)
    if (_ttsService.isConfigured) {
      try {
        debugPrint('[Conversation] Trying Google Cloud TTS...');
        if (mounted) setState(() => _isAiSpeaking = true);
        final ttsConfig = await _resolveVietnameseTtsConfig();
        final bytes = await _ttsService.synthesize(
          text: text,
          languageCode: appLanguage.speechLanguageCode,
          voiceName: ttsConfig.voiceName,
          speakingRate: ttsConfig.speed,
        );
        await _ttsPlayer.stop();
        await _ttsPlayer.play(BytesSource(bytes), volume: 1.0);
        debugPrint('[Conversation] Google TTS playing successfully');
        return;
      } catch (e) {
        debugPrint(
          '[Conversation] Google TTS failed: $e, falling back to local TTS',
        );
      }
    } else {
      debugPrint('[Conversation] Google TTS not configured, using local TTS');
    }

    // Fallback: on-device TTS (no API key needed)
    try {
      debugPrint('[Conversation] Trying local TTS (flutter_tts)...');
      if (mounted) setState(() => _isAiSpeaking = true);
      final prefs = await SharedPreferences.getInstance();
      final speed = (prefs.getDouble('profile_ai_voice_speed') ?? 1.0).clamp(
        0.8,
        1.3,
      );
      // flutter_tts uses 0.0-1.0 range, map from 0.8-1.3 -> 0.35-0.65
      final ttsSpeed = 0.35 + (speed - 0.8) * 0.6;
      debugPrint('[Conversation] Local TTS speed: $ttsSpeed');
      await _localTtsService.speak(
        text,
        language: appLanguage.speechLanguageCode,
        speakingRate: ttsSpeed,
      );
    } catch (e) {
      debugPrint('[Conversation] Local TTS also failed: $e');
      if (mounted) setState(() => _isAiSpeaking = false);
    }
  }

  Future<void> _stopAiVoice() async {
    await _ttsPlayer.stop();
    await _localTtsService.stop();
    if (!mounted) return;
    setState(() => _isAiSpeaking = false);
  }

  Future<({String voiceName, double speed})>
  _resolveVietnameseTtsConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = (prefs.getString('profile_ai_voice_tone') ?? 'Balanced')
        .toLowerCase();
    final speed = (prefs.getDouble('profile_ai_voice_speed') ?? 1.0).clamp(
      0.8,
      1.3,
    );

    String voiceName;
    if (appLanguage.locale.languageCode != 'vi') {
      voiceName = tone.contains('energetic')
          ? 'en-US-Standard-D'
          : tone.contains('calm')
          ? 'en-US-Standard-B'
          : 'en-US-Standard-C';
    } else if (tone.contains('calm')) {
      voiceName = 'vi-VN-Standard-B';
    } else if (tone.contains('energetic')) {
      voiceName = 'vi-VN-Standard-D';
    } else {
      voiceName = 'vi-VN-Standard-A';
    }
    return (voiceName: voiceName, speed: speed);
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _ScriptTurn {
  final String text;
  final bool isAi;

  const _ScriptTurn.ai(this.text) : isAi = true;
  const _ScriptTurn.user(this.text) : isAi = false;
}

// Voice Settings Bottom Sheet
class _VoiceSettingsSheet extends StatefulWidget {
  const _VoiceSettingsSheet();

  @override
  State<_VoiceSettingsSheet> createState() => _VoiceSettingsSheetState();
}

class _VoiceSettingsSheetState extends State<_VoiceSettingsSheet> {
  int _selectedVoice = 1;
  double _speed = 1.0;
  bool _isLoading = true;
  bool _isPreviewing = false;
  final LocalTtsService _localTtsService = LocalTtsService();
  void Function()? _previousLocalTtsComplete;

  final List<Map<String, dynamic>> _voices = [
    {
      'name': 'Calm',
      'icon': Icons.person_rounded,
      'color': AppColors.onboardingBlueDeep,
    },
    {
      'name': 'Balanced',
      'icon': Icons.person_rounded,
      'color': AppColors.onboardingBlue,
    },
    {
      'name': 'Energetic',
      'icon': Icons.person_rounded,
      'color': AppColors.progressAccentBlue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _previousLocalTtsComplete = _localTtsService.onComplete;
    _localTtsService.onComplete = () {
      if (mounted) setState(() => _isPreviewing = false);
    };
  }

  @override
  void dispose() {
    _localTtsService.stop();
    _localTtsService.onComplete = _previousLocalTtsComplete;
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = (prefs.getString('profile_ai_voice_tone') ?? 'Balanced')
        .toLowerCase();
    final speed = prefs.getDouble('profile_ai_voice_speed') ?? 1.0;
    if (!mounted) return;
    setState(() {
      if (tone.contains('calm')) {
        _selectedVoice = 0;
      } else if (tone.contains('energetic')) {
        _selectedVoice = 2;
      } else {
        _selectedVoice = 1;
      }
      _speed = speed.clamp(0.8, 1.3);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final c = context.colors;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dashboardTextMuted.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Cài đặt giọng nói AI',
            style: base.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textHeading,
            ),
          ),
          const SizedBox(height: 24),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chọn giọng nói',
              style: base.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: c.textHeading,
              ),
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(_voices.length, (i) {
            final voice = _voices[i];
            final isSelected = _selectedVoice == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedVoice = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (voice['color'] as Color).withValues(alpha: 0.09)
                      : c.metricRowBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? (voice['color'] as Color).withValues(alpha: 0.45)
                        : c.borderColor.withValues(alpha: 0.55),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (voice['color'] as Color).withValues(
                          alpha: 0.15,
                        ),
                      ),
                      child: Icon(
                        voice['icon'] as IconData,
                        color: voice['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        voice['name'] as String,
                        style: base.copyWith(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: c.textHeading,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _previewVoice(i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (voice['color'] as Color).withValues(
                            alpha: 0.12,
                          ),
                        ),
                        child: Icon(
                          _isPreviewing && isSelected
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: voice['color'] as Color,
                          size: 18,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: voice['color'] as Color,
                        size: 22,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tốc độ nói',
              style: base.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: c.textHeading,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Chậm',
                style: base.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.8,
                  max: 1.3,
                  divisions: 5,
                  activeColor: c.accentBlue,
                  inactiveColor: c.accentBlue.withValues(alpha: 0.18),
                  label: _speed == 1.0
                      ? 'Bình thường'
                      : _speed == 1.1
                      ? 'Nhanh'
                      : _speed < 1.0
                      ? 'Chậm'
                      : 'Rất nhanh',
                  onChanged: (v) => setState(() => _speed = v),
                ),
              ),
              Text(
                'Nhanh',
                style: base.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _saveAndClose();
                },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.dashboardHeroGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Lưu cài đặt',
                      style: base.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndClose() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = switch (_selectedVoice) {
      0 => 'Calm',
      2 => 'Energetic',
      _ => 'Balanced',
    };
    await prefs.setString('profile_ai_voice_tone', tone);
    await prefs.setDouble('profile_ai_voice_speed', _speed);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu cài đặt giọng nói AI',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.progressAccentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _previewVoice(int index) async {
    setState(() {
      _selectedVoice = index;
      _isPreviewing = true;
    });

    final speed = (0.35 + (_speed - 0.8) * 0.6).clamp(0.0, 1.0);
    try {
      await _localTtsService.stop();
      await _localTtsService.speak(
        appLanguage.locale.languageCode == 'vi'
            ? 'Xin chào, đây là bản nghe thử giọng nói AI của SpeechUp.'
            : 'Hello, this is a SpeechUp AI voice preview.',
        language: appLanguage.speechLanguageCode,
        speakingRate: speed,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPreviewing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể phát nghe thử: $e')));
    }
  }
}
