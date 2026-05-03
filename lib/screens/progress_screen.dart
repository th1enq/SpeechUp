import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../models/practice_session.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _showWeekly = true;
  final FirestoreService _firestoreService = FirestoreService();
  UserProfile? _profile;
  bool _isLoading = true;
  List<int> _weeklyScores = [];
  DateTime _weekEnd = DateTime.now();
  int _selectedDayIndex = 6;
  List<PracticeSession> _selectedDaySessions = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _canGoNextWeek {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedEnd = DateTime(_weekEnd.year, _weekEnd.month, _weekEnd.day);
    return normalizedEnd.isBefore(normalizedToday);
  }

  Future<void> _loadWeeklyScores(String uid) async {
    final weeklyScores =
        await _firestoreService.getWeeklyScores(uid, endDate: _weekEnd);
    if (!mounted) return;
    setState(() {
      _weeklyScores = weeklyScores;
    });
  }

  DateTime _dateForSelectedIndex(int index) {
    final normalizedEnd = DateTime(_weekEnd.year, _weekEnd.month, _weekEnd.day);
    return normalizedEnd.subtract(Duration(days: 6 - index));
  }

  Future<void> _loadSelectedDaySessions(String uid) async {
    final date = _dateForSelectedIndex(_selectedDayIndex);
    final sessions = await _firestoreService.getSessionsForDate(uid, date);
    if (!mounted) return;
    setState(() {
      _selectedDaySessions = sessions;
    });
  }

  Future<void> _loadData() async {
    if (!isFirebaseSupported) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        final weeklyScores =
            await _firestoreService.getWeeklyScores(user.uid, endDate: _weekEnd);
        final selectedDaySessions = await _firestoreService.getSessionsForDate(
          user.uid,
          _dateForSelectedIndex(_selectedDayIndex),
        );
        if (mounted) {
          setState(() {
            _profile = profile;
            _weeklyScores = weeklyScores;
            _selectedDaySessions = selectedDaySessions;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading progress data: $e');
        if (mounted) {
          setState(() {
            _profile = null;
            _weeklyScores = const [];
            _selectedDaySessions = const [];
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goPrevWeek() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _weekEnd = _weekEnd.subtract(const Duration(days: 7));
      _selectedDayIndex = 6;
    });
    await _loadWeeklyScores(user.uid);
    await _loadSelectedDaySessions(user.uid);
  }

  Future<void> _goNextWeek() async {
    if (!_canGoNextWeek) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final next = _weekEnd.add(const Duration(days: 7));
    final normalizedNext = DateTime(next.year, next.month, next.day);

    setState(() {
      _weekEnd = normalizedNext.isAfter(normalizedToday) ? normalizedToday : normalizedNext;
      _selectedDayIndex = 6;
    });
    await _loadWeeklyScores(user.uid);
    await _loadSelectedDaySessions(user.uid);
  }

  Future<void> _onSelectDay(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _selectedDayIndex = index);
    if (user == null || !isFirebaseSupported) return;
    await _loadSelectedDaySessions(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
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
                          Icons.person_rounded,
                          color: c.accentBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SpeechUp',
                        style: base.copyWith(
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
                t('progress.title'),
                style: base.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: c.textHeading,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  t(
                    'progress.monthlyMinutes',
                    params: {
                      'minutes': '${_profile?.totalSpeakingMinutes.round() ?? 0}',
                    },
                  ),
                  style: base.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                    height: 1.45,
                  ),
                ),
              const SizedBox(height: 20),
              if (_showWeekly) ...[
                _Recent7DaysNav(
                  base: base,
                  c: c,
                  weekEnd: _weekEnd,
                  selectedIndex: _selectedDayIndex,
                  dailyScores: _weeklyScores,
                  onSelect: _onSelectDay,
                  onPrev: _goPrevWeek,
                  onNext: _goNextWeek,
                  canGoNext: _canGoNextWeek,
                ),
                const SizedBox(height: 12),
                _DailyStudySummaryCard(
                  base: base,
                  c: c,
                  date: _dateForSelectedIndex(_selectedDayIndex),
                  sessions: _selectedDaySessions,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.toggleTrackBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PeriodToggleChip(
                        label: t('progress.weekly'),
                        selected: _showWeekly,
                        onTap: () => setState(() => _showWeekly = true),
                        c: c,
                      ),
                    ),
                    Expanded(
                      child: _PeriodToggleChip(
                        label: t('progress.monthly'),
                        selected: !_showWeekly,
                        onTap: () => setState(() => _showWeekly = false),
                        c: c,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _FluencyScoreCard(
                base: base,
                scores: _weeklyScores,
                selectedIndex: _selectedDayIndex,
                c: c,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 14),
              _PronunciationCard(base: base, c: c),
              const SizedBox(height: 14),
              _SpeechSpeedTrendCard(base: base, averageSpeed: 142, targetSpeed: 150, c: c), // Replace 142 with real metric if available
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('progress.milestones'),
                    style: base.copyWith(
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
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MilestoneItem(
                      base: base,
                      icon: Icons.local_fire_department_rounded,
                      iconColor: c.accentPurple,
                      label: t('progress.milestoneStreak'),
                      c: c,
                    ),
                  ),
                  Expanded(
                    child: _MilestoneItem(
                      base: base,
                      icon: Icons.auto_awesome_rounded,
                      iconColor: c.accentBlue,
                      label: t('progress.milestoneFluency'),
                      c: c,
                    ),
                  ),
                  Expanded(
                    child: _MilestoneItem(
                      base: base,
                      icon: Icons.schedule_rounded,
                      iconColor: c.accentPurple,
                      label: t('progress.milestoneHour'),
                      c: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  color: c.accentBlue,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: c.accentBlue.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('progress.aiRecommendation'),
                            style: base.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('progress.aiRecommendationBody'),
                            style: base.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColorsExtension c;

  const _PeriodToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? c.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: font.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? c.accentBlue
                    : c.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FluencyScoreCard extends StatelessWidget {
  final TextStyle base;
  final List<int> scores;
  final int selectedIndex;
  final AppColorsExtension c;
  final bool isLoading;

  const _FluencyScoreCard({
    required this.base,
    required this.scores,
    required this.selectedIndex,
    required this.c,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final f = base;
    
    // Fallback logic
    final displayScores = scores.isEmpty ? [44, 58, 50, 64, 78, 60, 85] : scores;
    final safeIndex = selectedIndex.clamp(0, displayScores.length - 1);
    final currentScore = displayScores.isNotEmpty ? displayScores[safeIndex] : 0;
    
    // Normalize to max 100 for height, min height 4.0
    final barHeights = displayScores.map((s) => (s / 100.0 * 92.0).clamp(4.0, 92.0)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(26),
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
          Row(
            children: [
              Text(
                appLanguage.t('progress.fluencyScore'),
                style: f.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: c.textMuted,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: c.progressTrendRed,
                    size: 18,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '+12%', // To be real calculated later if we have previous week data
                    style: f.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.progressTrendRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const CircularProgressIndicator()
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$currentScore',
                    style: f.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: c.textHeading,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: '/100',
                    style: f.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < barHeights.length; i++)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: barHeights[i],
                        decoration: BoxDecoration(
                          color: i == safeIndex
                              ? c.accentBlue
                              : c.progressBarPale.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
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

class _DailyStudySummaryCard extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final DateTime date;
  final List<PracticeSession> sessions;
  final bool isLoading;

  const _DailyStudySummaryCard({
    required this.base,
    required this.c,
    required this.date,
    required this.sessions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final f = base;

    final totalSeconds = sessions.fold<int>(0, (acc, s) => acc + s.durationSeconds);
    final totalMinutes = (totalSeconds / 60).round();
    final sessionCount = sessions.length;
    final avgScore = sessionCount == 0
        ? 0
        : (sessions.fold<int>(0, (acc, s) => acc + s.score) / sessionCount).round();

    final dateLabel = MaterialLocalizations.of(context).formatFullDate(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: f.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.accentBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Minutes',
                  value: '$totalMinutes',
                  icon: Icons.schedule_rounded,
                  c: c,
                  base: f,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Sessions',
                  value: '$sessionCount',
                  icon: Icons.auto_awesome_rounded,
                  c: c,
                  base: f,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Avg',
                  value: '$avgScore',
                  icon: Icons.insights_rounded,
                  c: c,
                  base: f,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppColorsExtension c;
  final TextStyle base;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.c,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: c.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.7), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.accentBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: base.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                    height: 1,
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

class _PronunciationCard extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;

  const _PronunciationCard({required this.base, required this.c});

  @override
  Widget build(BuildContext context) {
    final f = base;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLanguage.t('progress.pronunciation'),
                  style: f.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appLanguage.t('progress.steadyGrowth'),
                  style: f.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Recent7DaysNav extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final DateTime weekEnd;
  final int selectedIndex;
  final List<int> dailyScores;
  final ValueChanged<int> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _Recent7DaysNav({
    required this.base,
    required this.c,
    required this.weekEnd,
    required this.selectedIndex,
    required this.dailyScores,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  static const _weekdayShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final f = base;

    final normalizedEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
    final days = List<DateTime>.generate(
      7,
      (i) => normalizedEnd.subtract(Duration(days: 6 - i)),
    );

    final monthYear = MaterialLocalizations.of(context).formatMonthYear(normalizedEnd);

    final bg = c.cardBg;
    final border = c.borderColor;
    final shadow = c.shadowColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthYear,
                  style: f.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                    height: 1.05,
                  ),
                ),
              ),
              _NavIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrev,
                c: c,
              ),
              const SizedBox(width: 10),
              _NavIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: canGoNext ? onNext : null,
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == days.length - 1 ? 0 : 8),
                    child: _DayNavItem(
                      weekday: _weekdayShort[(days[i].weekday - 1).clamp(0, 6)],
                      day: days[i].day,
                      selected: i == selectedIndex,
                      completed: dailyScores.length == 7 ? dailyScores[i] > 0 : false,
                      onTap: () => onSelect(i),
                      c: c,
                      borderColor: border,
                      base: f,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final AppColorsExtension c;

  const _NavIconButton({
    required this.icon,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: c.surfaceBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: c.borderColor.withValues(alpha: enabled ? 1 : 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? c.textHeading : c.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DayNavItem extends StatelessWidget {
  final String weekday;
  final int day;
  final bool selected;
  final bool completed;
  final VoidCallback onTap;
  final AppColorsExtension c;
  final Color borderColor;
  final TextStyle base;

  const _DayNavItem({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.completed,
    required this.onTap,
    required this.c,
    required this.borderColor,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayColor = selected ? Colors.white.withValues(alpha: 0.92) : c.textMuted;
    final dayColor = selected ? Colors.white : c.textHeading;

    final indicatorColor = completed
        ? (selected ? Colors.white : c.accentPurple)
        : borderColor.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? c.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekday,
                style: base.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: weekdayColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$day',
                style: base.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: dayColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechSpeedTrendCard extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final int averageSpeed;
  final int targetSpeed;

  const _SpeechSpeedTrendCard({
    required this.base,
    required this.c,
    required this.averageSpeed,
    required this.targetSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final f = base;
    final targetProgress = (averageSpeed / targetSpeed).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.progressSpeedStart,
            c.progressSpeedEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLanguage.t('progress.speechSpeedTrend'),
            style: f.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.textHeading,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                appLanguage.t('progress.averageSpeed'),
                style: f.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textHeading,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: c.accentBlue.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$averageSpeed ${appLanguage.t('progress.wpm')}',
                  style: f.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: c.surfaceBg.withValues(alpha: 0.85)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: targetProgress,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accentBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            appLanguage.t('progress.speedTarget'),
            style: f.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final TextStyle base;
  final IconData icon;
  final Color iconColor;
  final String label;
  final AppColorsExtension c;

  const _MilestoneItem({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final f = base;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.cardBg,
            boxShadow: [
              BoxShadow(
                color: c.shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: f.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}
