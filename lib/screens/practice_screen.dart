import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../models/practice_session.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  TextStyle get _display => GoogleFonts.plusJakartaSans();

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                            color: AppColors.dashboardNavy.withValues(alpha: 0.06),
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
                        color: AppColors.dashboardNavy,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
              t('practice.title'),
              style: _display.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.dashboardNavy,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('practice.subtitle'),
              style: _display.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.dashboardTextMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _PracticeExerciseCard(
              variant: _ExerciseVisual.readSentence,
              title: t('practice.readTitle'),
              body: t('practice.readBody'),
              bodyItalic: true,
              tagLabel: t('practice.easy'),
              onTap: () => _openRecording(
                context,
                exerciseType: 'read',
                content: t('practice.readBody'),
              ),
            ),
            const SizedBox(height: 14),
            _PracticeExerciseCard(
              variant: _ExerciseVisual.shadowing,
              title: t('practice.shadowingTitle'),
              body: t('practice.shadowingBody'),
              bodyItalic: false,
              tagLabel: t('practice.medium'),
              onTap: () => _openRecording(
                context,
                exerciseType: 'shadowing',
                content: 'Repeat after listening...',
              ),
            ),
            const SizedBox(height: 14),
            _PracticeExerciseCard(
              variant: _ExerciseVisual.slowSpeech,
              title: t('practice.slowTitle'),
              body: t('practice.slowBody'),
              bodyItalic: false,
              tagLabel: t('practice.hard'),
              onTap: () => _openRecording(
                context,
                exerciseType: 'slow',
                content: 'Speak slowly and clearly...',
              ),
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
        builder: (_) => _RecordingScreen(
          exerciseType: exerciseType,
          content: content,
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
        action = _GradientStartButton(onTap: onTap, label: appLanguage.t('common.start'));
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
                        fontStyle: bodyItalic ? FontStyle.italic : FontStyle.normal,
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

class _RecordingScreen extends StatelessWidget {
  final String exerciseType;
  final String content;

  const _RecordingScreen({
    required this.exerciseType,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final display = GoogleFonts.plusJakartaSans();
    void close() => Navigator.of(context).pop();

    Future<void> saveAndClose() async {
      if (!isFirebaseSupported) {
        close();
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firestoreService = FirestoreService();
        final session = PracticeSession(
          userId: user.uid,
          exerciseType: exerciseType,
          content: content,
          score: 82, // Simulated score
          durationSeconds: 60,
          fluency: 85,
          pronunciation: 90,
          speechSpeed: 75,
          createdAt: DateTime.now(),
        );
        await firestoreService.savePracticeSession(session);

        // Update user stats
        final profile = await firestoreService.getUserProfile(user.uid);
        if (profile != null) {
          await firestoreService.updateUserProfile(user.uid, {
            'totalSessions': profile.totalSessions + 1,
            'totalSpeakingMinutes': profile.totalSpeakingMinutes + 1.0,
          });
        }
        await firestoreService.updateStreak(user.uid);
      }
      close();
    }

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
                        onTap: close,
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
                  appLanguage.t('practice.listening'),
                  textAlign: TextAlign.center,
                  style: display.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardNavy,
                    height: 1.2,
                  ),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    content,
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
                const Center(child: _RecordingWaveform()),
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
                          color: AppColors.onboardingBlue.withValues(alpha: 0.42),
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
                        value: appLanguage.t('practice.normal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecordingMetricCard(
                        icon: Icons.pause_rounded,
                        label: appLanguage.t('practice.metricPauses'),
                        value: appLanguage.t('practice.none'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecordingMetricCard(
                        icon: Icons.graphic_eq_rounded,
                        label: appLanguage.t('practice.metricClarity'),
                        value: appLanguage.t('practice.high'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                SizedBox(
                  height: 54,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: saveAndClose,
                      borderRadius: BorderRadius.circular(27),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.dashboardHeroGradient,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.onboardingBlue.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            appLanguage.t('practice.stopRecording'),
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
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: close,
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
}

class _RecordingWaveform extends StatelessWidget {
  const _RecordingWaveform();

  static const List<double> _heights = [
    22, 32, 42, 52, 64, 76, 64, 52, 42, 32, 22,
  ];

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
        for (var i = 0; i < _heights.length; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          Container(
            width: barWidth,
            height: _heights[i],
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
          Icon(
            icon,
            color: AppColors.onboardingBlueDeep,
            size: 22,
          ),
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
