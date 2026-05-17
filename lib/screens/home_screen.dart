import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';
import '../main.dart' show isFirebaseSupported;
import '../widgets/screen_header.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final ValueChanged<String>? onOpenChatTopic;
  final String userName;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.onOpenChatTopic,
    this.userName = 'User',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  int _todayMinutes = 0;
  int _streakDays = 0;
  int _dailyGoalMinutes = (FirestoreService.dailyStreakGoalSeconds / 60).ceil();
  TimeOfDay? _practiceTime;
  List<bool> _weeklyActivity = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    TimeOfDay? savedTime;
    try {
      savedTime = await NotificationService().getSavedPracticeTime();
    } catch (_) {}

    if (!isFirebaseSupported) {
      if (mounted) {
        setState(() {
          _practiceTime = savedTime;
          _isLoading = false;
        });
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _practiceTime = savedTime;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final sessions = await _firestoreService.getTodaySessions(user.uid);
      final totalSeconds = sessions.fold<int>(
        0,
        (acc, s) => acc + s.durationSeconds,
      );
      final minutes = (totalSeconds / 60).round();
      final dailyGoalMinutes = await _firestoreService
          .calculateDailyGoalMinutes(user.uid);

      // Load streak from user profile
      int streak = 0;
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        streak = profile?.streakDays ?? 0;
      } catch (_) {}

      // Build activity for the current Monday-Sunday week.
      List<bool> activity = List.filled(7, false);
      try {
        final recentSessions = await _firestoreService.getRecentSessions(
          user.uid,
          limit: 50,
        );
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          activity[i] = recentSessions.any(
            (s) =>
                s.createdAt.year == day.year &&
                s.createdAt.month == day.month &&
                s.createdAt.day == day.day,
          );
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _todayMinutes = minutes;
        _dailyGoalMinutes = dailyGoalMinutes;
        _streakDays = streak;
        _practiceTime = savedTime;
        _weeklyActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _goPractice() => widget.onNavigate(1);
  void _goChat() => widget.onNavigate(2);
  void _goProgress() => widget.onNavigate(3);
  void _goProfile() => widget.onNavigate(4);

  Future<void> _openTimePicker() async {
    final notificationService = NotificationService();
    final picked = await showTimePicker(
      context: context,
      initialTime: _practiceTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final granted = await notificationService.requestPermissions();
    if (!mounted) return;
    setState(() => _practiceTime = picked);
    if (!granted) {
      await notificationService.setNotificationsEnabled(false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Notification permission is required for phone reminders.',
          ),
        ),
      );
      return;
    }

    await notificationService.setNotificationsEnabled(true);
    if (isFirebaseSupported) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final nextReminderAt = _nextReminderDateTime(picked);
          await _firestoreService.updateUserProfile(user.uid, {
            'notificationsEnabled': true,
          });
          await _firestoreService.updatePracticeReminder(
            uid: user.uid,
            time: picked,
            nextReminderAt: nextReminderAt,
            enabled: true,
          );
          await FcmService().startForCurrentUser();
        } catch (_) {}
      }
    }

    final scheduled = await notificationService.scheduleAtUserTime(picked);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          scheduled
              ? 'Đã đặt nhắc nhở tập luyện.'
              : 'Chưa thể đặt nhắc nhở. Hãy bật thông báo trong Profile.',
        ),
      ),
    );
  }

  DateTime _nextReminderDateTime(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  List<String> _allTopics() {
    if (appLanguage.locale.languageCode == 'vi') {
      return const [
        'Du lịch',
        'Công việc',
        'Giới thiệu bản thân',
        'Mua sắm hằng ngày',
        'Hội thoại xã giao',
      ];
    }
    return const [
      'Travel',
      'Work',
      'Self Introduction',
      'Daily Shopping',
      'Small Talk',
    ];
  }

  Future<void> _openAllTopics() async {
    final topics = _allTopics();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final c = context.colors;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appLanguage.t('home.recommendedTopics'),
                  style: _base.copyWith(
                    color: c.textHeading,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                for (final topic in topics)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: Icon(
                      Icons.record_voice_over_rounded,
                      color: c.accentBlue,
                    ),
                    title: Text(
                      topic,
                      style: _base.copyWith(
                        color: c.textHeading,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: c.textMuted,
                      size: 16,
                    ),
                    onTap: () => Navigator.of(context).pop(topic),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    widget.onOpenChatTopic?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final c = context.colors;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final bottomContentPadding =
        kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom + 20;

    final safeMinutes = _todayMinutes.clamp(0, 999);
    final progress = (safeMinutes / _dailyGoalMinutes).clamp(0.0, 1.0);
    final percent = (progress * 100).round().clamp(0, 100);

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: c.accentBlue,
            backgroundColor: c.cardBg,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomContentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    title: t('home.appName'),
                    onAvatarTap: _goProfile,
                  ),
                  const SizedBox(height: 18),
                  _DailyGoalCard(
                    base: _base,
                    c: c,
                    isLoading: _isLoading,
                    percent: percent,
                    minutes: safeMinutes,
                    goalMinutes: _dailyGoalMinutes,
                    title: t('home.dailyGoal'),
                    subtitle: t(
                      'home.minsSpokenToday',
                      params: {
                        'current': '$safeMinutes',
                        'goal': '$_dailyGoalMinutes',
                      },
                    ),
                    badge: t('home.keepItUp'),
                  ),
                  const SizedBox(height: 16),
                  // ── Streak + Scheduler combined card ──
                  _StreakSchedulerCard(
                    base: _base,
                    c: c,
                    streakDays: _streakDays,
                    weeklyActivity: _weeklyActivity,
                    practiceTime: _practiceTime,
                    onScheduleTap: _openTimePicker,
                  ),
                  const SizedBox(height: 18),
                  _FeatureGrid(
                    base: _base,
                    c: c,
                    compact: compact,
                    items: [
                      _FeatureItem(
                        icon: Icons.smart_toy_outlined,
                        label: t('home.featureAiTalk'),
                        onTap: _goChat,
                        iconBg: c.feedbackAttention.withValues(alpha: 0.16),
                        iconColor: c.feedbackAttention,
                      ),
                      _FeatureItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: t('home.featureTopicPractice'),
                        onTap: _goPractice,
                        iconBg: c.accentBlue.withValues(alpha: 0.14),
                        iconColor: c.accentBlue,
                      ),
                      _FeatureItem(
                        icon: Icons.school_outlined,
                        label: t('home.featureGuidedSpeaking'),
                        onTap: _goProgress,
                        iconBg: c.accentPurple.withValues(alpha: 0.14),
                        iconColor: c.accentPurple,
                      ),
                      _FeatureItem(
                        icon: Icons.menu_book_outlined,
                        label: t('home.featureDailyScenarios'),
                        onTap: _goPractice,
                        iconBg: c.feedbackGood.withValues(alpha: 0.14),
                        iconColor: c.feedbackGood,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    t('home.learningPath'),
                    style: _base.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: c.textHeading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LearningPath(
                    base: _base,
                    c: c,
                    compact: compact,
                    onStart: _goPractice,
                    todayTag: t('home.todaysLessonTag'),
                    todayTitle: t('home.todaysLessonTitle'),
                    todayMeta: t('home.lessonMeta', params: {'mins': '12'}),
                    startLabel: t('home.startSession'),
                    tomorrowTitle: t('home.tomorrowTitle'),
                    tomorrowSubtitle: t('home.lockedUntilTomorrow'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('home.recommendedTopics'),
                          style: _base.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: c.textHeading,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openAllTopics,
                        style: TextButton.styleFrom(
                          foregroundColor: c.accentBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          t('common.viewAll'),
                          style: _base.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RecommendedTopics(
                    base: _base,
                    c: c,
                    compact: compact,
                    items: [
                      _TopicItem(
                        title: t('home.topicTravel'),
                        subtitle: t('home.topicTravelHint'),
                        icon: Icons.flight_takeoff_rounded,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            c.accentPurpleDeep.withValues(alpha: 0.75),
                            c.accentPurple.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                      _TopicItem(
                        title: t('home.topicWork'),
                        subtitle: t('home.topicWorkHint'),
                        icon: Icons.work_outline_rounded,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            c.accentBlueDeep.withValues(alpha: 0.75),
                            c.accentBlue.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 12 + MediaQuery.paddingOf(context).bottom,
            child: SafeArea(
              top: false,
              child: _MicFab(c: c, onTap: _goPractice),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak + Scheduler combined card (full-width, single row) ───
class _StreakSchedulerCard extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final int streakDays;
  final List<bool> weeklyActivity;
  final TimeOfDay? practiceTime;
  final VoidCallback onScheduleTap;

  const _StreakSchedulerCard({
    required this.base,
    required this.c,
    required this.streakDays,
    required this.weeklyActivity,
    required this.practiceTime,
    required this.onScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime = practiceTime != null;
    final timeStr = hasTime ? practiceTime!.format(context) : '--:--';
    final weekdayLabels = appLanguage.weekdayNarrowLabels;
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: Streak info + Schedule button ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.warmGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.streakFlame.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays',
                    style: base.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: c.textHeading,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'day streak',
                    style: base.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onScheduleTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasTime
                        ? c.accentBlue.withValues(alpha: 0.10)
                        : c.borderColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasTime
                          ? c.accentBlue.withValues(alpha: 0.35)
                          : c.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alarm_rounded,
                        color: hasTime ? c.accentBlue : c.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: base.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: hasTime ? c.accentBlue : c.textMuted,
                        ),
                      ),
                      if (hasTime) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle_rounded,
                          color: c.accentBlue,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── 7-day activity row (full width) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = i < weeklyActivity.length && weeklyActivity[i];
              final isToday = i == todayIndex;
              final circleSize = isToday ? 34.0 : 26.0;
              final borderColor = isToday
                  ? AppColors.streakFlame
                  : active
                  ? AppColors.streakFlame.withValues(alpha: 0.55)
                  : c.borderColor.withValues(alpha: 0.35);
              final fillColor = active
                  ? AppColors.streakFlame
                  : isToday
                  ? AppColors.streakFlame.withValues(alpha: 0.14)
                  : c.borderColor.withValues(alpha: 0.16);

              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fillColor,
                        border: Border.all(
                          color: borderColor,
                          width: isToday ? 3 : 1,
                        ),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: AppColors.streakFlame.withValues(
                                    alpha: active ? 0.28 : 0.18,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: active
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : isToday
                          ? Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.streakFlame,
                              size: 17,
                            )
                          : null,
                    ),
                    SizedBox(height: isToday ? 5 : 6),
                    Text(
                      weekdayLabels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base.copyWith(
                        fontSize: isToday ? 10 : 9,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                        color: isToday
                            ? AppColors.streakFlame
                            : active
                            ? AppColors.streakFlame.withValues(alpha: 0.78)
                            : c.textMuted.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final bool isLoading;
  final int percent;
  final int minutes;
  final int goalMinutes;
  final String title;
  final String subtitle;
  final String badge;

  const _DailyGoalCard({
    required this.base,
    required this.c,
    required this.isLoading,
    required this.percent,
    required this.minutes,
    required this.goalMinutes,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = c.accentBlue;
    final badgeBg = c.feedbackGood.withValues(alpha: 0.14);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          _GoalRing(
            base: base,
            c: c,
            color: ringColor,
            isLoading: isLoading,
            percent: percent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: base.copyWith(
                    color: c.textHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: base.copyWith(
                    color: c.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: c.feedbackGood),
                      const SizedBox(width: 6),
                      Text(
                        badge,
                        style: base.copyWith(
                          color: c.feedbackGood,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
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
    );
  }
}

class _GoalRing extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final Color color;
  final bool isLoading;
  final int percent;

  const _GoalRing({
    required this.base,
    required this.c,
    required this.color,
    required this.isLoading,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final p = (percent / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: isLoading ? null : p,
            strokeWidth: 7,
            backgroundColor: c.borderColor.withValues(alpha: 0.35),
            color: color,
          ),
          Text(
            isLoading ? '--' : '$percent%',
            style: base.copyWith(
              color: c.textHeading,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconBg,
    required this.iconColor,
  });
}

class _FeatureGrid extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final bool compact;
  final List<_FeatureItem> items;

  const _FeatureGrid({
    required this.base,
    required this.c,
    required this.compact,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureTile(base: base, c: c, item: items[0]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _FeatureTile(base: base, c: c, item: items[1]),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FeatureTile(base: base, c: c, item: items[2]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _FeatureTile(base: base, c: c, item: items[3]),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final _FeatureItem item;

  const _FeatureTile({required this.base, required this.c, required this.item});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: compact ? 124 : 128,
          padding: EdgeInsets.fromLTRB(12, compact ? 10 : 12, 12, 10),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.borderColor.withValues(alpha: 0.75)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 42 : 46,
                height: compact ? 42 : 46,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: compact ? 22 : 24,
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  color: c.textHeading,
                  fontSize: compact ? 12.5 : 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningPath extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final bool compact;
  final VoidCallback onStart;
  final String todayTag;
  final String todayTitle;
  final String todayMeta;
  final String startLabel;
  final String tomorrowTitle;
  final String tomorrowSubtitle;

  const _LearningPath({
    required this.base,
    required this.c,
    required this.compact,
    required this.onStart,
    required this.todayTag,
    required this.todayTitle,
    required this.todayMeta,
    required this.startLabel,
    required this.tomorrowTitle,
    required this.tomorrowSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = c.accentBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 3,
                height: compact ? 210 : 220,
                decoration: BoxDecoration(
                  color: c.borderColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c.borderColor.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent, width: 1.6),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -14,
                      child: Opacity(
                        opacity: 0.14,
                        child: Image.asset(
                          'assets/images/onboarding_welcome_hero.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayTag,
                          style: base.copyWith(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          todayTitle,
                          style: base.copyWith(
                            color: c.textHeading,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: c.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              todayMeta,
                              style: base.copyWith(
                                color: c.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              startLabel,
                              style: base.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: c.surfaceBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: c.borderColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tomorrowTitle,
                      style: base.copyWith(
                        color: c.textHeading.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tomorrowSubtitle,
                      style: base.copyWith(
                        color: c.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _TopicItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class _RecommendedTopics extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final bool compact;
  final List<_TopicItem> items;

  const _RecommendedTopics({
    required this.base,
    required this.c,
    required this.compact,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 150 : 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: compact ? 190 : 210,
              decoration: BoxDecoration(gradient: item.gradient),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.16,
                      child: Image.asset(
                        'assets/images/onboarding_welcome_hero.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -28,
                    top: -28,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 20),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: base.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: base.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MicFab extends StatelessWidget {
  final AppColorsExtension c;
  final VoidCallback onTap;

  const _MicFab({required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = c.accentBlue;
    const size = 62.0;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
