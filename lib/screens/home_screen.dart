import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  static TextStyle get _display => GoogleFonts.plusJakartaSans();

  @override
  Widget build(BuildContext context) {
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
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.onboardingBlue,
                        size: 24,
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
              'Hello, User',
              style: _display.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.dashboardNavy,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Let\'s practice speaking today',
              style: _display.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.dashboardTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onNavigate(1),
                borderRadius: BorderRadius.circular(28),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.dashboardHeroGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onboardingBlue.withValues(alpha: 0.32),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Start Speaking Practice',
                          textAlign: TextAlign.center,
                          style: _display.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to start recording your speech.',
                          textAlign: TextAlign.center,
                          style: _display.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(child: const _HomeHeroMic()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dashboardNavy.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Speech Score',
                    style: _display.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dashboardTextMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(child: _DailyScoreDonut(score: 78, maxScore: 100)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DashboardMetricRow(
              icon: Icons.waves_rounded,
              label: 'Fluency',
              value: '85%',
              iconBg: AppColors.dashboardFluencyIconBg,
              accent: AppColors.dashboardFluencyAccent,
            ),
            const SizedBox(height: 10),
            _DashboardMetricRow(
              icon: Icons.record_voice_over_rounded,
              label: 'Pronunciation',
              value: '90%',
              iconBg: AppColors.dashboardPronunciationIconBg,
              accent: AppColors.dashboardPronunciationAccent,
            ),
            const SizedBox(height: 10),
            _DashboardMetricRow(
              icon: Icons.speed_rounded,
              label: 'Speech Speed',
              value: '75%',
              iconBg: AppColors.dashboardSpeedIconBg,
              accent: AppColors.dashboardSpeedAccent,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Practice',
                  style: _display.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardNavy,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onboardingBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: _display.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onboardingBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RecentPracticeItem(
              date: 'Today',
              detail: '5 sessions',
              score: 82,
            ),
            const SizedBox(height: 10),
            _RecentPracticeItem(
              date: 'Yesterday',
              detail: '3 sessions',
              score: 75,
            ),
            const SizedBox(height: 10),
            _RecentPracticeItem(
              date: 'Monday',
              detail: '4 sessions',
              score: 80,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroMic extends StatelessWidget {
  const _HomeHeroMic();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.mic_rounded,
        color: AppColors.onboardingBlue,
        size: 42,
      ),
    );
  }
}

/// Ring / fill / typography for the daily score donut, from normalized points.
class _DailyScorePalette {
  final Color ring;
  final Color fill;
  final Color scoreNumber;
  final Color subtitle;
  final Color shadow;

  const _DailyScorePalette({
    required this.ring,
    required this.fill,
    required this.scoreNumber,
    required this.subtitle,
    required this.shadow,
  });

  factory _DailyScorePalette.forScore(int score, int maxScore) {
    if (maxScore <= 0) {
      return _DailyScorePalette(
        ring: AppColors.dashboardNavy,
        fill: AppColors.dashboardBackground,
        scoreNumber: AppColors.dashboardNavy,
        subtitle: AppColors.dashboardTextMuted,
        shadow: AppColors.dashboardNavy,
      );
    }
    final r = (score / maxScore).clamp(0.0, 1.0);
    if (r < 0.5) {
      return _DailyScorePalette(
        ring: AppColors.feedbackAttention,
        fill: const Color(0xFFFFF4ED),
        scoreNumber: const Color(0xFFC2410C),
        subtitle: const Color(0xFF9A3412),
        shadow: AppColors.feedbackAttention,
      );
    }
    if (r < 0.65) {
      return _DailyScorePalette(
        ring: AppColors.feedbackWarning,
        fill: const Color(0xFFFFFBEB),
        scoreNumber: const Color(0xFFB45309),
        subtitle: const Color(0xFF92400E),
        shadow: AppColors.feedbackWarning,
      );
    }
    if (r < 0.85) {
      return _DailyScorePalette(
        ring: AppColors.onboardingBlue,
        fill: const Color(0xFFEEF4FF),
        scoreNumber: AppColors.onboardingBlueDeep,
        subtitle: AppColors.dashboardTextMuted,
        shadow: AppColors.onboardingBlue,
      );
    }
    return _DailyScorePalette(
      ring: AppColors.feedbackGood,
      fill: const Color(0xFFECFDF5),
      scoreNumber: const Color(0xFF047857),
      subtitle: const Color(0xFF065F46),
      shadow: AppColors.feedbackGood,
    );
  }
}

class _DailyScoreDonut extends StatelessWidget {
  final int score;
  final int maxScore;

  const _DailyScoreDonut({
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    final palette = _DailyScorePalette.forScore(score, maxScore);
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.fill,
        border: Border.all(
          color: palette.ring,
          width: 14,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: style.copyWith(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: palette.scoreNumber,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/ $maxScore',
            style: style.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color accent;

  const _DashboardMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.dashboardMetricRowBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: style.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.dashboardNavy,
              ),
            ),
          ),
          Text(
            value,
            style: style.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPracticeItem extends StatelessWidget {
  final String date;
  final String detail;
  final int score;

  const _RecentPracticeItem({
    required this.date,
    required this.detail,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardNavy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dashboardSpeedIconBg,
            ),
            child: Icon(
              Icons.history_rounded,
              color: AppColors.onboardingBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: style.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: style.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dashboardTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: style.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onboardingBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SCORE',
                style: style.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.dashboardTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
