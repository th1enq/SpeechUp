import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_language.dart';
import '../main.dart' show isFirebaseSupported;
import '../models/practice_session.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final String userName;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.userName = 'User',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static TextStyle get _display => GoogleFonts.plusJakartaSans();

  final FirestoreService _firestoreService = FirestoreService();
  late Future<_HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_HomeDashboardData> _loadDashboard() async {
    if (!isFirebaseSupported) {
      return _HomeDashboardData.fallback(widget.userName);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _HomeDashboardData.fallback(widget.userName);
    }

    try {
      final results = await Future.wait<dynamic>([
        _firestoreService.getUserProfile(user.uid),
        _firestoreService.getRecentSessions(user.uid, limit: 6),
        _firestoreService.getDailyScore(user.uid),
      ]);

      final profile = results[0] as UserProfile?;
      final sessions = results[1] as List<PracticeSession>;
      final dailyScore = results[2] as int;

      return _HomeDashboardData.fromData(
        profile: profile,
        sessions: sessions,
        dailyScore: dailyScore,
        fallbackName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : widget.userName,
      );
    } catch (_) {
      return _HomeDashboardData.fallback(widget.userName);
    }
  }

  Future<void> _refreshDashboard() async {
    final future = _loadDashboard();
    if (!mounted) return;
    setState(() => _dashboardFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_HomeDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? _HomeDashboardData.fallback(widget.userName);

          return RefreshIndicator(
            color: AppColors.onboardingBlue,
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(onNavigate: widget.onNavigate),
                  const SizedBox(height: 22),
                  _GreetingCard(data: data),
                  const SizedBox(height: 18),
                  _StreakCard(data: data),
                  const SizedBox(height: 18),
                  _OverviewCard(data: data),
                  const SizedBox(height: 18),
                  _QuickMetricsCard(data: data),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onNavigate(1),
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
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Row(
                            children: [
                              const Expanded(child: _StartPracticeCopy()),
                              const SizedBox(width: 16),
                              const _HomeHeroMic(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RecentSessionsSection(data: data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Function(int) onNavigate;

  const _TopBar({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
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
              style: _HomeScreenState._display.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.dashboardNavy,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => onNavigate(4),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            Icons.person_outline_rounded,
            color: AppColors.dashboardNavy,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final _HomeDashboardData data;

  const _GreetingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final initials = _initialsFromName(data.userName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardNavy.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.dashboardHeroGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: _HomeScreenState._display.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('home.greeting', params: {'name': data.userName}),
                  style: _HomeScreenState._display.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardNavy,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đây là không gian luyện nói riêng của bạn hôm nay.',
                  style: _HomeScreenState._display.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dashboardTextMuted,
                    height: 1.4,
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

class _StreakCard extends StatelessWidget {
  final _HomeDashboardData data;

  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.calmMintSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.calmMint,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chuỗi hoạt động',
                      style: _HomeScreenState._display.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.calmText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.streakDays} ngày luyện tập liên tiếp',
                      style: _HomeScreenState._display.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.calmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${data.streakDays}',
                style: _HomeScreenState._display.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.calmText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Hôm nay',
                  value: '${data.todaySessions}',
                  hint: 'buổi luyện',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Tổng buổi',
                  value: '${data.totalSessions}',
                  hint: 'đã hoàn thành',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Thời lượng',
                  value: '${data.totalMinutes}',
                  hint: 'phút luyện',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final _HomeDashboardData data;

  const _OverviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
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
            'Đánh giá tổng quát',
            style: _HomeScreenState._display.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tổng hợp từ các buổi luyện gần đây để bạn biết mình đang tiến bộ ở đâu.',
            style: _HomeScreenState._display.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.dashboardTextMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _DailyScoreDonut(score: data.overallScore, maxScore: 100),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _InsightTile(
                      title: 'Đã cải thiện',
                      message: data.improvedArea,
                      icon: Icons.trending_up_rounded,
                      background: AppColors.calmMintSurface,
                      iconColor: AppColors.calmMint,
                      textColor: AppColors.calmText,
                    ),
                    const SizedBox(height: 10),
                    _InsightTile(
                      title: 'Cần khắc phục',
                      message: data.needsWorkArea,
                      icon: Icons.track_changes_rounded,
                      background: AppColors.calmBlueSurface,
                      iconColor: AppColors.onboardingBlue,
                      textColor: AppColors.dashboardNavy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickMetricsCard extends StatelessWidget {
  final _HomeDashboardData data;

  const _QuickMetricsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricInfo(
        icon: Icons.waves_rounded,
        label: 'Độ trôi chảy',
        value: '${data.fluency}%',
        iconBg: AppColors.dashboardFluencyIconBg,
        accent: AppColors.dashboardFluencyAccent,
      ),
      _MetricInfo(
        icon: Icons.record_voice_over_rounded,
        label: 'Phát âm',
        value: '${data.pronunciation}%',
        iconBg: AppColors.dashboardPronunciationIconBg,
        accent: AppColors.dashboardPronunciationAccent,
      ),
      _MetricInfo(
        icon: Icons.speed_rounded,
        label: 'Nhịp nói',
        value: data.speechRateLabel,
        iconBg: AppColors.dashboardSpeedIconBg,
        accent: AppColors.dashboardSpeedAccent,
      ),
    ];

    return Column(
      children: metrics
          .map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DashboardMetricRow(
                icon: metric.icon,
                label: metric.label,
                value: metric.value,
                iconBg: metric.iconBg,
                accent: metric.accent,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StartPracticeCopy extends StatelessWidget {
  const _StartPracticeCopy();

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('home.startPractice'),
          style: _HomeScreenState._display.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t('home.startPracticeHint'),
          style: _HomeScreenState._display.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _RecentSessionsSection extends StatelessWidget {
  final _HomeDashboardData data;

  const _RecentSessionsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Luyện tập gần đây',
          style: _HomeScreenState._display.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.dashboardNavy,
          ),
        ),
        const SizedBox(height: 12),
        if (data.recentSessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
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
            child: Text(
              'Chưa có dữ liệu luyện tập gần đây. Hãy bắt đầu một buổi luyện để SpeechUp tạo đánh giá đầu tiên.',
              style: _HomeScreenState._display.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.dashboardTextMuted,
                height: 1.45,
              ),
            ),
          )
        else
          ...data.recentSessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentPracticeItem(
                date: _relativeDate(session.createdAt),
                detail: _sessionDetail(session),
                score: session.score,
              ),
            ),
          ),
      ],
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _HomeScreenState._display.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.calmTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: _HomeScreenState._display.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.calmText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: _HomeScreenState._display.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.calmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final Color textColor;

  const _InsightTile({
    required this.title,
    required this.message,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _HomeScreenState._display.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: _HomeScreenState._display.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.35,
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
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.fill,
        border: Border.all(color: palette.ring, width: 12),
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
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: palette.scoreNumber,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Điểm tổng quát',
            style: style.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

class _MetricInfo {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color accent;

  const _MetricInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.accent,
  });
}

class _HomeDashboardData {
  final String userName;
  final int streakDays;
  final int todaySessions;
  final int totalSessions;
  final int totalMinutes;
  final int overallScore;
  final int fluency;
  final int pronunciation;
  final int speechRateWpm;
  final String improvedArea;
  final String needsWorkArea;
  final List<PracticeSession> recentSessions;

  const _HomeDashboardData({
    required this.userName,
    required this.streakDays,
    required this.todaySessions,
    required this.totalSessions,
    required this.totalMinutes,
    required this.overallScore,
    required this.fluency,
    required this.pronunciation,
    required this.speechRateWpm,
    required this.improvedArea,
    required this.needsWorkArea,
    required this.recentSessions,
  });

  factory _HomeDashboardData.fromData({
    required UserProfile? profile,
    required List<PracticeSession> sessions,
    required int dailyScore,
    required String fallbackName,
  }) {
    final effectiveSessions = sessions;
    final latestSession =
        effectiveSessions.isEmpty ? null : effectiveSessions.first;
    final avgFluency = _averageInt(
      effectiveSessions.map((session) => session.fluency),
      fallback: 0,
    );
    final avgPronunciation = _averageInt(
      effectiveSessions.map((session) => session.pronunciation),
      fallback: 0,
    );
    final avgWpm = _averageInt(
      effectiveSessions.map((session) => session.speechSpeed),
      fallback: 0,
    );
    final overall = dailyScore > 0
        ? dailyScore
        : (profile?.averageScore ?? _averageInt(
            effectiveSessions.map((session) => session.score),
            fallback: 0,
          ));

    final contextualInsights = _contextualInsights(
      latestSession: latestSession,
      avgFluency: avgFluency,
      avgPronunciation: avgPronunciation,
      avgWpm: avgWpm,
    );

    final strengths = <MapEntry<String, int>>[
      if (contextualInsights.improvedText.isNotEmpty)
        MapEntry(contextualInsights.improvedText, contextualInsights.improvedWeight),
      MapEntry('Phát âm rõ ràng và ổn định hơn trong các câu trả lời gần đây.', avgPronunciation),
      MapEntry('Độ trôi chảy đang tốt hơn, các câu nối mạch hơn trước.', avgFluency),
      MapEntry(_paceStrength(avgWpm), _paceScore(avgWpm)),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final focusAreas = <MapEntry<String, int>>[
      if (contextualInsights.needsWorkText.isNotEmpty)
        MapEntry(contextualInsights.needsWorkText, contextualInsights.needsWorkWeight),
      MapEntry(_paceWeakness(avgWpm), 100 - _paceScore(avgWpm)),
      MapEntry('Hãy giữ nhịp thở và khoảng dừng tự nhiên để câu nói đỡ gấp.', 100 - avgFluency),
      MapEntry('Bạn có thể nhấn rõ các từ khóa hơn để người nghe bắt ý nhanh hơn.', 100 - avgPronunciation),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final todayCount = _todaySessionCount(effectiveSessions);

    return _HomeDashboardData(
      userName: (profile?.displayName.trim().isNotEmpty ?? false)
          ? profile!.displayName
          : fallbackName,
      streakDays: profile?.streakDays ?? 0,
      todaySessions: todayCount,
      totalSessions: profile?.totalSessions ?? effectiveSessions.length,
      totalMinutes: (profile?.totalSpeakingMinutes ?? 0).round(),
      overallScore: overall.clamp(0, 100),
      fluency: avgFluency.clamp(0, 100),
      pronunciation: avgPronunciation.clamp(0, 100),
      speechRateWpm: avgWpm,
      improvedArea: strengths.first.key,
      needsWorkArea: focusAreas.first.key,
      recentSessions: effectiveSessions.take(4).toList(),
    );
  }

  factory _HomeDashboardData.fallback(String userName) {
    return _HomeDashboardData(
      userName: userName,
      streakDays: 0,
      todaySessions: 0,
      totalSessions: 0,
      totalMinutes: 0,
      overallScore: 0,
      fluency: 0,
      pronunciation: 0,
      speechRateWpm: 0,
      improvedArea: 'Bắt đầu một buổi luyện để SpeechUp ghi nhận tiến bộ đầu tiên của bạn.',
      needsWorkArea: 'Khi có dữ liệu luyện nói, phần này sẽ gợi ý điểm cần tập trung thêm.',
      recentSessions: const [],
    );
  }

  String get speechRateLabel {
    if (speechRateWpm <= 0) return '--';
    return '$speechRateWpm wpm';
  }

  static int _todaySessionCount(List<PracticeSession> sessions) {
    final now = DateTime.now();
    return sessions.where((session) {
      final d = session.createdAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  static int _averageInt(Iterable<int> values, {required int fallback}) {
    final list = values.where((value) => value > 0).toList();
    if (list.isEmpty) return fallback;
    final total = list.fold<int>(0, (sum, value) => sum + value);
    return (total / list.length).round();
  }

  static int _paceScore(int wpm) {
    if (wpm <= 0) return 0;
    final diff = (wpm - 130).abs();
    return (100 - diff).clamp(0, 100);
  }

  static String _paceStrength(int wpm) {
    if (wpm == 0) {
      return 'Khi có thêm dữ liệu, SpeechUp sẽ đánh giá nhịp nói ổn định của bạn.';
    }
    if (wpm < 110) {
      return 'Bạn đã biết chậm lại để kiểm soát nhịp nói và giữ câu rõ hơn.';
    }
    if (wpm <= 145) {
      return 'Nhịp nói đang khá cân bằng, dễ nghe và ổn định hơn.';
    }
    return 'Bạn giữ được năng lượng nói tốt trong các tình huống phản hồi nhanh.';
  }

  static String _paceWeakness(int wpm) {
    if (wpm == 0) {
      return 'Hoàn thành một buổi luyện để hệ thống đánh giá nhịp nói chính xác hơn.';
    }
    if (wpm < 110) {
      return 'Bạn có thể nói liền mạch hơn một chút để câu trả lời tự nhiên hơn.';
    }
    if (wpm <= 145) {
      return 'Hãy tiếp tục giữ nhịp nói này và thêm khoảng dừng ngắn ở ý chính.';
    }
    return 'Tốc độ đang hơi nhanh, hãy chèn thêm khoảng dừng để người nghe dễ theo dõi.';
  }

  static _InsightContext _contextualInsights({
    required PracticeSession? latestSession,
    required int avgFluency,
    required int avgPronunciation,
    required int avgWpm,
  }) {
    if (latestSession == null) {
      return const _InsightContext.empty();
    }

    switch (latestSession.exerciseType) {
      case 'self_introduction':
        return _InsightContext(
          improvedText: avgPronunciation >= avgFluency
              ? 'Ở phần tự giới thiệu, bạn phát âm tên riêng và thông tin cá nhân rõ hơn, tạo cảm giác tự tin ngay từ đầu.'
              : 'Ở bài tự giới thiệu, câu mở đầu của bạn liền mạch hơn và ít bị ngắt hơn trước.',
          improvedWeight: avgPronunciation >= avgFluency
              ? avgPronunciation
              : avgFluency,
          needsWorkText: avgWpm > 145
              ? 'Khi tự giới thiệu, bạn đang vào ý khá nhanh. Hãy chậm lại một nhịp ở câu đầu để người nghe bắt kịp thông tin chính.'
              : 'Hãy thêm một câu chốt ngắn về điểm mạnh hoặc mục tiêu để phần tự giới thiệu trọn vẹn hơn.',
          needsWorkWeight: avgWpm > 145 ? 88 : 78,
        );
      case 'ordering_food':
        return _InsightContext(
          improvedText: avgFluency >= 70
              ? 'Trong tình huống gọi đồ uống, bạn đang giữ được nhịp nói tự nhiên hơn khi nêu món và yêu cầu thêm.'
              : 'Bạn đã diễn đạt yêu cầu gọi món rõ ý hơn, người nghe dễ hiểu món chính và phần bổ sung.',
          improvedWeight: avgFluency >= 70 ? avgFluency : avgPronunciation,
          needsWorkText: avgPronunciation < 70
              ? 'Ở bài gọi đồ uống, hãy nhấn rõ các từ khóa như tên món, size và yêu cầu thêm để tránh bị nghe nhầm.'
              : 'Khi gọi món, bạn có thể thêm một khoảng dừng ngắn giữa món chính và yêu cầu phụ để câu rõ hơn.',
          needsWorkWeight: avgPronunciation < 70 ? 84 : 76,
        );
      case 'interview_opening':
        return _InsightContext(
          improvedText: avgFluency >= avgPronunciation
              ? 'Trong phần mở đầu phỏng vấn, câu trả lời của bạn có cấu trúc rõ hơn và giữ được mạch nói ổn định hơn.'
              : 'Ở bài mở đầu phỏng vấn, cách nhấn các ý về kinh nghiệm và điểm mạnh đã rõ ràng hơn.',
          improvedWeight: avgFluency >= avgPronunciation
              ? avgFluency
              : avgPronunciation,
          needsWorkText: avgWpm < 110
              ? 'Phần mở đầu phỏng vấn đang hơi chậm. Bạn có thể nối các ý về kinh nghiệm và mục tiêu tự nhiên hơn để câu trả lời đỡ ngập ngừng.'
              : 'Hãy thêm một khoảng dừng ngắn trước ý mạnh nhất của bạn để câu trả lời phỏng vấn chắc và thuyết phục hơn.',
          needsWorkWeight: avgWpm < 110 ? 86 : 80,
        );
      case 'private_practice':
        return _InsightContext(
          improvedText: avgFluency >= avgPronunciation
              ? 'Ở buổi luyện tự do gần nhất, bạn nói trôi chảy hơn và giữ câu dài tốt hơn.'
              : 'Ở buổi luyện tự do gần nhất, độ rõ của giọng nói đang ổn định hơn.',
          improvedWeight: avgFluency >= avgPronunciation
              ? avgFluency
              : avgPronunciation,
          needsWorkText: avgPronunciation < 70
              ? 'Bạn có thể mở khẩu hình rõ hơn ở các từ khóa để phần luyện tự do nghe chắc hơn.'
              : _paceWeakness(avgWpm),
          needsWorkWeight: avgPronunciation < 70 ? 80 : 72,
        );
      default:
        return _InsightContext(
          improvedText: _paceStrength(avgWpm),
          improvedWeight: _paceScore(avgWpm),
          needsWorkText: _paceWeakness(avgWpm),
          needsWorkWeight: 100 - _paceScore(avgWpm),
        );
    }
  }
}

class _InsightContext {
  final String improvedText;
  final int improvedWeight;
  final String needsWorkText;
  final int needsWorkWeight;

  const _InsightContext({
    required this.improvedText,
    required this.improvedWeight,
    required this.needsWorkText,
    required this.needsWorkWeight,
  });

  const _InsightContext.empty()
      : improvedText = '',
        improvedWeight = 0,
        needsWorkText = '',
        needsWorkWeight = 0;
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'SU';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return appLanguage.t('common.today');
  if (diff == 1) return appLanguage.t('common.yesterday');
  return '${date.day}/${date.month}/${date.year}';
}

String _sessionDetail(PracticeSession session) {
  final duration = session.durationSeconds <= 0
      ? '< 1 min'
      : '${(session.durationSeconds / 60).ceil()} min';
  return '${_exerciseLabel(session.exerciseType)} • $duration';
}

String _exerciseLabel(String exerciseType) {
  switch (exerciseType) {
    case 'self_introduction':
      return 'Tự giới thiệu';
    case 'ordering_food':
      return 'Gọi đồ uống';
    case 'interview_opening':
      return 'Mở đầu phỏng vấn';
    case 'private_practice':
      return 'Luyện tự do';
    default:
      return exerciseType.replaceAll('_', ' ');
  }
}
