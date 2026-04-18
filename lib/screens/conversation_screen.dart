import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../services/speech_input_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../services/firestore_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _inConversation = false;
  String? _selectedScenario;

  final List<_Scenario> _scenarios = [
    _Scenario(
      id: 'cafe',
      title: 'Gọi đồ uống tại quán cà phê',
      description: 'Luyện tập gọi đồ uống và giao tiếp với nhân viên',
      icon: Icons.coffee_rounded,
      color: AppColors.onboardingBlueDeep,
    ),
    _Scenario(
      id: 'interview',
      title: 'Phỏng vấn xin việc',
      description: 'Tập trả lời các câu hỏi phỏng vấn một cách tự tin',
      icon: Icons.work_rounded,
      color: AppColors.progressAccentBlue,
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
  Widget build(BuildContext context) {
    if (_inConversation && _selectedScenario != null) {
      return _ConversationChat(
        scenario: _scenarios.firstWhere((s) => s.id == _selectedScenario),
        onExit: () {
          setState(() {
            _inConversation = false;
            _selectedScenario = null;
          });
        },
        onSaveConversation: (scenarioId, messages) async {
          if (!isFirebaseSupported) return;
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final firestoreService = FirestoreService();
            await firestoreService.saveConversation(
              userId: user.uid,
              scenarioId: scenarioId,
              messages: messages,
            );
          }
        },
      );
    }

    final base = GoogleFonts.plusJakartaSans();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dashboardNavy.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: AppColors.onboardingBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SpeechUp',
                      style: base.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dashboardNavy,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.dashboardNavy,
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Hội thoại với AI',
              style: base.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.dashboardNavy,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn tình huống để bắt đầu luyện tập',
              style: base.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.dashboardTextMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
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

class _ScenarioCard extends StatelessWidget {
  final _Scenario scenario;
  final VoidCallback onTap;

  const _ScenarioCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Container(
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
                          color: AppColors.dashboardNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scenario.description,
                        style: base.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dashboardTextMuted,
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
  final VoidCallback onExit;
  final Future<void> Function(
    String scenarioId,
    List<Map<String, dynamic>> messages,
  )?
  onSaveConversation;

  const _ConversationChat({
    required this.scenario,
    required this.onExit,
    this.onSaveConversation,
  });

  @override
  State<_ConversationChat> createState() => _ConversationChatState();
}

class _ConversationChatState extends State<_ConversationChat> {
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isUserRecording = false;
  late final SpeechInputService _speechService;
  String? _lastSpeechError;
  final ScrollController _scrollController = ScrollController();

  // Simulated conversation flows
  static const Map<String, List<List<String>>> _conversationFlows = {
    'cafe': [
      ['Xin chào! Chào mừng bạn đến quán cà phê. Bạn muốn dùng gì ạ?'],
      ['Cho mình một ly cà phê sữa đá nhé.'],
      ['Dạ vâng ạ! Bạn muốn size vừa hay lớn ạ?'],
      ['Size vừa thôi, và cho mình thêm ít đường nhé.'],
      [
        'Dạ được ạ! Bạn có muốn dùng thêm bánh ngọt không ạ? Hôm nay quán có croissant bơ mới ra lò rất thơm.',
      ],
      ['Nghe hấp dẫn quá, cho mình một cái croissant luôn nhé!'],
      [
        'Tuyệt vời ạ! Một cà phê sữa đá size vừa ít đường và một croissant bơ. Tổng cộng 75 nghìn ạ. Bạn thanh toán bằng tiền mặt hay chuyển khoản ạ?',
      ],
    ],
    'interview': [
      [
        'Chào bạn, cảm ơn bạn đã đến phỏng vấn hôm nay. Bạn có thể giới thiệu đôi chút về bản thân mình không?',
      ],
      [
        'Dạ vâng, em xin chào. Em tên là Mai, em có 3 năm kinh nghiệm trong lĩnh vực truyền thông.',
      ],
      ['Rất tốt! Vậy điểm mạnh lớn nhất của bạn trong công việc là gì?'],
      [
        'Điểm mạnh của em là khả năng lên kế hoạch nội dung và quản lý đa nhiệm.',
      ],
      ['Bạn có thể chia sẻ về một dự án mà bạn tự hào nhất không?'],
    ],
    'phone': [
      ['Alô, xin chào! Đây là công ty ABC, tôi có thể giúp gì cho anh/chị?'],
      [
        'Dạ chào anh, em là Mai từ công ty XYZ. Em gọi để trao đổi về đề xuất hợp tác mà bên em đã gửi.',
      ],
      [
        'À vâng, tôi đã nhận được đề xuất. Bạn có thể tóm tắt lại các điểm chính không?',
      ],
      [
        'Dạ vâng. Đề xuất chính là chương trình marketing liên kết, giúp tăng nhận diện thương hiệu cho cả hai bên.',
      ],
      ['Nghe khá thú vị. Về ngân sách dự kiến thì sao?'],
    ],
    'present': [
      [
        'Chào mọi người, buổi thuyết trình bắt đầu nhé. Bạn có thể bắt đầu khi sẵn sàng.',
      ],
      [
        'Kính chào ban giám đốc, hôm nay em xin trình bày về chiến lược phát triển quý 3.',
      ],
      [
        'Phần tổng quan rất rõ ràng. Bạn có thể giải thích thêm về mục tiêu doanh thu không?',
      ],
    ],
  };

  @override
  void initState() {
    super.initState();
    _speechService = SpeechInputService()..addListener(_handleSpeechUpdate);
    // AI starts the conversation
    _addAIMessage();
  }

  void _addAIMessage() {
    final flow =
        _conversationFlows[widget.scenario.id] ?? _conversationFlows['cafe']!;
    final aiMessages = <String>[];
    for (int i = 0; i < flow.length; i += 2) {
      aiMessages.add(flow[i][0]);
    }

    final aiIndex = _messages.where((m) => !m.isUser).length;
    if (aiIndex < aiMessages.length) {
      setState(() => _isTyping = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add(
              _ChatMessage(text: aiMessages[aiIndex], isUser: false),
            );
          });
          _scrollToBottom();
        }
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isTyping) return;

    if (_isUserRecording) {
      await _speechService.stopListening();
      return;
    }

    if (!_speechService.isSupportedPlatform) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage.t('practice.unsupportedPlatform')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLanguage.t('practice.permissionDenied')} ${_speechService.errorSummary}',
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
          .map((m) => {'text': m.text, 'isUser': m.isUser})
          .toList();
      widget.onSaveConversation!(widget.scenario.id, messageMaps);
    }
    _speechService
      ..removeListener(_handleSpeechUpdate)
      ..cancelListening();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.dashboardNavy),
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
                      color: AppColors.dashboardNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isTyping)
                    Text(
                      'Đang trả lời...',
                      style: base.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onboardingBlue,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              size: 22,
              color: AppColors.dashboardNavy,
            ),
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
            icon: Icon(
              Icons.close_rounded,
              size: 22,
              color: AppColors.dashboardNavy,
            ),
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
          if (_isUserRecording || _speechService.recognizedText.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.onboardingBlue.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                _speechService.recognizedText.isEmpty
                    ? appLanguage.t('practice.listening')
                    : _speechService.recognizedText,
                style: base.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _speechService.recognizedText.isEmpty
                      ? AppColors.dashboardTextMuted
                      : AppColors.dashboardNavy,
                  height: 1.4,
                ),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.dashboardNavy.withValues(alpha: 0.06),
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
                const SizedBox(width: 20),
                MicButton(
                  isRecording: _isUserRecording,
                  onTap: () => _toggleRecording(),
                  size: 64,
                ),
                const SizedBox(width: 20),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLanguage.t('practice.permissionDenied')} ${_speechService.errorSummary}',
          ),
        ),
      );
    }
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

    setState(() {
      _messages.add(_ChatMessage(text: transcript, isUser: true));
    });
    _speechService.resetSession();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _addAIMessage();
    });
  }

  String _localeIdForApp() {
    return appLanguage.locale.languageCode == 'vi' ? 'vi_VN' : 'en_US';
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
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

  final List<Map<String, dynamic>> _voices = [
    {
      'name': 'Giọng nam miền Bắc',
      'icon': Icons.person_rounded,
      'color': AppColors.onboardingBlueDeep,
    },
    {
      'name': 'Giọng nữ miền Nam',
      'icon': Icons.person_rounded,
      'color': AppColors.onboardingBlue,
    },
    {
      'name': 'Giọng nữ miền Bắc',
      'icon': Icons.person_rounded,
      'color': AppColors.progressAccentBlue,
    },
    {
      'name': 'Giọng nam miền Nam',
      'icon': Icons.person_rounded,
      'color': AppColors.progressMilestonePurple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              color: AppColors.dashboardNavy,
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
                color: AppColors.dashboardNavy,
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
                      : AppColors.dashboardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? (voice['color'] as Color).withValues(alpha: 0.45)
                        : AppColors.dashboardTextMuted.withValues(alpha: 0.12),
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
                          color: AppColors.dashboardNavy,
                        ),
                      ),
                    ),
                    // Play preview
                    GestureDetector(
                      onTap: () {},
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
                          Icons.play_arrow_rounded,
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
                color: AppColors.dashboardNavy,
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
                  color: AppColors.dashboardTextMuted,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 1.5,
                  divisions: 4,
                  activeColor: AppColors.onboardingBlue,
                  inactiveColor: AppColors.onboardingBlue.withValues(
                    alpha: 0.18,
                  ),
                  label: _speed == 0.5
                      ? 'Rất chậm'
                      : _speed == 0.75
                      ? 'Chậm'
                      : _speed == 1.0
                      ? 'Bình thường'
                      : _speed == 1.25
                      ? 'Nhanh'
                      : 'Rất nhanh',
                  onChanged: (v) => setState(() => _speed = v),
                ),
              ),
              Text(
                'Nhanh',
                style: base.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dashboardTextMuted,
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã lưu cài đặt giọng nói!',
                        style: base.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.progressAccentBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
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
}
