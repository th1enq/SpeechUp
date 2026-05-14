import 'dart:async';
import 'dart:io' show Directory, File;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../models/pronunciation_result.dart';
import '../services/speech_input_service.dart';
import '../services/cloud_speech_service.dart';
import '../services/native_speech_service.dart';
import '../services/azure_pronunciation_service.dart';
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
    final c = context.colors;
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

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: c.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: c.accentBlue.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLanguage.locale.languageCode == 'vi'
                        ? 'Luyện hội thoại theo tình huống'
                        : 'Practice by real situations',
                    style: base.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLanguage.locale.languageCode == 'vi'
                        ? 'Chọn mẫu có sẵn hoặc nhập chủ đề riêng. App sẽ nghe đúng câu bạn nói và chỉ ra chỗ chưa khớp.'
                        : 'Choose a preset or enter your own topic. The app keeps your transcript and highlights mismatches.',
                    style: base.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.edit_rounded, color: c.accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _customTopicController,
                            style: base.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dashboardNavy,
                            ),
                            decoration: InputDecoration(
                              hintText: appLanguage.locale.languageCode == 'vi'
                                  ? 'Nhập chủ đề riêng...'
                                  : 'Enter a custom topic...',
                              hintStyle: base.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                          color: c.accentBlue,
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
                color: c.cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.borderColor.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: c.shadowColor.withValues(alpha: 0.35),
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
                                  color: c.textHeading,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tùy chỉnh giọng, tốc độ phản hồi',
                                style: base.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: c.textMuted,
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
  final List<PronunciationResult> _turnPronunciationResults = [];
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
  final AudioPlayer _scorePlayer = AudioPlayer();
  String? _lastSpeechError;
  final ScrollController _scrollController = ScrollController();
  final LlmChatService _llmService = LlmChatService();
  bool _useLlm = false;
  final TextEditingController _textInputController = TextEditingController();
  bool _showTextInput = false;
  final CloudSpeechService _cloudSpeechService = CloudSpeechService();
  final NativeSpeechService _nativeSpeechService = NativeSpeechService();
  final AudioRecorder _assessmentRecorder = AudioRecorder();
  bool _useCloudSpeech = false;
  bool _useNativeSpeech = false;
  bool _useAzureOnlySpeech = false;
  bool _isAssessingPronunciation = false;
  bool _didShowOverallPronunciationSummary = false;
  int _scoreTotal = 0;
  int _scoreCombo = 0;
  int _scoreEventSerial = 0;
  _ScoreEvent? _latestScoreEvent;
  String? _assessmentAudioPath;
  bool get _isCustomScenario =>
      widget.customPrompt != null && widget.customPrompt!.trim().isNotEmpty;

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

    // Preset scenarios use local scripts to avoid unnecessary Gemini calls.
    // Gemini is reserved for custom topics only.
    _useLlm = _isCustomScenario && _llmService.isConfigured;

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
              ? 'Chủ đề riêng cần Gemini để tạo hội thoại động. Hiện chưa có key hoặc Gemini đang tạm giới hạn, bạn vẫn có thể nhập câu để luyện phản xạ.'
              : 'Custom topics need Gemini for dynamic replies. Gemini is not configured or is temporarily limited, but you can still type to practice.',
          isUser: false,
          assessment: null,
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
        _messages.add(
          _ChatMessage(text: opening, isUser: false, assessment: null),
        );
      });
      _scrollToBottom();
      unawaited(_speakAiMessage(opening));
    } catch (e) {
      if (!mounted) return;
      final message = _rateLimitFallbackMessage();
      setState(() {
        _isTyping = false;
        _useLlm = false;
        _showTextInput = true;
        _messages.add(
          _ChatMessage(text: message, isUser: false, assessment: null),
        );
      });
      _scrollToBottom();
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
      _showOverallPronunciationSummary();
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
        _messages.add(
          _ChatMessage(text: aiText, isUser: false, assessment: null),
        );
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
      if (_nextTurnIndex >= _scriptFlow.length) {
        _showOverallPronunciationSummary();
      }
    });
  }

  void _showOverallPronunciationSummary() {
    if (_didShowOverallPronunciationSummary ||
        _turnPronunciationResults.isEmpty ||
        !mounted) {
      return;
    }
    _didShowOverallPronunciationSummary = true;

    double avg(double Function(PronunciationResult result) pick) {
      final total = _turnPronunciationResults.fold<double>(
        0,
        (sum, result) => sum + pick(result),
      );
      return total / _turnPronunciationResults.length;
    }

    final accuracy = avg((result) => result.accuracyScore);
    final fluency = avg((result) => result.fluencyScore);
    final completeness = avg((result) => result.completenessScore);
    final overall = avg((result) => result.overallScore);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _showScoreEvent(
        score: overall.round(),
        accuracy: accuracy.round(),
        fluency: fluency.round(),
        completeness: completeness.round(),
        shouldRetry: false,
        isFinal: true,
      );
    });
  }

  Future<void> _toggleRecording() async {
    if (_isTyping) return;
    if (!_useLlm && !_isCustomScenario && _currentUserPrompt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không còn câu mẫu để luyện ở kịch bản này.'),
        ),
      );
      return;
    }

    // Stop recording
    if (_isUserRecording) {
      if (_useAzureOnlySpeech) {
        setState(() => _isUserRecording = false);
        await _submitAzureOnlyRecording();
      } else if (_useNativeSpeech) {
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
          await _submitCloudRecognizedMessage(text);
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

    if (_shouldUseAzureOnlySpeech) {
      final didStart = await _startAssessmentRecording();
      if (didStart) {
        setState(() {
          _useAzureOnlySpeech = true;
          _isUserRecording = true;
        });
        debugPrint('[Conversation] Azure-only assessment recording started');
        return;
      }
    }

    // Start recording with native speech (on-device, free)
    if (_useNativeSpeech) {
      _nativeSpeechService.resetSession();
      _lastSpeechError = null;
      await _startAssessmentRecording();
      final didStart = await _nativeSpeechService.startListening(
        locale: appLanguage.speechLanguageCode,
      );
      if (didStart) {
        setState(() => _isUserRecording = true);
        debugPrint('[Conversation] Native speech recording started');
      } else if (mounted) {
        await _discardAssessmentRecording();
        if (!mounted) return;
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
    await _startAssessmentRecording();
    final didStart = await _speechService.startListening(
      localeId: _localeIdForApp(),
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 3),
    );
    if (!didStart && await _startNativeSpeechFallback()) {
      return;
    }
    if (!didStart && mounted) {
      await _discardAssessmentRecording();
      if (!mounted) return;
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

  Future<bool> _startNativeSpeechFallback() async {
    if (!_nativeSpeechService.isSupportedPlatform) return false;

    final nativeOk = await _nativeSpeechService.initialize();
    if (!nativeOk) return false;

    _speechService.resetSession();
    _nativeSpeechService.resetSession();
    _lastSpeechError = null;
    final didStart = await _nativeSpeechService.startListening(
      locale: appLanguage.speechLanguageCode,
    );
    if (!didStart) return false;

    if (mounted) {
      setState(() {
        _useNativeSpeech = true;
        _useCloudSpeech = false;
        _isUserRecording = true;
      });
    }
    debugPrint('[Conversation] Fallback native speech recording started');
    return true;
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
              if (m.assessment != null) ...{
                'expectedText': m.assessment!.expectedText,
                'spokenText': m.assessment!.spokenText,
                'accuracy': m.assessment!.accuracy,
                'feedback': m.assessment!.feedback,
                if (m.assessment!.azureResult != null) ...{
                  'azureAccuracyScore':
                      m.assessment!.azureResult!.accuracyScore,
                  'azureFluencyScore': m.assessment!.azureResult!.fluencyScore,
                  'azureCompletenessScore':
                      m.assessment!.azureResult!.completenessScore,
                  'azureProsodyScore': m.assessment!.azureResult!.prosodyScore,
                  'azureOverallScore': m.assessment!.azureResult!.overallScore,
                },
                'issues': m.assessment!.issues
                    .map(
                      (issue) => {
                        'type': issue.type.name,
                        'expected': issue.expected,
                        'actual': issue.actual,
                      },
                    )
                    .toList(),
              },
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
          provider: _useLlm
              ? 'gemini'
              : _isCustomScenario
              ? 'offline-custom'
              : 'scripted',
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
    _scorePlayer.dispose();
    _localTtsService.stop();
    _assessmentRecorder.dispose();
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
                  if (_isTyping || _isAssessingPronunciation)
                    Text(
                      _isAssessingPronunciation
                          ? 'Azure đang chấm phát âm...'
                          : _isAiSpeaking
                          ? 'Đang phát giọng...'
                          : 'Đang trả lời...',
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
              itemCount:
                  _messages.length +
                  ((_isTyping || _isAssessingPronunciation) ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length &&
                    (_isTyping || _isAssessingPronunciation)) {
                  return const TypingIndicator();
                }
                final msg = _messages[index];
                return _AssessedChatBubble(message: msg);
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
          if (_latestScoreEvent != null)
            _ScoreRewardPanel(
              key: ValueKey(_latestScoreEvent!.serial),
              event: _latestScoreEvent!,
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

  void _showScoreEvent({
    required int score,
    required int accuracy,
    required int fluency,
    required int completeness,
    required bool shouldRetry,
    bool isFinal = false,
  }) {
    final normalizedScore = score.clamp(0, 100).toInt();
    final earnedPoints =
        (isFinal
                ? math.max(25, normalizedScore * 2)
                : shouldRetry
                ? math.max(8, (normalizedScore * 0.45).round())
                : math.max(15, normalizedScore))
            .toInt();

    if (!shouldRetry && !isFinal && normalizedScore >= 70) {
      _scoreCombo++;
    } else if (shouldRetry) {
      _scoreCombo = 0;
    }

    setState(() {
      _scoreTotal += earnedPoints;
      _latestScoreEvent = _ScoreEvent(
        serial: ++_scoreEventSerial,
        points: earnedPoints,
        score: normalizedScore,
        accuracy: accuracy.clamp(0, 100).toInt(),
        fluency: fluency.clamp(0, 100).toInt(),
        completeness: completeness.clamp(0, 100).toInt(),
        total: _scoreTotal,
        combo: _scoreCombo,
        shouldRetry: shouldRetry,
        isFinal: isFinal,
      );
    });
    unawaited(_playScoreSound());
  }

  void _showScoreFromAssessment(
    _SpeechAssessment assessment, {
    required bool shouldRetry,
  }) {
    final azure = assessment.azureResult;
    _showScoreEvent(
      score: assessment.accuracy,
      accuracy: azure?.accuracyScore.round() ?? assessment.accuracy,
      fluency: azure?.fluencyScore.round() ?? assessment.accuracy,
      completeness:
          azure?.completenessScore.round() ??
          ((assessment.matchedWords / math.max(1, assessment.expectedWords)) *
                  100)
              .round(),
      shouldRetry: shouldRetry,
    );
  }

  Future<void> _playScoreSound() async {
    try {
      await _scorePlayer.stop();
      await _scorePlayer.setVolume(0.78);
      await _scorePlayer.play(AssetSource('audio/score_pickup.wav'));
    } catch (e) {
      debugPrint('[Conversation] Score sound failed: $e');
    }
  }

  /// Returns the currently recognized text from whichever speech service is active.
  String get _activeRecognizedText {
    if (_useAzureOnlySpeech) return '';
    if (_useNativeSpeech) return _nativeSpeechService.recognizedText;
    if (_useCloudSpeech) return _cloudSpeechService.recognizedText;
    return _speechService.recognizedText;
  }

  void _handleSpeechUpdate() {
    if (!mounted) return;
    if (_useAzureOnlySpeech || _useNativeSpeech || _useCloudSpeech) return;
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
      unawaited(_submitRecognizedMessage());
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
    if (_useAzureOnlySpeech) return;
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
      unawaited(
        _submitCloudRecognizedMessage(text),
      ); // Reuse same submission logic
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

  bool get _shouldUseAzureOnlySpeech {
    return !_isCustomScenario &&
        _currentUserPrompt != null &&
        AzurePronunciationService().isConfigured;
  }

  Future<void> _submitAzureOnlyRecording() async {
    final expectedText = _currentUserPrompt;
    if (expectedText == null || _nextTurnIndex >= _scriptFlow.length) {
      await _discardAssessmentRecording();
      _useAzureOnlySpeech = false;
      return;
    }

    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) {
      await _discardAssessmentRecording();
      _useAzureOnlySpeech = false;
      return;
    }

    final audioBytes = await _consumeAssessmentAudioBytes();
    if (audioBytes == null) {
      _useAzureOnlySpeech = false;
      if (!mounted) return;
      setState(() => _showTextInput = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lấy được audio để chấm phát âm.')),
      );
      return;
    }

    PronunciationResult? azureResult;
    if (mounted) setState(() => _isAssessingPronunciation = true);
    try {
      azureResult = await AzurePronunciationService().assess(
        audioBytes: audioBytes,
        referenceText: expected.text,
        language: appLanguage.speechLanguageCode,
      );
      debugPrint(
        '[Conversation] Azure recognized user sentence: "${azureResult.recognizedText}"',
      );
    } catch (e) {
      debugPrint('[Conversation] Azure-only assessment failed: $e');
    } finally {
      _useAzureOnlySpeech = false;
      if (mounted) setState(() => _isAssessingPronunciation = false);
    }

    if (!mounted) return;
    if (azureResult == null) {
      setState(() => _showTextInput = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Azure chấm phát âm lỗi. Hãy thử lại.')),
      );
      return;
    }

    final spokenText = azureResult.recognizedText.isNotEmpty
        ? azureResult.recognizedText
        : azureResult.words.map((word) => word.word).join(' ').trim();
    final displayedSpokenText = spokenText.isNotEmpty
        ? spokenText
        : (appLanguage.locale.languageCode == 'vi'
              ? 'Azure không nhận dạng được câu người dùng đọc'
              : 'Azure could not recognize the user sentence');
    final shouldRetry = _shouldRetryPronunciation(azureResult);

    setState(() {
      _messages.add(
        _ChatMessage(text: displayedSpokenText, isUser: true, assessment: null),
      );
      if (shouldRetry) {
        _currentUserPrompt = expected.text;
      } else {
        _turnPronunciationResults.add(azureResult!);
        _nextTurnIndex++;
        _currentUserPrompt = null;
      }
    });
    _showScoreEvent(
      score: azureResult.overallScore.round(),
      accuracy: azureResult.accuracyScore.round(),
      fluency: azureResult.fluencyScore.round(),
      completeness: azureResult.completenessScore.round(),
      shouldRetry: shouldRetry,
    );
    _scrollToBottom();

    if (!mounted || shouldRetry) return;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _pushNextAiTurn();
    });
  }

  bool _shouldRetryPronunciation(PronunciationResult result) {
    return result.overallScore < 60 ||
        result.accuracyScore < 55 ||
        result.completenessScore < 60;
  }

  Future<_SpeechAssessment> _buildSpeechAssessment({
    required String expectedText,
    required String spokenText,
  }) async {
    PronunciationResult? azureResult;
    final azureService = AzurePronunciationService();
    final audioBytes = await _consumeAssessmentAudioBytes();

    if (azureService.isConfigured && audioBytes != null) {
      if (mounted) setState(() => _isAssessingPronunciation = true);
      try {
        azureResult = await azureService.assess(
          audioBytes: audioBytes,
          referenceText: expectedText,
          language: appLanguage.speechLanguageCode,
        );
        debugPrint(
          '[Conversation] Azure recognized user sentence: "${azureResult.recognizedText}"',
        );
      } catch (e) {
        debugPrint('[Conversation] Azure pronunciation assessment failed: $e');
      } finally {
        if (mounted) setState(() => _isAssessingPronunciation = false);
      }
    }

    return _SpeechAssessment.compare(
      expectedText: expectedText,
      spokenText: spokenText,
      azureResult: azureResult,
    );
  }

  Future<bool> _startAssessmentRecording() async {
    final azureService = AzurePronunciationService();
    if (!azureService.isConfigured || _useCloudSpeech) return false;

    if (await _assessmentRecorder.isRecording()) {
      await _assessmentRecorder.stop();
    }

    final hasPermission = await _assessmentRecorder.hasPermission();
    if (!hasPermission) return false;

    final dir = Directory.systemTemp;
    _assessmentAudioPath =
        '${dir.path}/chat_assessment_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _assessmentRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _assessmentAudioPath!,
    );
    return true;
  }

  Future<Uint8List?> _consumeAssessmentAudioBytes() async {
    if (_useCloudSpeech) {
      return _cloudSpeechService.lastRecordedAudioBytes;
    }

    try {
      final path = await _assessmentRecorder.stop();
      final targetPath = path ?? _assessmentAudioPath;
      _assessmentAudioPath = null;
      if (targetPath == null || targetPath.isEmpty) return null;
      final file = File(targetPath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      await file.delete().catchError((_) => file);
      if (bytes.length < 1000) return null;
      return bytes;
    } catch (_) {
      _assessmentAudioPath = null;
      return null;
    }
  }

  Future<void> _discardAssessmentRecording() async {
    try {
      if (await _assessmentRecorder.isRecording()) {
        final path = await _assessmentRecorder.stop();
        final targetPath = path ?? _assessmentAudioPath;
        if (targetPath != null && targetPath.isNotEmpty) {
          final file = File(targetPath);
          if (await file.exists()) {
            await file.delete().catchError((_) => file);
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup only.
    } finally {
      _assessmentAudioPath = null;
      _useAzureOnlySpeech = false;
      if (mounted && _isAssessingPronunciation) {
        setState(() => _isAssessingPronunciation = false);
      }
    }
  }

  /// Submit text recognized by cloud speech service.
  Future<void> _submitCloudRecognizedMessage(String text) async {
    if (text.isEmpty) {
      await _discardAssessmentRecording();
      return;
    }
    _cloudSpeechService.resetSession();
    _nativeSpeechService.resetSession();

    if (_useLlm) {
      await _discardAssessmentRecording();
      _submitLlmMessage(text);
      return;
    }
    if (_isCustomScenario) {
      await _discardAssessmentRecording();
      _submitLocalCustomMessage(text);
      return;
    }

    // Scripted flow
    if (_currentUserPrompt == null || _nextTurnIndex >= _scriptFlow.length) {
      await _discardAssessmentRecording();
      return;
    }
    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) {
      await _discardAssessmentRecording();
      return;
    }
    final assessment = await _buildSpeechAssessment(
      expectedText: expected.text,
      spokenText: text,
    );
    if (assessment.azureResult != null) {
      _turnPronunciationResults.add(assessment.azureResult!);
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, assessment: null));
      _nextTurnIndex++;
      _currentUserPrompt = null;
    });
    _showScoreFromAssessment(assessment, shouldRetry: false);
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pushNextAiTurn();
    });
  }

  Future<void> _submitRecognizedMessage() async {
    final transcript = _speechService.recognizedText;
    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLanguage.t('practice.noSpeechDetected'))),
      );
      _speechService.resetSession();
      await _discardAssessmentRecording();
      return;
    }

    if (_useLlm) {
      await _discardAssessmentRecording();
      _submitLlmMessage(transcript);
      return;
    }
    if (_isCustomScenario) {
      await _discardAssessmentRecording();
      _submitLocalCustomMessage(transcript);
      _speechService.resetSession();
      return;
    }

    // Scripted flow
    if (_currentUserPrompt == null || _nextTurnIndex >= _scriptFlow.length) {
      _speechService.resetSession();
      await _discardAssessmentRecording();
      return;
    }

    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) {
      _speechService.resetSession();
      await _discardAssessmentRecording();
      return;
    }
    final assessment = await _buildSpeechAssessment(
      expectedText: expected.text,
      spokenText: transcript,
    );
    if (assessment.azureResult != null) {
      _turnPronunciationResults.add(assessment.azureResult!);
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: transcript, isUser: true, assessment: null),
      );
      _nextTurnIndex++;
      _currentUserPrompt = null;
    });
    _showScoreFromAssessment(assessment, shouldRetry: false);
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
    if (_isCustomScenario) {
      _submitLocalCustomMessage(text);
      return;
    }

    // Scripted flow: just add user text and push next AI turn
    if (_currentUserPrompt == null || _nextTurnIndex >= _scriptFlow.length) {
      return;
    }

    final expected = _scriptFlow[_nextTurnIndex];
    if (expected.isAi) return;
    _SpeechAssessment.compare(expectedText: expected.text, spokenText: text);

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, assessment: null));
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
      _messages.add(
        _ChatMessage(text: userText, isUser: true, assessment: null),
      );
      _isTyping = true;
    });
    _speechService.resetSession();
    _scrollToBottom();

    try {
      final reply = await _llmService.sendMessage(userText);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(text: reply, isUser: false, assessment: null),
        );
      });
      _scrollToBottom();
      unawaited(_speakAiMessage(reply));
    } catch (e) {
      if (!mounted) return;
      final isRateLimited = e is LlmChatException && e.isRateLimited;
      final reply = isRateLimited
          ? _rateLimitFallbackMessage()
          : (appLanguage.locale.languageCode == 'vi'
                ? 'AI đang tạm lỗi. Mình đã lưu câu bạn vừa nói, hãy thử lại sau ít phút.'
                : 'AI is temporarily unavailable. Your message was saved; please try again in a few minutes.');
      setState(() {
        _isTyping = false;
        if (isRateLimited) _useLlm = false;
        _showTextInput = true;
        _messages.add(
          _ChatMessage(text: reply, isUser: false, assessment: null),
        );
      });
      _scrollToBottom();
    }
  }

  void _submitLocalCustomMessage(String userText) {
    final reply = _localCustomReply(userText);
    setState(() {
      _messages.add(
        _ChatMessage(text: userText, isUser: true, assessment: null),
      );
      _messages.add(_ChatMessage(text: reply, isUser: false, assessment: null));
    });
    _speechService.resetSession();
    _cloudSpeechService.resetSession();
    _nativeSpeechService.resetSession();
    _scrollToBottom();
  }

  String _rateLimitFallbackMessage() {
    if (appLanguage.locale.languageCode != 'vi') {
      return 'Gemini is temporarily rate limited, so I switched this chat to offline practice mode. You can continue speaking or typing; dynamic AI replies will be available again later.';
    }
    return 'Gemini đang bị giới hạn tạm thời do quá nhiều request, nên mình đã chuyển cuộc trò chuyện sang chế độ luyện offline. Bạn vẫn có thể nói hoặc nhập câu để tiếp tục luyện.';
  }

  String _localCustomReply(String userText) {
    if (appLanguage.locale.languageCode != 'vi') {
      return 'I heard: "$userText". Good. Try expanding that answer with one more detail, then say it again clearly.';
    }
    return 'Mình đã nghe: "$userText". Tốt rồi. Hãy thử nói lại câu đó chậm hơn và thêm một chi tiết nữa để luyện phản xạ.';
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

class _ScoreEvent {
  final int serial;
  final int points;
  final int score;
  final int accuracy;
  final int fluency;
  final int completeness;
  final int total;
  final int combo;
  final bool shouldRetry;
  final bool isFinal;

  const _ScoreEvent({
    required this.serial,
    required this.points,
    required this.score,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.total,
    required this.combo,
    required this.shouldRetry,
    required this.isFinal,
  });
}

class _ScoreRewardPanel extends StatelessWidget {
  final _ScoreEvent event;

  const _ScoreRewardPanel({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final vi = appLanguage.locale.languageCode == 'vi';
    final color = event.shouldRetry
        ? c.feedbackWarning
        : event.score >= 85
        ? c.feedbackGood
        : event.score >= 65
        ? c.accentBlue
        : c.feedbackAttention;
    final title = event.isFinal
        ? (vi ? 'HOÀN THÀNH' : 'COMPLETE')
        : event.shouldRetry
        ? (vi ? 'THỬ LẠI' : 'RETRY')
        : event.score >= 85
        ? (vi ? 'COMBO ĐẸP' : 'CLEAN COMBO')
        : (vi ? 'ĂN ĐIỂM' : 'SCORE UP');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - opacity) * 18),
            child: Transform.scale(scale: 0.94 + opacity * 0.06, child: child),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              c.cardBg,
              c.accentPurple.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    event.isFinal
                        ? Icons.emoji_events_rounded
                        : event.shouldRetry
                        ? Icons.replay_rounded
                        : Icons.bolt_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: base.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.shouldRetry
                            ? (vi
                                  ? 'Giữ câu này và kiếm lại combo'
                                  : 'Keep this prompt and rebuild combo')
                            : (vi
                                  ? 'Tổng điểm ${event.total}'
                                  : 'Total ${event.total}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: base.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: event.points),
                      duration: const Duration(milliseconds: 620),
                      curve: Curves.easeOutCubic,
                      builder: (context, points, _) {
                        return Text(
                          '+$points',
                          style: base.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: color,
                            height: 1,
                          ),
                        );
                      },
                    ),
                    Text(
                      event.combo > 1
                          ? 'x${event.combo}'
                          : '${event.score}/100',
                      style: base.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: c.textHeading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScoreStatBar(
                    label: vi ? 'Đúng' : 'Acc',
                    value: event.accuracy,
                    color: c.feedbackGood,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScoreStatBar(
                    label: vi ? 'Trôi' : 'Flow',
                    value: event.fluency,
                    color: c.accentBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScoreStatBar(
                    label: vi ? 'Đủ' : 'Done',
                    value: event.completeness,
                    color: c.accentPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreStatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreStatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final normalized = value.clamp(0, 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: c.textMuted,
                ),
              ),
            ),
            Text(
              '$value',
              style: base.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: c.textHeading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            backgroundColor: c.borderColor.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _AssessedChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _AssessedChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.assessment == null) {
      return ChatBubble(message: message.text, isUser: message.isUser);
    }

    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final assessment = message.assessment!;
    final scoreColor = assessment.accuracy >= 85
        ? c.feedbackGood
        : assessment.accuracy >= 65
        ? c.feedbackWarning
        : c.error;
    final vi = appLanguage.locale.languageCode == 'vi';

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.borderColor.withValues(alpha: 0.78)),
          boxShadow: [
            BoxShadow(
              color: c.shadowColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: c.heroGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vi ? 'Bạn đã nói' : 'You said',
                    style: base.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    assessment.spokenText.isNotEmpty
                        ? assessment.spokenText
                        : message.text,
                    style: base.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.42,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${assessment.accuracy}',
                          style: base.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vi ? 'Độ khớp câu mẫu' : 'Prompt match',
                              style: base.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: c.textHeading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${assessment.matchedWords}/${assessment.expectedWords} ${vi ? 'từ khớp' : 'words matched'}',
                              style: base.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (assessment.azureResult != null) ...[
                    const SizedBox(height: 12),
                    _AzureScoreGrid(result: assessment.azureResult!),
                  ],
                  const SizedBox(height: 12),
                  _AssessmentTextBlock(
                    label: vi ? 'Câu người dùng đọc' : 'User sentence',
                    text: assessment.spokenText.isNotEmpty
                        ? assessment.spokenText
                        : message.text,
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const SizedBox(height: 10),
                  _AssessmentTextBlock(
                    label: vi ? 'Câu mẫu' : 'Original prompt',
                    text: assessment.expectedText,
                    icon: Icons.flag_rounded,
                  ),
                  if (assessment.issues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      vi ? 'Chỗ cần sửa' : 'Needs attention',
                      style: base.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: c.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assessment.issues.take(8).map((issue) {
                        return _IssueChip(issue: issue);
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      assessment.feedback,
                      style: base.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textBody,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentTextBlock extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;

  const _AssessmentTextBlock({
    required this.label,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.metricRowBg.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: c.accentBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: base.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: base.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textHeading,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AzureScoreGrid extends StatelessWidget {
  final PronunciationResult result;

  const _AzureScoreGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final vi = appLanguage.locale.languageCode == 'vi';
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 300 ? 6.0 : 8.0;
        final itemWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _AzureScorePill(
                label: vi ? 'Độ đúng' : 'Accuracy',
                value: result.accuracyScore,
                icon: Icons.gps_fixed_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _AzureScorePill(
                label: vi ? 'Độ trôi' : 'Fluency',
                value: result.fluencyScore,
                icon: Icons.speed_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _AzureScorePill(
                label: vi ? 'Đủ câu' : 'Complete',
                value: result.completenessScore,
                icon: Icons.done_all_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AzureScorePill extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _AzureScorePill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final color = value >= 80
        ? c.feedbackGood
        : value >= 60
        ? c.feedbackWarning
        : c.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value.round().toString(),
            style: base.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  final _SpeechIssue issue;

  const _IssueChip({required this.issue});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final color = switch (issue.type) {
      _SpeechIssueType.missing => c.error,
      _SpeechIssueType.extra => c.feedbackWarning,
      _SpeechIssueType.different => c.feedbackAttention,
      _SpeechIssueType.pronunciation => c.accentPurple,
    };
    final value = switch (issue.type) {
      _SpeechIssueType.missing => issue.expected ?? '',
      _SpeechIssueType.extra => issue.actual ?? '',
      _SpeechIssueType.different =>
        '${issue.expected ?? ''} -> ${issue.actual ?? ''}',
      _SpeechIssueType.pronunciation =>
        '${issue.expected ?? ''} ~ ${issue.actual ?? ''}',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '${issue.label(context)}: $value',
        style: base.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final _SpeechAssessment? assessment;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.assessment,
  });
}

enum _SpeechIssueType { missing, extra, different, pronunciation }

class _SpeechIssue {
  final _SpeechIssueType type;
  final String? expected;
  final String? actual;

  const _SpeechIssue({required this.type, this.expected, this.actual});

  String label(BuildContext context) {
    final vi = appLanguage.locale.languageCode == 'vi';
    switch (type) {
      case _SpeechIssueType.missing:
        return vi ? 'Thiếu từ' : 'Missing word';
      case _SpeechIssueType.extra:
        return vi ? 'Thừa từ' : 'Extra word';
      case _SpeechIssueType.different:
        return vi ? 'Nói khác câu mẫu' : 'Different word';
      case _SpeechIssueType.pronunciation:
        return vi ? 'Phát âm/chính tả chưa khớp' : 'Pronunciation/spelling';
    }
  }
}

class _SpeechAssessment {
  final String expectedText;
  final String spokenText;
  final int accuracy;
  final int matchedWords;
  final int expectedWords;
  final List<_SpeechIssue> issues;
  final PronunciationResult? azureResult;

  const _SpeechAssessment({
    required this.expectedText,
    required this.spokenText,
    required this.accuracy,
    required this.matchedWords,
    required this.expectedWords,
    required this.issues,
    this.azureResult,
  });

  String get feedback {
    final vi = appLanguage.locale.languageCode == 'vi';
    if (accuracy >= 90) {
      return vi
          ? 'Rất tốt. Câu nói gần như khớp với mẫu.'
          : 'Great. Your sentence is very close to the prompt.';
    }
    if (accuracy >= 72) {
      return vi
          ? 'Khá tốt. Hãy luyện lại các từ được đánh dấu.'
          : 'Good attempt. Practice the highlighted words again.';
    }
    if (accuracy >= 50) {
      return vi
          ? 'Bạn đã nói được một phần câu. Cần chậm lại và đọc rõ từng cụm.'
          : 'You got part of the sentence. Slow down and articulate each phrase.';
    }
    return vi
        ? 'Câu nhận dạng còn lệch nhiều. Hãy nghe lại câu mẫu rồi thử lại.'
        : 'The recognized sentence differs a lot. Listen again and retry.';
  }

  static _SpeechAssessment compare({
    required String expectedText,
    required String spokenText,
    PronunciationResult? azureResult,
  }) {
    final expected = _SpeechToken.tokenize(expectedText);
    final spoken = _SpeechToken.tokenize(spokenText);
    final lcs = _longestCommonSubsequence(expected, spoken);
    final issues = <_SpeechIssue>[];
    var matched = 0;
    var expectedCursor = 0;
    var spokenCursor = 0;

    for (final pair in lcs) {
      _appendGapIssues(
        issues,
        expected.sublist(expectedCursor, pair.expectedIndex),
        spoken.sublist(spokenCursor, pair.spokenIndex),
      );
      matched++;
      expectedCursor = pair.expectedIndex + 1;
      spokenCursor = pair.spokenIndex + 1;
    }

    _appendGapIssues(
      issues,
      expected.sublist(expectedCursor),
      spoken.sublist(spokenCursor),
    );

    final denominator = math.max(expected.length, spoken.length);
    final accuracy = denominator == 0
        ? 0
        : ((matched / denominator) * 100).round().clamp(0, 100);

    final azureIssues = _issuesFromAzure(azureResult);
    return _SpeechAssessment(
      expectedText: expectedText,
      spokenText: spokenText,
      accuracy: azureResult?.overallScore.round().clamp(0, 100) ?? accuracy,
      matchedWords: azureResult == null
          ? matched
          : math.max(0, (azureResult.words.length - azureIssues.length)),
      expectedWords: azureResult?.words.length ?? expected.length,
      issues: azureIssues.isNotEmpty ? azureIssues : issues,
      azureResult: azureResult,
    );
  }

  static List<_SpeechIssue> _issuesFromAzure(PronunciationResult? result) {
    if (result == null) return const [];
    return [
      for (final word in result.words)
        if (word.hasError || word.accuracyScore < 70)
          _SpeechIssue(
            type: switch (word.errorType.toLowerCase()) {
              'omission' => _SpeechIssueType.missing,
              'insertion' => _SpeechIssueType.extra,
              'mispronunciation' => _SpeechIssueType.pronunciation,
              _ => _SpeechIssueType.pronunciation,
            },
            expected: word.errorType.toLowerCase() == 'insertion'
                ? null
                : word.word,
            actual: word.errorType.toLowerCase() == 'insertion'
                ? word.word
                : null,
          ),
    ];
  }

  static void _appendGapIssues(
    List<_SpeechIssue> issues,
    List<_SpeechToken> expectedGap,
    List<_SpeechToken> spokenGap,
  ) {
    final paired = math.min(expectedGap.length, spokenGap.length);
    for (var i = 0; i < paired; i++) {
      final expected = expectedGap[i].raw;
      final actual = spokenGap[i].raw;
      issues.add(
        _SpeechIssue(
          type:
              _looksSimilar(expectedGap[i].normalized, spokenGap[i].normalized)
              ? _SpeechIssueType.pronunciation
              : _SpeechIssueType.different,
          expected: expected,
          actual: actual,
        ),
      );
    }
    for (var i = paired; i < expectedGap.length; i++) {
      issues.add(
        _SpeechIssue(
          type: _SpeechIssueType.missing,
          expected: expectedGap[i].raw,
        ),
      );
    }
    for (var i = paired; i < spokenGap.length; i++) {
      issues.add(
        _SpeechIssue(type: _SpeechIssueType.extra, actual: spokenGap[i].raw),
      );
    }
  }

  static List<_TokenPair> _longestCommonSubsequence(
    List<_SpeechToken> expected,
    List<_SpeechToken> spoken,
  ) {
    final rows = expected.length + 1;
    final cols = spoken.length + 1;
    final dp = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = expected.length - 1; i >= 0; i--) {
      for (var j = spoken.length - 1; j >= 0; j--) {
        if (expected[i].normalized == spoken[j].normalized) {
          dp[i][j] = dp[i + 1][j + 1] + 1;
        } else {
          dp[i][j] = math.max(dp[i + 1][j], dp[i][j + 1]);
        }
      }
    }

    final pairs = <_TokenPair>[];
    var i = 0;
    var j = 0;
    while (i < expected.length && j < spoken.length) {
      if (expected[i].normalized == spoken[j].normalized) {
        pairs.add(_TokenPair(i, j));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }
    return pairs;
  }

  static bool _looksSimilar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a[0] == b[0]) return true;
    final distance = _levenshtein(a, b);
    final longest = math.max(a.length, b.length);
    return longest > 0 && (1 - distance / longest) >= 0.62;
  }

  static int _levenshtein(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }
}

class _SpeechToken {
  final String raw;
  final String normalized;

  const _SpeechToken(this.raw, this.normalized);

  static List<_SpeechToken> tokenize(String text) {
    final matches = RegExp(
      r"[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)?",
      unicode: true,
    ).allMatches(text);
    return [
      for (final match in matches)
        _SpeechToken(match.group(0)!, match.group(0)!.toLowerCase()),
    ];
  }
}

class _TokenPair {
  final int expectedIndex;
  final int spokenIndex;

  const _TokenPair(this.expectedIndex, this.spokenIndex);
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
