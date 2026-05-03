import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../models/practice_session.dart';
import '../services/firestore_service.dart';
import '../main.dart' show isFirebaseSupported;

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final String userName;

  const HomeScreen({super.key, required this.onNavigate, this.userName = 'User'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static TextStyle get _display => GoogleFonts.plusJakartaSans();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  int _dailyScore = 0;
  List<PracticeSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!isFirebaseSupported) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final dailyScore = await _firestoreService.getDailyScore(user.uid);
        final recentSessions = await _firestoreService.getRecentSessions(user.uid, limit: 5);
        if (mounted) {
          setState(() {
            _dailyScore = dailyScore;
            _recentSessions = recentSessions;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading home data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final c = context.colors;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: c.accentBlue,
        backgroundColor: c.cardBg,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                          color: c.cardBg,
                          boxShadow: [
                            BoxShadow(
                              color: c.shadowColor,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          color: c.accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SpeechUp',
                        style: _HomeScreenState._display.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: c.textHeading,
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
                      color: c.textHeading,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                t('home.greeting', params: {'name': widget.userName}),
                style: _HomeScreenState._display.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: c.textHeading,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t('home.subtitle'),
                style: _HomeScreenState._display.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onNavigate(1),
                  borderRadius: BorderRadius.circular(28),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: c.heroGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: c.accentBlue.withValues(alpha: 0.32),
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
                            t('home.startPractice'),
                            textAlign: TextAlign.center,
                            style: _HomeScreenState._display.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('home.startPracticeHint'),
                            textAlign: TextAlign.center,
                            style: _HomeScreenState._display.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(child: _HomeHeroMic(c: c)),
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
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('home.dailyScore'),
                      style: _HomeScreenState._display.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: _isLoading ? const CircularProgressIndicator() : _DailyScoreDonut(score: _dailyScore, maxScore: 100, c: c)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!_isLoading && _recentSessions.isNotEmpty) ...[
                Builder(builder: (context) {
                  final latestSession = _recentSessions.first;
                  return Column(
                    children: [
                      _DashboardMetricRow(
                        icon: Icons.waves_rounded,
                        label: t('home.fluency'),
                        value: '${latestSession.fluency}%',
                        iconBg: c.fluencyIconBg,
                        accent: c.fluencyAccent,
                        c: c,
                      ),
                      const SizedBox(height: 10),
                      _DashboardMetricRow(
                        icon: Icons.record_voice_over_rounded,
                        label: t('home.pronunciation'),
                        value: '${latestSession.pronunciation}%',
                        iconBg: c.pronunciationIconBg,
                        accent: c.pronunciationAccent,
                        c: c,
                      ),
                      const SizedBox(height: 10),
                      _DashboardMetricRow(
                        icon: Icons.speed_rounded,
                        label: t('home.speechSpeed'),
                        value: '${latestSession.speechSpeed} wpm',
                        iconBg: c.speedIconBg,
                        accent: c.speedAccent,
                        c: c,
                      ),
                    ],
                  );
                }),
              ] else ...[
                 _DashboardMetricRow(
                  icon: Icons.waves_rounded,
                  label: t('home.fluency'),
                  value: '--',
                  iconBg: c.fluencyIconBg,
                  accent: c.fluencyAccent,
                  c: c,
                ),
                const SizedBox(height: 10),
                _DashboardMetricRow(
                  icon: Icons.record_voice_over_rounded,
                  label: t('home.pronunciation'),
                  value: '--',
                  iconBg: c.pronunciationIconBg,
                  accent: c.pronunciationAccent,
                  c: c,
                ),
                const SizedBox(height: 10),
                _DashboardMetricRow(
                  icon: Icons.speed_rounded,
                  label: t('home.speechSpeed'),
                  value: '--',
                  iconBg: c.speedIconBg,
                  accent: c.speedAccent,
                  c: c,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('home.recentPractice'),
                    style: _HomeScreenState._display.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.textHeading,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: c.accentBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      t('common.viewAll'),
                      style: _HomeScreenState._display.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_recentSessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No recent sessions yet. Start practicing!',
                      style: TextStyle(color: c.textMuted),
                    ),
                  ),
                )
              else
                ..._recentSessions.map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentPracticeItem(
                      date: DateFormat.yMMMd().format(session.createdAt),
                      detail: '${session.durationSeconds}s duration',
                      score: session.score,
                      c: c,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeroMic extends StatelessWidget {
  final AppColorsExtension c;
  const _HomeHeroMic({required this.c});

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
        color: c.accentBlue,
        size: 42,
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

  factory _DailyScorePalette.forScore(int score, int maxScore, AppColorsExtension c) {
    if (maxScore <= 0 || score <= 0) {
      return _DailyScorePalette(
        ring: c.navInactive,
        fill: c.scaffoldBg,
        scoreNumber: c.textMuted,
        subtitle: c.textMuted,
        shadow: c.shadowColor,
      );
    }
    final r = (score / maxScore).clamp(0.0, 1.0);
    if (r < 0.5) {
      return _DailyScorePalette(
        ring: c.feedbackAttention,
        fill: const Color(0xFFFFF4ED),
        scoreNumber: const Color(0xFFC2410C),
        subtitle: const Color(0xFF9A3412),
        shadow: c.feedbackAttention,
      );
    }
    if (r < 0.65) {
      return _DailyScorePalette(
        ring: c.feedbackWarning,
        fill: const Color(0xFFFFFBEB),
        scoreNumber: const Color(0xFFB45309),
        subtitle: const Color(0xFF92400E),
        shadow: c.feedbackWarning,
      );
    }
    if (r < 0.85) {
      return _DailyScorePalette(
        ring: c.accentBlue,
        fill: c.metricRowBg,
        scoreNumber: c.accentBlueDeep,
        subtitle: c.textMuted,
        shadow: c.accentBlue,
      );
    }
    return _DailyScorePalette(
      ring: c.feedbackGood,
      fill: const Color(0xFFECFDF5),
      scoreNumber: const Color(0xFF047857),
      subtitle: const Color(0xFF065F46),
      shadow: c.feedbackGood,
    );
  }
}

class _DailyScoreDonut extends StatelessWidget {
  final int score;
  final int maxScore;
  final AppColorsExtension c;

  const _DailyScoreDonut({
    required this.score,
    required this.maxScore,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    final palette = _DailyScorePalette.forScore(score, maxScore, c);
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.fill,
        border: Border.all(color: palette.ring, width: 14),
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
            score > 0 ? '$score' : '--',
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
  final AppColorsExtension c;

  const _DashboardMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.accent,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.metricRowBg,
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
                color: c.textHeading,
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
  final AppColorsExtension c;

  const _RecentPracticeItem({
    required this.date,
    required this.detail,
    required this.score,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
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
              color: c.speedIconBg,
            ),
            child: Icon(
              Icons.history_rounded,
              color: c.accentBlue,
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
                    color: c.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: style.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
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
                  color: c.accentBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                appLanguage.t('home.score'),
                style: style.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
