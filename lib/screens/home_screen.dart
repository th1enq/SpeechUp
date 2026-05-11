import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../main.dart' show isFirebaseSupported;

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
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  int _todayMinutes = 0;
  int _streakDays = 0;
  TimeOfDay? _practiceTime;
  List<bool> _weeklyActivity = List.filled(7, false);
  final List<_HomeNotification> _notifications = [
    _HomeNotification(
      title: 'Daily practice reminder',
      body: 'Spend a few minutes speaking today to keep your streak.',
      createdAt: DateTime.now(),
    ),
    _HomeNotification(
      title: 'Try a guided exercise',
      body: 'Start a guided speaking session to warm up your voice.',
      createdAt: DateTime.now(),
    ),
  ];

  static const int _dailyGoalMinutes = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!isFirebaseSupported) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final sessions = await _firestoreService.getTodaySessions(user.uid);
      final totalSeconds = sessions.fold<int>(
        0,
        (acc, s) => acc + s.durationSeconds,
      );
      final minutes = (totalSeconds / 60).round();

      // Load streak from user profile
      int streak = 0;
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        streak = profile?.streakDays ?? 0;
      } catch (_) {}

      // Load saved practice time
      TimeOfDay? savedTime;
      try {
        savedTime = await NotificationService().getSavedPracticeTime();
      } catch (_) {}

      // Build 7-day activity (today + 6 days back)
      List<bool> activity = List.filled(7, false);
      try {
        final recentSessions = await _firestoreService.getRecentSessions(user.uid, limit: 50);
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final day = now.subtract(Duration(days: 6 - i));
          activity[i] = recentSessions.any((s) =>
            s.createdAt.year == day.year &&
            s.createdAt.month == day.month &&
            s.createdAt.day == day.day);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _todayMinutes = minutes;
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _practiceTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _practiceTime = picked);
    await NotificationService().scheduleAtUserTime(picked);
  }

  int get _unreadNotificationCount =>
      _notifications.where((n) => !n.read).length;

  Future<void> _handleNotificationsTap() async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await NotificationService().requestPermissions();
    if (!mounted) return;
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please allow notifications to receive daily reminders.'),
        ),
      );
      // Still allow users to view in-app notifications list.
    }
    if (granted) {
      await NotificationService().scheduleDailyReminder(true);
    }
    if (!mounted) return;

    // Open in-app notifications list and mark all as read.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final c = context.colors;
        final sheetHeight = MediaQuery.of(context).size.height * 0.45;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: _base.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: c.textHeading,
                      ),
                    ),
                    if (_unreadNotificationCount > 0)
                      Text(
                        '$_unreadNotificationCount new',
                        style: _base.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.accentBlue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_notifications.isEmpty)
                  Text(
                    'No notifications yet.',
                    style: _base.copyWith(
                      fontSize: 14,
                      color: c.textMuted,
                    ),
                  )
                else
                  SizedBox(
                    height: sheetHeight,
                    child: ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: n.read
                                ? c.cardBg
                                : c.accentBlue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.borderColor.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                n.read
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_active_rounded,
                                size: 22,
                                color: n.read
                                    ? c.textMuted
                                    : c.accentBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: _base.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: c.textHeading,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      style: _base.copyWith(
                                        fontSize: 13,
                                        color: c.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

    if (!mounted) return;
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });
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
                    leading: Icon(Icons.record_voice_over_rounded, color: c.accentBlue),
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
    widget.onNavigate(2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Topic selected: $selected')),
    );
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
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                bottomContentPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeTopBar(
                    base: _base,
                    c: c,
                    title: t('home.appName'),
                    onProfileTap: _goProfile,
                    onNotificationsTap: _handleNotificationsTap,
                    unreadCount: _unreadNotificationCount,
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
              child: _MicFab(
                c: c,
                onTap: _goPractice,
              ),
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
    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final hasTime = practiceTime != null;
    final timeStr = hasTime ? practiceTime!.format(context) : '--:--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: c.shadowColor, blurRadius: 12, offset: const Offset(0, 4)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              final isToday = i == 6;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppColors.streakFlame
                            : c.borderColor.withValues(alpha: 0.3),
                        border: isToday
                            ? Border.all(color: AppColors.streakFlame, width: 2)
                            : null,
                      ),
                      child: active
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLetters[i],
                      style: base.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.streakFlame : c.textMuted,
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

class _HomeTopBar extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final String title;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;
  final int unreadCount;

  const _HomeTopBar({
    required this.base,
    required this.c,
    required this.title,
    required this.onProfileTap,
    required this.onNotificationsTap,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photo = user?.photoURL;

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.cardBg,
                border: Border.all(color: c.borderColor.withValues(alpha: 0.7)),
              ),
              child: ClipOval(
                child: photo == null
                    ? Icon(Icons.person_rounded, color: c.textMuted)
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person_rounded, color: c.textMuted),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: c.textHeading,
                height: 1.0,
              ),
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationsTap,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 42, minHeight: 42),
              icon: Icon(
                Icons.notifications_none_rounded,
                color: c.textHeading,
                size: 26,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: c.feedbackGood,
                      ),
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
            Expanded(child: _FeatureTile(base: base, c: c, item: items[0])),
            const SizedBox(width: 14),
            Expanded(child: _FeatureTile(base: base, c: c, item: items[1])),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _FeatureTile(base: base, c: c, item: items[2])),
            const SizedBox(width: 14),
            Expanded(child: _FeatureTile(base: base, c: c, item: items[3])),
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

  const _FeatureTile({
    required this.base,
    required this.c,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: compact ? 110 : 118,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.borderColor.withValues(alpha: 0.75)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  color: c.textHeading,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
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
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
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
                            Icon(Icons.schedule_rounded, size: 18, color: c.textMuted),
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
                  border: Border.all(color: c.borderColor.withValues(alpha: 0.7)),
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
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNotification {
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  _HomeNotification({
    required this.title,
    required this.body,
    required this.createdAt,
  }) : read = false;
}