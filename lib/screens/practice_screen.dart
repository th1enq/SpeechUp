import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../services/speech_input_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../services/firestore_service.dart';
import '../services/microphone_settings_service.dart';
import '../services/speech_recognition_service.dart';
import '../models/practice_session.dart';
import 'analysis_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  TextStyle get _display => GoogleFonts.plusJakartaSans();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final MicrophoneSettingsService _micSettingsService =
      MicrophoneSettingsService();
  final FirestoreService _firestoreService = FirestoreService();

  MicrophoneSettings _micSettings = MicrophoneSettings.defaults;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcript = '';
  String? _helperMessage;
  DateTime? _recordingStartedAt;
  double _soundLevel = 0;

  @override
  void initState() {
    super.initState();
    _loadMicSettings();
  }

  @override
  void dispose() {
    _speechService.cancel();
    super.dispose();
  }

  Future<void> _loadMicSettings() async {
    final settings = await _micSettingsService.load();
    if (mounted) setState(() => _micSettings = settings);
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
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
                        Icons.person_rounded,
                        color: AppColors.onboardingBlue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SpeechUp',
                      style: _display.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.calmText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _showMicrophoneSettings,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.calmText,
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Private practice',
              style: _display.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.calmText,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Speak naturally. Your words stay in your practice space.',
              style: _display.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.calmTextSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            _TranscriptPanel(
              transcript: _transcript,
              isRecording: _isRecording,
              isProcessing: _isProcessing,
            ),
            const SizedBox(height: 18),
            Center(
              child: _SoftWaveform(
                isActive: _isRecording && !_isProcessing,
                soundLevel: _soundLevel,
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: _RecordControl(
                isRecording: _isRecording,
                isProcessing: _isProcessing,
                onTap: _toggleRecording,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _recordButtonLabel,
                style: _display.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.calmText,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _helperMessage ?? _defaultHelper,
                textAlign: TextAlign.center,
                style: _display.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.calmTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Suggested practice',
              style: _display.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.calmText,
              ),
            ),
            const SizedBox(height: 12),
            _PracticeExerciseCard(
              variant: _ExerciseVisual.readSentence,
              title: appLanguage.locale.languageCode == 'vi'
                  ? 'Tự giới thiệu ngắn'
                  : 'Self introduction',
              body: appLanguage.locale.languageCode == 'vi'
                  ? 'Hãy giới thiệu bản thân trong 30 đến 45 giây như khi gặp đồng nghiệp mới hoặc bắt đầu buổi phỏng vấn.'
                  : 'Introduce yourself in 30 to 45 seconds as if you were meeting a new teammate or starting an interview.',
              bodyItalic: false,
              tagLabel: t('practice.easy'),
              onTap: () => _openRecording(
                context,
                exerciseType: 'self_introduction',
                content: appLanguage.locale.languageCode == 'vi'
                    ? 'Xin chao, minh la... Hom nay minh muon gioi thieu ngan gon ve ban than va cong viec cua minh.'
                    : 'Hi, I am... Today I would like to briefly introduce myself and the kind of work I do.',
              ),
            ),
            const SizedBox(height: 14),
            _PracticeExerciseCard(
              variant: _ExerciseVisual.shadowing,
              title: appLanguage.locale.languageCode == 'vi'
                  ? 'Gọi đồ uống'
                  : 'Order a drink',
              body: appLanguage.locale.languageCode == 'vi'
                  ? 'Luyện một cuộc hội thoại ngắn tại quán cà phê: gọi món, chọn kích cỡ, và nói thêm một yêu cầu nhỏ.'
                  : 'Practice a short cafe conversation: place an order, choose a size, and add one small request.',
              bodyItalic: false,
              tagLabel: t('practice.medium'),
              onTap: () => _openRecording(
                context,
                exerciseType: 'ordering_food',
                content: appLanguage.locale.languageCode == 'vi'
                    ? 'Cho minh mot ly ca phe sua da size vua, it duong va them mot banh nho.'
                    : 'I would like one iced latte, medium size, less sugar, and a small pastry.',
              ),
            ),
            const SizedBox(height: 14),
            _PracticeExerciseCard(
              variant: _ExerciseVisual.slowSpeech,
              title: appLanguage.locale.languageCode == 'vi'
                  ? 'Mở đầu phỏng vấn'
                  : 'Interview opening',
              body: appLanguage.locale.languageCode == 'vi'
                  ? 'Trả lời câu hỏi mở đầu trong buổi phỏng vấn: giới thiệu kinh nghiệm, điểm mạnh, và mục tiêu hiện tại.'
                  : 'Answer an interview opener: share your background, strengths, and what you are looking for now.',
              bodyItalic: false,
              tagLabel: t('practice.hard'),
              onTap: () => _openRecording(
                context,
                exerciseType: 'interview_opening',
                content: appLanguage.locale.languageCode == 'vi'
                    ? 'Cam on anh chi. Em co kinh nghiem trong linh vuc... va em rat mong co co hoi dong gop tai vi tri nay.'
                    : 'Thank you for having me. I have experience in... and I am excited about the opportunity to contribute in this role.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _recordButtonLabel {
    if (_isProcessing) return 'Preparing your reflection...';
    return _isRecording ? 'Tap to Finish' : 'Tap to Start';
  }

  String get _defaultHelper {
    if (_isProcessing) return 'Your session is still here.';
    if (_isRecording) return 'Speak naturally - I am listening';
    return 'Take your time';
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;
    if (_isRecording) {
      await _finishRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final status = await _micSettingsService.microphoneStatus();
    if (status != PermissionStatus.granted) {
      final nextStatus = await _micSettingsService.requestMicrophone();
      if (nextStatus != PermissionStatus.granted) {
        if (mounted) _showMicrophonePermissionSheet();
        return;
      }
    }

    try {
      final available = await _speechService.initialize(
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _helperMessage = message.contains('error_speech_timeout')
                ? 'I did not hear speech yet. You can keep trying.'
                : 'Speech recognition is not available on this device.';
          });
        },
      );
      if (!available) {
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _helperMessage =
              'Speech recognition is not available on this Android image.';
        });
        return;
      }

      setState(() {
        _isRecording = true;
        _isProcessing = false;
        _transcript = '';
        _helperMessage = 'Speak naturally - I am listening';
        _soundLevel = 0;
        _recordingStartedAt = DateTime.now();
      });

      await _speechService.listen(
        localeId: _micSettings.localeId,
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() {
            _soundLevel = level;
            _helperMessage =
                level < 2 ? 'Pauses are welcome here' : 'Speak naturally - I am listening';
          });
        },
        onResult: (recognizedWords, isFinal) {
          if (!mounted) return;
          setState(() {
            _transcript = recognizedWords;
            _helperMessage = recognizedWords.trim().isEmpty
                ? 'Speak naturally - I am listening'
                : 'Your words are appearing in real time.';
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _helperMessage =
            'Could not start speech recognition. Check microphone and recognition service.';
      });
    }
  }

  Future<void> _finishRecording() async {
    await _speechService.stop();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _soundLevel = 0;
      _helperMessage = 'Preparing your reflection...';
    });

    final startedAt = _recordingStartedAt ?? DateTime.now();
    final duration =
        DateTime.now().difference(startedAt).inSeconds.clamp(1, 3600).toInt();
    final transcript = _transcript.trim();

    if (transcript.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _helperMessage = 'I could not hear clear speech yet. Please try again.';
      });
      return;
    }

    final summary = _buildSessionSummary(transcript, duration);

    if (isFirebaseSupported) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final content =
            _micSettings.saveTranscripts ? transcript : 'Private practice summary';
        final session = PracticeSession(
          userId: user.uid,
          exerciseType: 'private_practice',
          content: content,
          score: summary.score,
          durationSeconds: duration,
          fluency: summary.fluency,
          pronunciation: summary.pronunciation,
          speechSpeed: summary.wordsPerMinute,
          createdAt: DateTime.now(),
        );
        try {
          await _firestoreService.savePracticeSessionAndUpdateStats(session);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not save right now. Your result is still here.'),
              ),
            );
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _helperMessage = null;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          transcript: transcript,
          durationSeconds: duration,
        ),
      ),
    );
  }

  _SessionSummary _buildSessionSummary(String transcript, int durationSeconds) {
    final words = transcript
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    final wordsPerMinute = durationSeconds > 0
        ? (words.length / durationSeconds * 60).round()
        : 0;
    final pacePenalty = (wordsPerMinute - 130).abs().clamp(0, 80);
    final score = (88 - (pacePenalty / 4)).round().clamp(60, 96).toInt();
    final fluency = (score + 2).clamp(0, 100).toInt();
    final pronunciation = (score + 4).clamp(0, 100).toInt();
    return _SessionSummary(
      score: score,
      fluency: fluency,
      pronunciation: pronunciation,
      wordsPerMinute: wordsPerMinute,
    );
  }

  void _showMicrophonePermissionSheet() {
    final base = _display;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Microphone access is needed',
                  style: base.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.calmText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SpeechUp only listens during your private practice session.',
                  style: base.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.calmTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final status =
                          await _micSettingsService.requestMicrophone();
                      if (status == PermissionStatus.granted) {
                        await _startRecording();
                      }
                    },
                    child: const Text('Allow microphone'),
                  ),
                ),
                TextButton(
                  onPressed: () => _micSettingsService.openSettings(),
                  child: const Text('Open settings'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMicrophoneSettings() {
    var draft = _micSettings;
    final base = _display;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Microphone settings',
                      style: base.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.calmText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsOption(
                      title: 'Recognition language',
                      subtitle: draft.localeId == 'vi_VN'
                          ? 'Tiếng Việt'
                          : 'English (US)',
                      icon: Icons.language_rounded,
                      onTap: () {
                        setSheetState(() {
                          draft = draft.copyWith(
                            localeId:
                                draft.localeId == 'vi_VN' ? 'en_US' : 'vi_VN',
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: draft.privateMode,
                      onChanged: (value) {
                        setSheetState(() {
                          draft = draft.copyWith(privateMode: value);
                        });
                      },
                      title: const Text('Private mode'),
                      subtitle: const Text('Ask before saving session details.'),
                    ),
                    SwitchListTile.adaptive(
                      value: draft.saveTranscripts,
                      onChanged: (value) {
                        setSheetState(() {
                          draft = draft.copyWith(saveTranscripts: value);
                        });
                      },
                      title: const Text('Save transcripts'),
                      subtitle: const Text('Turn off to save only summary insights.'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
	                        onPressed: () async {
	                          await _micSettingsService.save(draft);
	                          if (!mounted || !context.mounted) return;
	                          setState(() => _micSettings = draft);
	                          Navigator.pop(context);
                        },
                        child: const Text('Save settings'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openRecording(
    BuildContext context, {
    required String exerciseType,
    required String content,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _RecordingScreen(exerciseType: exerciseType, content: content),
      ),
    );
  }
}

class _SessionSummary {
  final int score;
  final int fluency;
  final int pronunciation;
  final int wordsPerMinute;

  const _SessionSummary({
    required this.score,
    required this.fluency,
    required this.pronunciation,
    required this.wordsPerMinute,
  });
}

class _TranscriptPanel extends StatelessWidget {
  final String transcript;
  final bool isRecording;
  final bool isProcessing;

  const _TranscriptPanel({
    required this.transcript,
    required this.isRecording,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final lines = _visibleLines;

    return Container(
      width: double.infinity,
      height: 360,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.calmText.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.calmMintSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Private practice',
                  style: base.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.calmText,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isRecording ? Icons.mic_rounded : Icons.lock_outline_rounded,
                color: isRecording ? AppColors.calmCoral : AppColors.calmBlue,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: transcript.trim().isEmpty
                  ? _TranscriptPlaceholder(isProcessing: isProcessing)
                  : Column(
                      key: ValueKey(transcript),
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < lines.length; i++) ...[
                          Text(
                            lines[i],
                            style: base.copyWith(
                              fontSize: i == lines.length - 1 ? 24 : 20,
                              fontWeight: i == lines.length - 1
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.45,
                              color: i == lines.length - 1
                                  ? AppColors.calmText
                                  : AppColors.calmTextSecondary.withValues(
                                      alpha: 0.55 + (i * 0.12),
                                    ),
                            ),
                          ),
                          if (i != lines.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _visibleLines {
    final words = transcript.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return const [];
    final chunks = <String>[];
    for (var i = 0; i < words.length; i += 8) {
      chunks.add(words.skip(i).take(8).join(' '));
    }
    return chunks.length <= 4 ? chunks : chunks.sublist(chunks.length - 4);
  }
}

class _TranscriptPlaceholder extends StatelessWidget {
  final bool isProcessing;

  const _TranscriptPlaceholder({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Center(
      key: ValueKey(isProcessing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProcessing ? Icons.auto_awesome_rounded : Icons.spa_outlined,
            size: 42,
            color: AppColors.calmBlue,
          ),
          const SizedBox(height: 14),
          Text(
            isProcessing
                ? 'Preparing your reflection...'
                : 'Your words will appear here',
            textAlign: TextAlign.center,
            style: base.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.calmText,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only you can see this session.',
            textAlign: TextAlign.center,
            style: base.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.calmTextSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftWaveform extends StatelessWidget {
  final bool isActive;
  final double soundLevel;

  const _SoftWaveform({
    required this.isActive,
    required this.soundLevel,
  });

  static const _heights = [18.0, 28.0, 38.0, 52.0, 68.0, 52.0, 38.0, 28.0, 18.0];

  @override
  Widget build(BuildContext context) {
    final normalizedLevel = ((soundLevel + 2) / 12).clamp(0.0, 1.0);
    return SizedBox(
      height: 72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            AnimatedContainer(
              duration: Duration(milliseconds: isActive ? 420 + (i * 24) : 260),
              curve: Curves.easeInOut,
              width: 8,
              height: isActive
                  ? (_heights[i] * (0.65 + normalizedLevel * 0.45))
                  : (_heights[i] * 0.45),
              decoration: BoxDecoration(
                color: (i.isEven ? AppColors.calmMint : AppColors.calmBlue)
                    .withValues(alpha: isActive ? 0.95 : 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordControl extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onTap;

  const _RecordControl({
    required this.isRecording,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isRecording ? 'Finish recording' : 'Start recording',
      child: Opacity(
        opacity: isProcessing ? 0.55 : 1,
        child: IgnorePointer(
          ignoring: isProcessing,
          child: MicButton(
            isRecording: isRecording,
            onTap: onTap,
            size: 96,
          ),
        ),
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return Material(
      color: AppColors.calmBlueSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.calmText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.calmText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: base.copyWith(
                        fontSize: 13,
                        color: AppColors.calmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.swap_horiz_rounded, color: AppColors.calmTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ExerciseVisual { readSentence, shadowing, slowSpeech }

class _PracticeExerciseCard extends StatelessWidget {
  final _ExerciseVisual variant;
  final String title;
  final String body;
  final bool bodyItalic;
  final String tagLabel;
  final VoidCallback onTap;

  const _PracticeExerciseCard({
    required this.variant,
    required this.title,
    required this.body,
    required this.bodyItalic,
    required this.tagLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();

    late final Color cardBg;
    late final Widget leadingIcon;
    late final Color tagBg;
    late final Color tagText;
    late final IconData watermark;
    late final Color watermarkColor;
    late final Widget action;

    switch (variant) {
      case _ExerciseVisual.readSentence:
        cardBg = Colors.white;
        leadingIcon = Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.onboardingBlue,
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 26,
          ),
        );
        tagBg = AppColors.practiceTagEasyBg;
        tagText = AppColors.practiceTagEasyText;
        watermark = Icons.menu_book_rounded;
        watermarkColor = AppColors.onboardingBlue;
        action = _GradientStartButton(
          onTap: onTap,
          label: appLanguage.t('common.start'),
        );
        break;
      case _ExerciseVisual.shadowing:
        cardBg = AppColors.practiceCardLavender;
        leadingIcon = Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE9D5FF),
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.practicePurple,
            size: 26,
          ),
        );
        tagBg = AppColors.practiceTagMidBg;
        tagText = AppColors.practiceTagMidText;
        watermark = Icons.fitness_center_rounded;
        watermarkColor = AppColors.practicePurple;
        action = _OutlineStartButton(
          onTap: onTap,
          label: appLanguage.t('common.start'),
          foreground: AppColors.practicePurpleDeep,
        );
        break;
      case _ExerciseVisual.slowSpeech:
        cardBg = AppColors.practiceCardBlush;
        leadingIcon = Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.practicePurple,
          ),
          child: const Icon(
            Icons.timer_outlined,
            color: Colors.white,
            size: 26,
          ),
        );
        tagBg = AppColors.practiceTagHardBg;
        tagText = AppColors.practiceTagHardText;
        watermark = Icons.speed_rounded;
        watermarkColor = AppColors.practicePurpleDeep;
        action = _OutlineStartButton(
          onTap: onTap,
          label: appLanguage.t('common.start'),
          foreground: AppColors.practicePurpleDeep,
        );
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardNavy.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -6,
              bottom: -6,
              child: Icon(
                watermark,
                size: 118,
                color: watermarkColor.withValues(alpha: 0.07),
              ),
            ),
            ColoredBox(
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leadingIcon,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: tagBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tagLabel,
                                  style: style.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: tagText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                title,
                                style: style.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dashboardNavy,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      bodyItalic ? '"$body"' : body,
                      style: style.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontStyle: bodyItalic
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: AppColors.dashboardTextMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    action,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientStartButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _GradientStartButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.dashboardHeroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: style.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineStartButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Color foreground;

  const _OutlineStartButton({
    required this.onTap,
    required this.label,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: style.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingScreen extends StatefulWidget {
  final String exerciseType;
  final String content;

  const _RecordingScreen({required this.exerciseType, required this.content});

  @override
  State<_RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<_RecordingScreen> {
  late final SpeechInputService _speechService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechInputService()..addListener(_handleSpeechUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _speechService.removeListener(_handleSpeechUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = GoogleFonts.plusJakartaSans();
    final transcript = _speechService.recognizedText;
    final durationSeconds = _speechService.elapsed.inSeconds;
    final wordsPerMinute = _calculateWordsPerMinute(
      transcript,
      durationSeconds,
    );
    final pausesLabel = _speechService.isListening
        ? appLanguage.t('practice.listening')
        : appLanguage.t('common.stop');
    final clarity = _estimateClarity(_effectiveSoundLevel).round();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.recordingBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SpeechUp',
                      style: display.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dashboardNavy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.recordingDotRecording,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appLanguage.t('practice.recordingSession'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: display.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.dashboardTextMuted,
                        ),
                      ),
                    ),
                    Material(
                      color: AppColors.recordingCloseBtnBg,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _closeScreen,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.dashboardNavy,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  _speechService.isListening
                      ? appLanguage.t('practice.listening')
                      : appLanguage.t('practice.tapToStart'),
                  textAlign: TextAlign.center,
                  style: display.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardNavy,
                    height: 1.2,
                  ),
                ),
                if (widget.content.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    widget.content,
                    textAlign: TextAlign.center,
                    style: display.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dashboardTextMuted,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Center(
                  child: _RecordingWaveform(
                    heights: _buildWaveHeights(_effectiveSoundLevel),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.recordingMicGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onboardingBlue.withValues(
                            alpha: 0.42,
                          ),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _RecordingMetricCard(
                        icon: Icons.speed_rounded,
                        label: appLanguage.t('practice.metricSpeed'),
                        value: wordsPerMinute > 0
                            ? '$wordsPerMinute ${appLanguage.t('progress.wpm')}'
                            : '--',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecordingMetricCard(
                        icon: Icons.pause_rounded,
                        label: appLanguage.t('practice.metricPauses'),
                        value: pausesLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecordingMetricCard(
                        icon: Icons.graphic_eq_rounded,
                        label: appLanguage.t('practice.metricClarity'),
                        value: '$clarity%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            appLanguage.t('practice.liveTranscript'),
                            style: display.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dashboardNavy,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(_speechService.elapsed),
                            style: display.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onboardingBlueDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        transcript.isEmpty
                            ? appLanguage.t('practice.tapToStart')
                            : transcript,
                        style: display.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: transcript.isEmpty
                              ? AppColors.dashboardTextMuted
                              : AppColors.dashboardNavy,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  height: 54,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              if (_speechService.isListening) {
                                _stopAndAnalyze();
                              } else {
                                _startListening();
                              }
                            },
                      borderRadius: BorderRadius.circular(27),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.dashboardHeroGradient,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.onboardingBlue.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _speechService.isListening
                                      ? appLanguage.t('practice.stopRecording')
                                      : appLanguage.t('common.start'),
                                  style: display.copyWith(
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
                if (!_speechService.isSupportedPlatform ||
                    _speechService.lastError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      !_speechService.isSupportedPlatform
                          ? appLanguage.t('practice.unsupportedPlatform')
                          : _speechService.errorSummary.contains(
                              'service is not installed or unavailable',
                            )
                          ? '${appLanguage.t('practice.recognizerUnavailable')}\n${_speechService.errorSummary}'
                          : '${appLanguage.t('practice.permissionDenied')}\n${_speechService.errorSummary}',
                      style: display.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _closeScreen,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onboardingBlueDeep,
                    ),
                    child: Text(
                      appLanguage.t('common.cancel'),
                      style: display.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onboardingBlueDeep,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double get _effectiveSoundLevel {
    final level = _speechService.soundLevel;
    if (level.isNaN || level.isInfinite) return 0;
    return level.clamp(0, 40).toDouble();
  }

  Future<void> _startListening() async {
    if (!_speechService.isSupportedPlatform) {
      setState(() {});
      return;
    }

    _speechService.resetSession();
    final didStart = await _speechService.startListening(
      localeId: _localeIdForApp(),
    );
    if (!didStart && mounted) {
      setState(() {});
    }
  }

  Future<void> _stopAndAnalyze() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    await _speechService.stopListening();

    final transcript = _speechService.recognizedText;
    final durationSeconds = _speechService.elapsed.inSeconds;
    if (transcript.isEmpty) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(appLanguage.t('practice.noSpeechDetected'));
      }
      return;
    }

    await _savePracticeSession(
      transcript: transcript,
      durationSeconds: durationSeconds,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          transcript: transcript,
          durationSeconds: durationSeconds,
        ),
      ),
    );
  }

  Future<void> _savePracticeSession({
    required String transcript,
    required int durationSeconds,
  }) async {
    if (!isFirebaseSupported) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wordsPerMinute = _calculateWordsPerMinute(
      transcript,
      durationSeconds,
    );
    final fluency = _calculateFluencyScore(durationSeconds, transcript);
    final pronunciation = _calculatePronunciationScore(transcript);
    final score = ((fluency + pronunciation) / 2).round();

    final firestoreService = FirestoreService();
    final session = PracticeSession(
      userId: user.uid,
      exerciseType: widget.exerciseType,
      content: transcript,
      score: score,
      durationSeconds: durationSeconds,
      fluency: fluency,
      pronunciation: pronunciation,
      speechSpeed: wordsPerMinute,
      createdAt: DateTime.now(),
    );
    await firestoreService.savePracticeSession(session);

    final profile = await firestoreService.getUserProfile(user.uid);
    if (profile != null) {
      await firestoreService.updateUserProfile(user.uid, {
        'totalSessions': profile.totalSessions + 1,
        'totalSpeakingMinutes':
            profile.totalSpeakingMinutes + (durationSeconds / 60),
      });
    }
    await firestoreService.updateStreak(user.uid);
  }

  void _handleSpeechUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _closeScreen() {
    _speechService.cancelListening();
    Navigator.of(context).pop();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _localeIdForApp() {
    return appLanguage.locale.languageCode == 'vi' ? 'vi_VN' : 'en_US';
  }

  int _calculateWordsPerMinute(String transcript, int durationSeconds) {
    final words = transcript
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (words == 0 || durationSeconds <= 0) return 0;
    return ((words / durationSeconds) * 60).round();
  }

  int _calculateFluencyScore(int durationSeconds, String transcript) {
    final wordsPerMinute = _calculateWordsPerMinute(
      transcript,
      durationSeconds,
    );
    if (wordsPerMinute == 0) return 0;
    final distanceFromTarget = (135 - wordsPerMinute).abs();
    return (100 - distanceFromTarget).clamp(55, 98).toInt();
  }

  int _calculatePronunciationScore(String transcript) {
    final wordCount = transcript
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (wordCount == 0) return 0;
    return (65 + (wordCount * 2).clamp(0, 30)).toInt();
  }

  double _estimateClarity(double soundLevel) {
    return (55 + soundLevel * 1.1).clamp(55, 99);
  }

  List<double> _buildWaveHeights(double soundLevel) {
    final normalized = (soundLevel / 40).clamp(0.0, 1.0);
    const base = [
      18.0,
      28.0,
      38.0,
      50.0,
      64.0,
      78.0,
      64.0,
      50.0,
      38.0,
      28.0,
      18.0,
    ];
    return [for (final height in base) height * (0.45 + normalized * 0.75)];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RecordingWaveform extends StatelessWidget {
  final List<double> heights;

  const _RecordingWaveform({required this.heights});

  static const List<Color> _colors = [
    Color(0xFFB9DAFF),
    Color(0xFF9ECAFF),
    Color(0xFF7EB3FF),
    Color(0xFF5C9DFF),
    Color(0xFF4589EE),
    Color(0xFF2F75DC),
    Color(0xFF4589EE),
    Color(0xFF5C9DFF),
    Color(0xFF7EB3FF),
    Color(0xFF9ECAFF),
    Color(0xFFB9DAFF),
  ];

  @override
  Widget build(BuildContext context) {
    const barWidth = 8.0;
    const gap = 6.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < heights.length; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          Container(
            width: barWidth,
            height: heights[i],
            decoration: BoxDecoration(
              color: _colors[i],
              borderRadius: BorderRadius.circular(barWidth / 2),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecordingMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RecordingMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardNavy.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.onboardingBlueDeep, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: style.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
              color: AppColors.dashboardTextMuted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: style.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardNavy,
            ),
          ),
        ],
      ),
    );
  }
}
