import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../services/speech_input_service.dart';
import '../services/cloud_speech_service.dart';
import '../services/native_speech_service.dart';
import '../services/google_tts_service.dart';
import '../services/azure_pronunciation_service.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../models/practice_session.dart';
import '../models/pronunciation_result.dart';
import '../widgets/screen_header.dart';
import 'analysis_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  TextStyle get _display => GoogleFonts.plusJakartaSans();

  List<_PracticePromptOption> _optionsForLevel(_PracticeDifficulty level) {
    final vi = appLanguage.locale.languageCode == 'vi';
    switch (level) {
      case _PracticeDifficulty.easy:
        return [
          _PracticePromptOption(
            level: level,
            exerciseType: 'read',
            title: vi ? 'Chào hỏi hằng ngày' : 'Daily greetings',
            content: vi
                ? 'Xin chào, rất vui được gặp bạn hôm nay.'
                : 'Hello, it is nice to meet you today.',
            focus: vi
                ? 'Câu ngắn, từ quen thuộc, nhịp nói chậm.'
                : 'Short sentence, familiar words, slower pacing.',
            lengthLabel: vi ? '1 câu ngắn' : '1 short sentence',
            vocabularyLabel: vi ? 'Từ vựng cơ bản' : 'Basic vocabulary',
          ),
          _PracticePromptOption(
            level: level,
            exerciseType: 'read',
            title: vi ? 'Giới thiệu bản thân' : 'Self introduction',
            content: vi
                ? 'Tôi là Bao và tôi đang luyện nói tiếng Anh mỗi ngày.'
                : 'My name is Bao and I practice speaking English every day.',
            focus: vi
                ? 'Làm quen với câu hoàn chỉnh và phát âm rõ từng từ.'
                : 'Get used to full sentences and clearer articulation.',
            lengthLabel: vi ? '1 câu vừa' : '1 medium sentence',
            vocabularyLabel: vi ? 'Chủ đề quen thuộc' : 'Familiar topic',
          ),
          _PracticePromptOption(
            level: level,
            exerciseType: 'read',
            title: vi ? 'Sinh hoạt thường ngày' : 'Daily routine',
            content: vi
                ? 'Buổi sáng tôi thường uống cà phê trước khi bắt đầu làm việc.'
                : 'In the morning, I usually drink coffee before I start working.',
            focus: vi
                ? 'Tăng nhẹ độ dài câu nhưng vẫn dễ hiểu.'
                : 'Slightly longer sentence while staying easy to follow.',
            lengthLabel: vi ? '1 câu dài vừa' : '1 longer sentence',
            vocabularyLabel: vi ? 'Mô tả đơn giản' : 'Simple description',
          ),
        ];
      case _PracticeDifficulty.medium:
        return [
          _PracticePromptOption(
            level: level,
            exerciseType: 'shadowing',
            title: vi ? 'Họp công việc ngắn' : 'Short work update',
            content: vi
                ? 'Hôm nay nhóm của tôi sẽ rà soát tiến độ và chốt kế hoạch cho tuần tới.'
                : 'Today my team will review progress and finalize the plan for next week.',
            focus: vi
                ? 'Câu dài hơn, có nhiều cụm ý cần giữ nhịp ổn định.'
                : 'Longer sentence with multiple thought groups to pace well.',
            lengthLabel: vi ? '1 câu phức' : '1 complex sentence',
            vocabularyLabel: vi ? 'Từ vựng công việc' : 'Work vocabulary',
          ),
          _PracticePromptOption(
            level: level,
            exerciseType: 'shadowing',
            title: vi ? 'Đặt lịch hẹn' : 'Scheduling a meeting',
            content: vi
                ? 'Nếu bạn rảnh vào chiều thứ Năm, chúng ta có thể gặp nhau để thảo luận chi tiết hơn.'
                : 'If you are free on Thursday afternoon, we can meet to discuss the details further.',
            focus: vi
                ? 'Luyện nối âm, ngắt câu và giữ mạch nói tự nhiên.'
                : 'Practice linking, phrasing, and natural flow.',
            lengthLabel: vi ? '1 câu nhiều vế' : '1 multi-clause sentence',
            vocabularyLabel: vi ? 'Tình huống giao tiếp' : 'Functional phrases',
          ),
          _PracticePromptOption(
            level: level,
            exerciseType: 'shadowing',
            title: vi ? 'Mô tả trải nghiệm' : 'Describe an experience',
            content: vi
                ? 'Chuyến đi cuối tuần vừa rồi giúp tôi thư giãn và có thêm nhiều ý tưởng mới cho công việc.'
                : 'My weekend trip helped me relax and gave me many new ideas for work.',
            focus: vi
                ? 'Tăng độ dài và yêu cầu kiểm soát ngữ điệu tốt hơn.'
                : 'More length with stronger intonation control.',
            lengthLabel: vi ? '1 câu dài' : '1 long sentence',
            vocabularyLabel: vi
                ? 'Mô tả trải nghiệm'
                : 'Descriptive vocabulary',
          ),
        ];
      case _PracticeDifficulty.hard:
        return [
          _PracticePromptOption(
            level: level,
            exerciseType: 'slow',
            title: vi ? 'Trình bày quan điểm' : 'Present an opinion',
            content: vi
                ? 'Theo tôi, việc luyện nói mỗi ngày không chỉ cải thiện phát âm mà còn giúp tăng phản xạ giao tiếp trong môi trường thực tế.'
                : 'In my opinion, practicing speaking every day not only improves pronunciation but also strengthens communication reflexes in real situations.',
            focus: vi
                ? 'Câu dài, từ trừu tượng hơn, cần kiểm soát hơi và nhịp.'
                : 'Long sentence, more abstract wording, stronger breath control.',
            lengthLabel: vi ? '1 câu rất dài' : '1 very long sentence',
            vocabularyLabel: vi
                ? 'Từ vựng học thuật nhẹ'
                : 'Light academic vocabulary',
          ),
          _PracticePromptOption(
            level: level,
            exerciseType: 'slow',
            title: vi ? 'Báo cáo tiến độ' : 'Progress report',
            content: vi
                ? 'Mặc dù tiến độ hiện tại đang đi đúng hướng, chúng tôi vẫn cần tối ưu quy trình phối hợp để giảm thêm thời gian phản hồi giữa các bộ phận.'
                : 'Although the current progress is on track, we still need to optimize coordination so we can further reduce response time across teams.',
            focus: vi
                ? 'Nhiều cụm thông tin, cần nói chậm nhưng vẫn rõ ý.'
                : 'Several information chunks that require slow, clear delivery.',
            lengthLabel: vi ? '1 câu chuyên môn' : '1 professional sentence',
            vocabularyLabel: vi
                ? 'Từ vựng công việc nâng cao'
                : 'Advanced work vocabulary',
          ),
          _PracticePromptOption(
            level: level,
            exerciseType: 'slow',
            title: vi ? 'Giải thích quyết định' : 'Explain a decision',
            content: vi
                ? 'Chúng tôi chọn phương án này vì nó cân bằng tốt hơn giữa chi phí triển khai, trải nghiệm người dùng và khả năng mở rộng trong tương lai.'
                : 'We chose this approach because it creates a better balance between implementation cost, user experience, and long-term scalability.',
            focus: vi
                ? 'Luyện độ rõ của phụ âm cuối và nhấn ý chính.'
                : 'Practice final consonants and emphasis on key ideas.',
            lengthLabel: vi ? '1 câu lập luận' : '1 reasoning sentence',
            vocabularyLabel: vi
                ? 'Lập luận và phân tích'
                : 'Reasoning vocabulary',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final compact = MediaQuery.sizeOf(context).width < 370;
    final bottomPadding = 16 + MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: t('practice.title'),
              subtitle: t('practice.subtitle'),
            ),
            SizedBox(height: compact ? 18 : 24),
            _PracticeLevelCard(
              level: _PracticeDifficulty.easy,
              onTap: () => _openLevelSheet(_PracticeDifficulty.easy),
            ),
            const SizedBox(height: 14),
            _PracticeLevelCard(
              level: _PracticeDifficulty.medium,
              onTap: () => _openLevelSheet(_PracticeDifficulty.medium),
            ),
            const SizedBox(height: 14),
            _PracticeLevelCard(
              level: _PracticeDifficulty.hard,
              onTap: () => _openLevelSheet(_PracticeDifficulty.hard),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                color: AppColors.practiceStreakBlue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.practiceStreakBlue.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('practice.weeklyStreak'),
                    style: _display.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('practice.weeklyStreakHint'),
                    style: _display.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.45,
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

  Future<void> _openLevelSheet(_PracticeDifficulty level) async {
    final options = _optionsForLevel(level);
    final selected = await showModalBottomSheet<_PracticePromptOption>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final style = GoogleFonts.plusJakartaSans();
        final c = context.colors;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.sheetTitle,
                  style: style.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: c.textHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level.sheetSubtitle,
                  style: style.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return _PracticePromptOptionTile(
                        option: option,
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    _openRecording(
      context,
      exerciseType: selected.exerciseType,
      content: selected.content,
    );
  }
}

enum _PracticeDifficulty { easy, medium, hard }

class _PracticePromptOption {
  final _PracticeDifficulty level;
  final String exerciseType;
  final String title;
  final String content;
  final String focus;
  final String lengthLabel;
  final String vocabularyLabel;

  const _PracticePromptOption({
    required this.level,
    required this.exerciseType,
    required this.title,
    required this.content,
    required this.focus,
    required this.lengthLabel,
    required this.vocabularyLabel,
  });
}

extension on _PracticeDifficulty {
  String get label {
    final vi = appLanguage.locale.languageCode == 'vi';
    switch (this) {
      case _PracticeDifficulty.easy:
        return vi ? 'Dễ' : 'Easy';
      case _PracticeDifficulty.medium:
        return vi ? 'Trung bình' : 'Medium';
      case _PracticeDifficulty.hard:
        return vi ? 'Khó' : 'Hard';
    }
  }

  String get summary {
    final vi = appLanguage.locale.languageCode == 'vi';
    switch (this) {
      case _PracticeDifficulty.easy:
        return vi
            ? 'Câu ngắn, từ quen thuộc, phù hợp để bắt đầu.'
            : 'Short sentences with familiar words to get started.';
      case _PracticeDifficulty.medium:
        return vi
            ? 'Câu dài hơn, có nhiều cụm ý và cần giữ nhịp đều.'
            : 'Longer sentences with more phrasing and pacing control.';
      case _PracticeDifficulty.hard:
        return vi
            ? 'Câu dài, từ vựng khó hơn và cần kiểm soát ngữ điệu tốt.'
            : 'Longer prompts with tougher vocabulary and stronger intonation control.';
    }
  }

  String get sheetTitle {
    final vi = appLanguage.locale.languageCode == 'vi';
    switch (this) {
      case _PracticeDifficulty.easy:
        return vi ? 'Chọn bài luyện mức dễ' : 'Choose an easy practice prompt';
      case _PracticeDifficulty.medium:
        return vi
            ? 'Chọn bài luyện mức trung bình'
            : 'Choose a medium practice prompt';
      case _PracticeDifficulty.hard:
        return vi ? 'Chọn bài luyện mức khó' : 'Choose a hard practice prompt';
    }
  }

  String get sheetSubtitle {
    final vi = appLanguage.locale.languageCode == 'vi';
    switch (this) {
      case _PracticeDifficulty.easy:
        return vi
            ? 'Phù hợp để làm quen với nhịp nói, phát âm cơ bản và câu ngắn.'
            : 'Best for getting comfortable with speaking rhythm and short prompts.';
      case _PracticeDifficulty.medium:
        return vi
            ? 'Tập câu dài hơn, ghép nhiều ý và kiểm soát tốc độ rõ ràng.'
            : 'Train with longer lines, more ideas, and clearer pacing.';
      case _PracticeDifficulty.hard:
        return vi
            ? 'Dành cho câu nhiều thông tin, từ vựng nâng cao và ngữ điệu tốt.'
            : 'For denser prompts, advanced vocabulary, and stronger delivery.';
    }
  }

  Color get accent {
    switch (this) {
      case _PracticeDifficulty.easy:
        return AppColors.onboardingBlue;
      case _PracticeDifficulty.medium:
        return AppColors.practicePurple;
      case _PracticeDifficulty.hard:
        return AppColors.practicePurpleDeep;
    }
  }

  Color background(AppColorsExtension c) {
    switch (this) {
      case _PracticeDifficulty.easy:
        return c.cardBg;
      case _PracticeDifficulty.medium:
        return c.practiceCardLavender;
      case _PracticeDifficulty.hard:
        return c.practiceCardBlush;
    }
  }

  IconData get icon {
    switch (this) {
      case _PracticeDifficulty.easy:
        return Icons.spa_rounded;
      case _PracticeDifficulty.medium:
        return Icons.tune_rounded;
      case _PracticeDifficulty.hard:
        return Icons.bolt_rounded;
    }
  }
}

class _PracticeLevelCard extends StatelessWidget {
  final _PracticeDifficulty level;
  final VoidCallback onTap;

  const _PracticeLevelCard({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor.withValues(alpha: 0.35),
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
                level.icon,
                size: 118,
                color: level.accent.withValues(alpha: 0.08),
              ),
            ),
            ColoredBox(
              color: level.background(c),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: level.accent.withValues(alpha: 0.16),
                          ),
                          child: Icon(
                            level.icon,
                            color: level.accent,
                            size: 26,
                          ),
                        ),
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
                                  color: level.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  level.label.toUpperCase(),
                                  style: style.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: level.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                level.label,
                                style: style.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: c.textHeading,
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
                      level.summary,
                      style: style.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _LevelMetaChip(
                          icon: Icons.route_rounded,
                          label: appLanguage.locale.languageCode == 'vi'
                              ? 'Độ dài tăng dần'
                              : 'Increasing length',
                        ),
                        _LevelMetaChip(
                          icon: Icons.abc_rounded,
                          label: appLanguage.locale.languageCode == 'vi'
                              ? 'Từ vựng theo mức'
                              : 'Level-based vocabulary',
                        ),
                        _LevelMetaChip(
                          icon: Icons.touch_app_rounded,
                          label: appLanguage.locale.languageCode == 'vi'
                              ? 'Chạm để chọn bài'
                              : 'Tap to choose prompt',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _GradientStartButton(
                      onTap: onTap,
                      label: appLanguage.locale.languageCode == 'vi'
                          ? 'Chọn bài luyện'
                          : 'Choose prompt',
                    ),
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

class _PracticePromptOptionTile extends StatelessWidget {
  final _PracticePromptOption option;
  final VoidCallback onTap;

  const _PracticePromptOptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: option.level.background(c),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: option.level.accent.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: option.level.accent.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      option.level.icon,
                      color: option.level.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: style.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.focus,
                          style: style.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: option.level.accent),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"${option.content}"',
                style: style.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: c.textHeading,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LevelMetaChip(
                    icon: Icons.route_rounded,
                    label: option.lengthLabel,
                  ),
                  _LevelMetaChip(
                    icon: Icons.abc_rounded,
                    label: option.vocabularyLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LevelMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: style.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
        ],
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
    final c = context.colors;
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
              gradient: c.heroGradient,
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

class _RecordingScreen extends StatefulWidget {
  final String exerciseType;
  final String content;

  const _RecordingScreen({required this.exerciseType, required this.content});

  @override
  State<_RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<_RecordingScreen> {
  late final SpeechInputService _speechService;
  final CloudSpeechService _cloudSpeechService = CloudSpeechService();
  final NativeSpeechService _nativeSpeechService = NativeSpeechService();
  final AudioRecorder _assessmentRecorder = AudioRecorder();
  final GoogleTtsService _ttsService = GoogleTtsService();
  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isSubmitting = false;
  bool _isTtsLoading = false;
  bool _isTtsPlaying = false;
  bool _ttsAutoPlayed = false;
  bool _useCloudSpeech = false;
  bool _useNativeSpeech = false;
  String? _lastSpeechError;
  String? _assessmentAudioPath;
  DateTime? _fallbackStartedAt;
  Timer? _fallbackElapsedTicker;
  Duration _fallbackElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechInputService()..addListener(_handleSpeechUpdate);
    _nativeSpeechService.addListener(_handleNativeSpeechUpdate);
    _ttsPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isTtsPlaying = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.content.trim().isNotEmpty && !_ttsAutoPlayed) {
        _ttsAutoPlayed = true;
        _speakPromptText();
      }
      _checkMicAvailability().then((_) => _startListening());
    });
  }

  @override
  void dispose() {
    _ttsPlayer.dispose();
    _speechService.removeListener(_handleSpeechUpdate);
    _nativeSpeechService.removeListener(_handleNativeSpeechUpdate);
    _fallbackElapsedTicker?.cancel();
    _assessmentRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkMicAvailability() async {
    if (_speechService.isSupportedPlatform) {
      final available = await _speechService.initialize(
        localeId: _localeIdForApp(),
      );
      if (available) {
        _useCloudSpeech = false;
        _useNativeSpeech = false;
        return;
      }
    }

    if (_nativeSpeechService.isSupportedPlatform) {
      final nativeOk = await _nativeSpeechService.initialize();
      if (nativeOk) {
        _useNativeSpeech = true;
        _useCloudSpeech = false;
        return;
      }
    }

    if (_cloudSpeechService.isSupportedPlatform &&
        _cloudSpeechService.isConfigured) {
      final hasMic = await _cloudSpeechService.hasPermission();
      if (hasMic) {
        _useCloudSpeech = true;
        _useNativeSpeech = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = GoogleFonts.plusJakartaSans();
    final compact = MediaQuery.sizeOf(context).width < 370;
    final transcript = _activeRecognizedText;
    final durationSeconds = _activeElapsed.inSeconds;
    final wordsPerMinute = _calculateWordsPerMinute(
      transcript,
      durationSeconds,
    );
    final pausesLabel = _isActiveListening
        ? appLanguage.t('practice.listening')
        : appLanguage.t('common.stop');
    final micLevel = ((_effectiveSoundLevel / 40) * 100).round().clamp(0, 100);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.recordingBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              compact ? 6 : 8,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                SizedBox(height: compact ? 20 : 28),
                Text(
                  _isActiveListening
                      ? appLanguage.t('practice.listening')
                      : transcript.isEmpty
                      ? appLanguage.t('practice.tapToStart')
                      : appLanguage.t('common.stop'),
                  textAlign: TextAlign.center,
                  style: display.copyWith(
                    fontSize: compact ? 22 : 26,
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
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: _isTtsLoading
                          ? null
                          : () async {
                              if (_isTtsPlaying) {
                                await _stopPromptAudio();
                              } else {
                                await _speakPromptText();
                              }
                            },
                      icon: _isTtsLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isTtsPlaying
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_rounded,
                            ),
                      label: Text(
                        _isTtsPlaying ? 'Stop voice' : 'Listen with Google TTS',
                      ),
                    ),
                  ),
                ],
                SizedBox(height: compact ? 24 : 32),
                Center(
                  child: _RecordingWaveform(
                    heights: _buildWaveHeights(_effectiveSoundLevel),
                  ),
                ),
                SizedBox(height: compact ? 20 : 28),
                Center(
                  child: Container(
                    width: compact ? 102 : 120,
                    height: compact ? 102 : 120,
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
                    child: Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: compact ? 44 : 52,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 20 : 28),
                if (compact)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 60) / 2,
                        child: _RecordingMetricCard(
                          icon: Icons.speed_rounded,
                          label: appLanguage.t('practice.metricSpeed'),
                          value: wordsPerMinute > 0
                              ? '$wordsPerMinute ${appLanguage.t('progress.wpm')}'
                              : '--',
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 60) / 2,
                        child: _RecordingMetricCard(
                          icon: Icons.pause_rounded,
                          label: appLanguage.t('practice.metricPauses'),
                          value: pausesLabel,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 60) / 2,
                        child: _RecordingRealtimeMeterCard(
                          icon: Icons.graphic_eq_rounded,
                          label: appLanguage.locale.languageCode == 'vi'
                              ? 'MỨC MIC'
                              : 'MIC LEVEL',
                          value: '$micLevel%',
                          progress: micLevel / 100,
                        ),
                      ),
                    ],
                  )
                else
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
                        child: _RecordingRealtimeMeterCard(
                          icon: Icons.graphic_eq_rounded,
                          label: appLanguage.locale.languageCode == 'vi'
                              ? 'MỨC MIC'
                              : 'MIC LEVEL',
                          value: '$micLevel%',
                          progress: micLevel / 100,
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
                            _formatDuration(_activeElapsed),
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
                              if (_isActiveListening) {
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
                                  _isActiveListening
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
                if (!_isMicSupported || _activeSpeechError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      !_isMicSupported
                          ? appLanguage.t('practice.unsupportedPlatform')
                          : _activeSpeechErrorSummary.contains(
                              'service is not installed or unavailable',
                            )
                          ? '${appLanguage.t('practice.recognizerUnavailable')}\n$_activeSpeechErrorSummary'
                          : '${appLanguage.t('practice.permissionDenied')}\n$_activeSpeechErrorSummary',
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
    final level = _useNativeSpeech
        ? _nativeSpeechService.soundLevel
        : _speechService.soundLevel;
    if (level.isNaN || level.isInfinite) return 0;
    return level.clamp(0, 40).toDouble();
  }

  bool get _isActiveListening {
    if (_useNativeSpeech) return _nativeSpeechService.isListening;
    if (_useCloudSpeech) return _cloudSpeechService.isListening;
    return _speechService.isListening;
  }

  bool get _isMicSupported {
    return _speechService.isSupportedPlatform ||
        _nativeSpeechService.isSupportedPlatform ||
        _cloudSpeechService.isSupportedPlatform;
  }

  String get _activeRecognizedText {
    if (_useNativeSpeech) return _nativeSpeechService.recognizedText;
    if (_useCloudSpeech) return _cloudSpeechService.recognizedText;
    return _speechService.recognizedText;
  }

  String? get _activeSpeechError {
    if (_useNativeSpeech) return _nativeSpeechService.lastError;
    if (_useCloudSpeech) return _cloudSpeechService.lastError;
    return _speechService.lastError;
  }

  String get _activeSpeechErrorSummary {
    if (_useNativeSpeech) return _nativeSpeechService.errorSummary;
    if (_useCloudSpeech) return _cloudSpeechService.errorSummary;
    return _speechService.errorSummary;
  }

  Duration get _activeElapsed {
    if (_useNativeSpeech || _useCloudSpeech) return _fallbackElapsed;
    return _speechService.elapsed;
  }

  void _startFallbackElapsed() {
    _fallbackStartedAt = DateTime.now();
    _fallbackElapsed = Duration.zero;
    _fallbackElapsedTicker?.cancel();
    _fallbackElapsedTicker = Timer.periodic(const Duration(milliseconds: 250), (
      _,
    ) {
      if (!mounted || _fallbackStartedAt == null) return;
      setState(() {
        _fallbackElapsed = DateTime.now().difference(_fallbackStartedAt!);
      });
    });
  }

  void _stopFallbackElapsed() {
    _fallbackElapsedTicker?.cancel();
    _fallbackElapsedTicker = null;
    if (_fallbackStartedAt != null) {
      _fallbackElapsed = DateTime.now().difference(_fallbackStartedAt!);
      _fallbackStartedAt = null;
    }
  }

  Future<void> _startListening() async {
    if (!_isMicSupported) {
      setState(() {});
      return;
    }

    _lastSpeechError = null;

    if (_useCloudSpeech) {
      _cloudSpeechService.resetSession();
      final didStart = await _cloudSpeechService.startListening(
        locale: appLanguage.speechLanguageCode,
      );
      if (didStart) _startFallbackElapsed();
      if (!didStart && mounted) {
        setState(() {});
      }
      return;
    }

    await _startAssessmentRecording();

    if (_useNativeSpeech) {
      _nativeSpeechService.resetSession();
      final didStart = await _nativeSpeechService.startListening(
        locale: appLanguage.speechLanguageCode,
      );
      if (didStart) _startFallbackElapsed();
      if (!didStart && mounted) {
        setState(() {});
      }
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
    if (_useNativeSpeech) {
      await _nativeSpeechService.stopListening();
      _stopFallbackElapsed();
    } else if (_useCloudSpeech) {
      await _cloudSpeechService.stopListening(
        languageCode: appLanguage.speechLanguageCode,
      );
      _stopFallbackElapsed();
    } else {
      await _speechService.stopListening();
    }

    final transcript = _activeRecognizedText;
    final durationSeconds = _activeElapsed.inSeconds;
    final assessmentAudioBytes = await _consumeAssessmentAudioBytes();
    if (transcript.isEmpty) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(appLanguage.t('practice.noSpeechDetected'));
      }
      return;
    }

    // Attempt Azure Pronunciation Assessment (graceful fallback)
    PronunciationResult? azureResult;
    final azureService = AzurePronunciationService();
    if (azureService.isConfigured && assessmentAudioBytes != null) {
      try {
        azureResult = await azureService.assess(
          audioBytes: assessmentAudioBytes,
          referenceText: widget.content.isNotEmpty
              ? widget.content
              : transcript,
          language: appLanguage.speechLanguageCode,
        );
      } catch (e) {
        debugPrint('[Practice] Azure pronunciation assessment failed: $e');
        // Continue without Azure results — will fall back to local metrics.
      }
    }

    await _savePracticeSession(
      transcript: transcript,
      durationSeconds: durationSeconds,
      azureResult: azureResult,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          transcript: transcript,
          durationSeconds: durationSeconds,
          pronunciationResult: azureResult,
        ),
      ),
    );
  }

  Future<void> _startAssessmentRecording() async {
    if (_useCloudSpeech) return;
    if (await _assessmentRecorder.isRecording()) {
      await _assessmentRecorder.stop();
    }

    final hasPermission = await _assessmentRecorder.hasPermission();
    if (!hasPermission) return;

    final dir = Directory.systemTemp;
    _assessmentAudioPath =
        '${dir.path}/practice_assessment_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _assessmentRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _assessmentAudioPath!,
    );
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

  Future<void> _savePracticeSession({
    required String transcript,
    required int durationSeconds,
    PronunciationResult? azureResult,
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
    final score = azureResult != null
        ? azureResult.overallScore.round()
        : ((fluency + pronunciation) / 2).round();

    final firestoreService = FirestoreService();
    try {
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
        accuracyScore: azureResult?.accuracyScore ?? 0,
        fluencyScore: azureResult?.fluencyScore ?? 0,
        completenessScore: azureResult?.completenessScore ?? 0,
        prosodyScore: azureResult?.prosodyScore ?? 0,
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
    } catch (e) {
      debugPrint('Failed to save practice session: $e');
      if (mounted) {
        _showSnackBar(appLanguage.t('common.error'));
      }
    }
  }

  void _handleSpeechUpdate() {
    if (!mounted) return;
    final error = _speechService.lastError;
    if (error != null &&
        error.isNotEmpty &&
        !_speechService.isListening &&
        error != _lastSpeechError) {
      _lastSpeechError = error;
      _showSnackBar(error);
    }
    setState(() {});
  }

  void _handleNativeSpeechUpdate() {
    if (!mounted) return;
    final isListening = _nativeSpeechService.isListening;
    final error = _nativeSpeechService.lastError;

    if (!isListening && _fallbackStartedAt != null) {
      _stopFallbackElapsed();
    }

    if (error != null &&
        error.isNotEmpty &&
        !isListening &&
        error != _lastSpeechError) {
      _lastSpeechError = error;
      _showSnackBar(error);
    }

    setState(() {});
  }

  Future<void> _closeScreen() async {
    _stopPromptAudio();
    _fallbackElapsedTicker?.cancel();
    if (_useNativeSpeech) {
      await _nativeSpeechService.cancelListening();
    } else if (_useCloudSpeech) {
      await _cloudSpeechService.cancelListening();
    } else {
      await _speechService.cancelListening();
    }
    if (await _assessmentRecorder.isRecording()) {
      final path = await _assessmentRecorder.stop();
      if (path != null) {
        final file = File(path);
        await file.delete().catchError((_) => file);
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _speakPromptText() async {
    final text = widget.content.trim();
    if (text.isEmpty) return;
    if (!_ttsService.isConfigured) {
      _showSnackBar(
        'Missing Google TTS key. Add --dart-define=GOOGLE_TTS_API_KEY=YOUR_KEY',
      );
      return;
    }

    setState(() {
      _isTtsLoading = true;
      _isTtsPlaying = false;
    });
    try {
      final ttsConfig = await _resolveVietnameseTtsConfig();
      final bytes = await _ttsService.synthesize(
        text: text,
        languageCode: appLanguage.speechLanguageCode,
        voiceName: ttsConfig.voiceName,
        speakingRate: ttsConfig.speed,
      );
      await _ttsPlayer.stop();
      await _ttsPlayer.play(BytesSource(bytes), volume: 1.0);
      if (!mounted) return;
      setState(() => _isTtsPlaying = true);
    } catch (e) {
      _showSnackBar('Google TTS error: $e');
    } finally {
      if (mounted) {
        setState(() => _isTtsLoading = false);
      }
    }
  }

  Future<void> _stopPromptAudio() async {
    await _ttsPlayer.stop();
    if (!mounted) return;
    setState(() => _isTtsPlaying = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _localeIdForApp() {
    return appLanguage.speechLocaleId;
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

class _RecordingRealtimeMeterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double progress;

  const _RecordingRealtimeMeterCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.onboardingBlueDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: style.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.dashboardTextMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: style.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardNavy,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 8,
              backgroundColor: AppColors.dashboardTextMuted.withValues(
                alpha: 0.16,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                safeProgress > 0.75
                    ? AppColors.practicePurpleDeep
                    : safeProgress > 0.4
                    ? AppColors.onboardingBlue
                    : AppColors.recordingDotRecording,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
