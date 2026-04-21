import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart' show isFirebaseSupported;
import '../services/speech_input_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../services/conversation_ai_service.dart';
import '../services/firestore_service.dart';
import '../services/microphone_settings_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _inConversation = false;
  String? _selectedScenario;
  String _selectedCategory = 'Daily Communication';

  static const _categories = [
    'Daily Communication',
    'Interview',
    'Presentation',
    'Ordering Food',
    'Self Introduction',
  ];

  final List<_Scenario> _scenarios = [
    _Scenario(
      id: 'cafe',
      title: 'Gọi đồ uống tại quán cà phê',
      description: 'Luyện tập gọi đồ uống và giao tiếp với nhân viên',
      category: 'Ordering Food',
      difficulty: 'Easy',
      duration: '2-3 min',
      icon: Icons.coffee_rounded,
      color: AppColors.onboardingBlueDeep,
    ),
    _Scenario(
      id: 'interview',
      title: 'Phỏng vấn xin việc',
      description: 'Tập trả lời các câu hỏi phỏng vấn một cách tự tin',
      category: 'Interview',
      difficulty: 'Growing',
      duration: '5 min',
      icon: Icons.work_rounded,
      color: AppColors.progressAccentBlue,
    ),
    _Scenario(
      id: 'phone',
      title: 'Gọi điện cho khách hàng',
      description: 'Tập giao tiếp qua điện thoại chuyên nghiệp',
      category: 'Daily Communication',
      difficulty: 'Medium',
      duration: '3 min',
      icon: Icons.phone_in_talk_rounded,
      color: AppColors.onboardingBlue,
    ),
    _Scenario(
      id: 'present',
      title: 'Thuyết trình trước nhóm',
      description: 'Chuẩn bị cho bài thuyết trình trước đồng nghiệp',
      category: 'Presentation',
      difficulty: 'Growing',
      duration: '5 min',
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
    final visibleScenarios = _scenarios
        .where((scenario) => scenario.category == _selectedCategory)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
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
                        Icons.flag_rounded,
                        color: AppColors.calmMint,
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
                  onPressed: () => _showVoiceSettings(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.dashboardNavy,
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Choose a gentle challenge',
              style: base.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.dashboardNavy,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Practice real moments at your own pace.',
              style: base.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.dashboardTextMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(category),
                    selectedColor: AppColors.calmMintSurface,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.calmMint
                          : AppColors.dashboardTextMuted.withValues(
                              alpha: 0.15,
                            ),
                    ),
                    labelStyle: base.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dashboardNavy,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            ...visibleScenarios.map(
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
  final String category;
  final String difficulty;
  final String duration;
  final IconData icon;
  final Color color;

  const _Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
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
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ScenarioPill(label: scenario.difficulty),
                          _ScenarioPill(label: scenario.duration),
                        ],
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

class _ScenarioPill extends StatelessWidget {
  final String label;

  const _ScenarioPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.calmMintSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: base.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.calmText,
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
  late final SpeechInputService _speechService;
  final MicrophoneSettingsService _micSettingsService =
      MicrophoneSettingsService();
  final ConversationAiService _aiService = ConversationAiService();
  bool _isTyping = false;
  bool _isUserRecording = false;
  String _liveTranscript = '';
  String? _recordingHelper;
  String? _lastSpeechError;
  bool _isSubmittingResult = false;
  double _soundLevel = 0;
  MicrophoneSettings _micSettings = MicrophoneSettings.defaults;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _speechService = SpeechInputService()..addListener(_handleSpeechUpdate);
    _loadMicSettings();
    _requestAIReply();
  }

  Future<void> _loadMicSettings() async {
    final settings = await _micSettingsService.load();
    if (mounted) {
      setState(() => _micSettings = settings);
    }
  }

  Future<void> _requestAIReply() async {
    setState(() => _isTyping = true);
    try {
      final reply = await _aiService.nextReply(
        scenarioId: widget.scenario.id,
        scenarioTitle: widget.scenario.title,
        messages: _messages
            .map((message) => {'text': message.text, 'isUser': message.isUser})
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          const _ChatMessage(
            text:
                'Mình chưa kết nối được AI coach. Bạn cứ tiếp tục luyện nói, SpeechUp vẫn ghi lại phần trả lời của bạn.',
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleUserRecording() async {
    if (_isSubmittingResult) return;
    if (_isUserRecording) {
      await _finishUserRecording();
    } else {
      await _startUserRecording();
    }
  }

  Future<void> _startUserRecording() async {
    final status = await _micSettingsService.microphoneStatus();
    if (status != PermissionStatus.granted) {
      final nextStatus = await _micSettingsService.requestMicrophone();
      if (nextStatus != PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _recordingHelper =
                'Cần quyền microphone để trả lời bằng giọng nói.';
          });
        }
        return;
      }
    }

    _speechService.resetSession();
    final didStart = await _speechService.startListening(
      localeId: _micSettings.localeId,
    );
    if (!mounted) return;
    setState(() {
      _isUserRecording = didStart;
      _liveTranscript = '';
      _soundLevel = 0;
      _recordingHelper = didStart
          ? 'Mình đang lắng nghe câu trả lời của bạn...'
          : (_speechService.lastError ??
                'Không mở được microphone. Hãy kiểm tra cài đặt.');
      _lastSpeechError = null;
    });
  }

  Future<void> _finishUserRecording() async {
    if (_isSubmittingResult) return;
    _isSubmittingResult = true;
    await _speechService.stopListening();
    await _submitRecognizedMessage();
    _isSubmittingResult = false;
  }

  Future<void> _submitRecognizedMessage() async {
    final transcript = _speechService.recognizedText.trim();
    if (transcript.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isUserRecording = false;
        _liveTranscript = '';
        _soundLevel = 0;
        _recordingHelper = 'Mình chưa nghe rõ. Bạn có thể thử lại.';
      });
      _speechService.resetSession();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUserRecording = false;
      _liveTranscript = transcript;
      _soundLevel = 0;
      _recordingHelper = null;
      _messages.add(_ChatMessage(text: transcript, isUser: true));
    });
    _speechService.resetSession();
    _scrollToBottom();
    await _requestAIReply();
  }

  void _handleSpeechUpdate() {
    if (!mounted) return;

    final currentError = _speechService.lastError;
    final shouldSubmit =
        _isUserRecording &&
        !_speechService.isListening &&
        _speechService.recognizedText.trim().isNotEmpty &&
        !_isSubmittingResult;

    setState(() {
      _isUserRecording = _speechService.isListening;
      _liveTranscript = _speechService.recognizedText;
      _soundLevel = _speechService.soundLevel;
      if (_speechService.isListening) {
        _recordingHelper = _liveTranscript.trim().isEmpty
            ? 'Mình đang lắng nghe câu trả lời của bạn...'
            : 'SpeechUp đang ghi lại ý chính của bạn.';
      } else if (_liveTranscript.trim().isEmpty && currentError == null) {
        _recordingHelper ??= 'Bạn có thể bắt đầu bất cứ lúc nào.';
      }
    });

    if (currentError != null &&
        currentError.isNotEmpty &&
        currentError != _lastSpeechError) {
      _lastSpeechError = currentError;
      final helper = currentError.contains('recognition service') ||
              currentError.contains('unavailable')
          ? 'Thiết bị chưa có dịch vụ nhận diện giọng nói.'
          : 'SpeechUp chưa nghe rõ. Bạn có thể thử lại.';
      setState(() => _recordingHelper = helper);
    }

    if (shouldSubmit) {
      _isSubmittingResult = true;
      _submitRecognizedMessage().whenComplete(() {
        _isSubmittingResult = false;
      });
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
          if (_isUserRecording || _liveTranscript.isNotEmpty || _recordingHelper != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.calmMintSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isUserRecording
                            ? Icons.graphic_eq_rounded
                            : Icons.info_outline_rounded,
                        color: AppColors.calmText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _recordingHelper ?? 'Câu trả lời của bạn',
                          style: base.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.calmText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isUserRecording) ...[
                    const SizedBox(height: 8),
                    _ConversationWaveform(soundLevel: _soundLevel),
                  ],
                  if (_liveTranscript.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _liveTranscript,
                      style: base.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.calmText,
                      ),
                    ),
                  ],
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
                  color: AppColors.calmAmber.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: widget.onExit,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.calmText,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                MicButton(
                  isRecording: _isUserRecording,
                  onTap: _toggleUserRecording,
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
}

class _ConversationWaveform extends StatelessWidget {
  final double soundLevel;

  const _ConversationWaveform({required this.soundLevel});

  static const _bars = [10.0, 16.0, 26.0, 34.0, 24.0, 18.0, 12.0];

  @override
  Widget build(BuildContext context) {
    final normalized = ((soundLevel + 2) / 12).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _bars.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 6,
            height: _bars[i] * (0.7 + normalized * 0.6),
            decoration: BoxDecoration(
              color: (i.isEven ? AppColors.calmMint : AppColors.calmBlue),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ],
    );
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
