import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/theme_notifier.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  String _selectedLanguage = 'English (US)';
  String _selectedDifficulty = 'Intermediate';
  int _mainTab = 0;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  UserProfile? _profile;

  static const List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> _weekdayShort = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('profile_language');
    final savedDifficulty = prefs.getString('profile_difficulty');
    final savedNotifications = prefs.getBool('profile_notifications_enabled');

    if (mounted) {
      setState(() {
        _selectedLanguage = savedLanguage ?? appLanguage.currentLanguageDisplayName;
        _selectedDifficulty = savedDifficulty ?? _selectedDifficulty;
        _notificationsOn = savedNotifications ?? _notificationsOn;
      });
    }
    appLanguage.setByDisplayName(_selectedLanguage);

    if (!isFirebaseSupported) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _profile = profile;
            if (profile != null) {
              _selectedLanguage = profile.language;
              _selectedDifficulty = profile.difficulty;
              _notificationsOn = profile.notificationsEnabled;
              appLanguage.setByDisplayName(_selectedLanguage);
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  Future<void> _updateSettings({
    String? language,
    String? difficulty,
    bool? notificationsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (language != null) {
      await prefs.setString('profile_language', language);
    }
    if (difficulty != null) {
      await prefs.setString('profile_difficulty', difficulty);
    }
    if (notificationsEnabled != null) {
      await prefs.setBool('profile_notifications_enabled', notificationsEnabled);
    }

    if (isFirebaseSupported) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updates = <String, dynamic>{};
        if (language != null) updates['language'] = language;
        if (difficulty != null) updates['difficulty'] = difficulty;
        if (notificationsEnabled != null) {
          updates['notificationsEnabled'] = notificationsEnabled;
        }
        if (updates.isNotEmpty) {
          await _firestoreService.updateUserProfile(user.uid, updates);
        }
      }
    }
  }

  Future<void> _pickLanguage() async {
    final t = appLanguage.t;
    final selected = await _showOptionSheet(
      title: t('profile.selectLanguage'),
      options: appLanguage.supportedLanguageDisplayNames,
      currentValue: _selectedLanguage,
    );
    if (selected == null || selected == _selectedLanguage) return;

    setState(() => _selectedLanguage = selected);
    appLanguage.setByDisplayName(selected);
    await _updateSettings(language: selected);
  }

  Future<void> _pickDifficulty() async {
    final t = appLanguage.t;
    final selected = await _showOptionSheet(
      title: t('profile.selectDifficulty'),
      options: _difficulties,
      currentValue: _selectedDifficulty,
    );
    if (selected == null || selected == _selectedDifficulty) return;

    setState(() => _selectedDifficulty = selected);
    await _updateSettings(difficulty: selected);
  }

  Future<void> _toggleNotifications() async {
    final nextValue = !_notificationsOn;

    if (nextValue) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permissions are required.')),
          );
        }
        return;
      }
    }

    setState(() => _notificationsOn = nextValue);
    await _updateSettings(notificationsEnabled: nextValue);
    await NotificationService().scheduleDailyReminder(nextValue);
  }

  Future<String?> _showOptionSheet({
    required String title,
    required List<String> options,
    required String currentValue,
  }) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.cardBg,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: base.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.textHeading,
                      ),
                    ),
                  ),
                ),
                ...options.map(
                  (option) => ListTile(
                    onTap: () => Navigator.pop(context, option),
                    title: Text(
                      option,
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textHeading,
                      ),
                    ),
                    trailing: option == currentValue
                        ? Icon(Icons.check_rounded, color: c.accentBlue)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettingsSheet() {
    final base = GoogleFonts.plusJakartaSans();
    final t = appLanguage.t;
    final c = context.colors;
    final themeNotifier = context.read<ThemeNotifier>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: c.surfaceBg,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(ctx).bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('profile.settingsSheetTitle'),
                    style: base.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.textHeading,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsRow(
                    base: base,
                    icon: Icons.dark_mode_rounded,
                    iconColor: c.accentPurple,
                    iconBg: c.streakPillBg,
                    title: t('profile.theme'),
                    subtitle: themeNotifier.isDark
                        ? t('profile.themeOn')
                        : t('profile.themeOff'),
                    onTap: () => themeNotifier.toggle(),
                    c: c,
                    trailing: Switch.adaptive(
                      value: themeNotifier.isDark,
                      activeTrackColor: c.accentBlue.withValues(alpha: 0.55),
                      activeThumbColor: Colors.white,
                      onChanged: (_) => themeNotifier.toggle(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsRow(
                    base: base,
                    icon: Icons.language_rounded,
                    iconColor: c.accentBlue,
                    iconBg: c.speedIconBg,
                    title: t('profile.language'),
                    subtitle: _selectedLanguage,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickLanguage();
                    },
                    c: c,
                  ),
                  const SizedBox(height: 10),
                  _SettingsRow(
                    base: base,
                    icon: Icons.psychology_outlined,
                    iconColor: c.accentPurple,
                    iconBg: c.fluencyIconBg,
                    title: t('profile.speechDifficulty'),
                    subtitle: _selectedDifficulty,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickDifficulty();
                    },
                    c: c,
                  ),
                  const SizedBox(height: 10),
                  _SettingsRow(
                    base: base,
                    icon: Icons.notifications_outlined,
                    iconColor: c.accentPurple,
                    iconBg: c.fluencyIconBg,
                    title: t('profile.notifications'),
                    subtitle: _notificationsOn
                        ? t('profile.notificationsOn')
                        : t('profile.notificationsOff'),
                    onTap: _toggleNotifications,
                    c: c,
                    trailing: Switch.adaptive(
                      value: _notificationsOn,
                      activeTrackColor: c.accentBlue.withValues(alpha: 0.55),
                      activeThumbColor: Colors.white,
                      onChanged: (_) => _toggleNotifications(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (!isFirebaseSupported) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t('profile.firebaseOnlyLogout'))),
                            );
                          }
                          return;
                        }
                        await _authService.signOut();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.logoutColor,
                        side: BorderSide(color: c.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t('profile.logout'),
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayName() {
    return _profile?.displayName ??
        (isFirebaseSupported ? FirebaseAuth.instance.currentUser?.displayName : null) ??
        'User';
  }

  String _languageEmoji() {
    if (_selectedLanguage.toLowerCase().contains('việt') ||
        _selectedLanguage.toLowerCase().contains('viet')) {
      return '🇻🇳';
    }
    return '🇺🇸';
  }

  String _languageShortLabel() {
    if (_selectedLanguage.toLowerCase().contains('việt') ||
        _selectedLanguage.toLowerCase().contains('viet')) {
      return 'Tiếng Việt';
    }
    return 'English';
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final t = appLanguage.t;
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sessions = _profile?.totalSessions ?? 0;
    final streak = _profile?.streakDays ?? 0;
    final avgScore = (_profile?.averageScore ?? 0).clamp(0, 100);
    final progressPct = avgScore;
    final filledStudyDots = math.min(streak, 7);
    final activeDayCount = streak > 0 ? streak : (sessions > 0 ? 1 : 0);

    final email = isFirebaseSupported ? FirebaseAuth.instance.currentUser?.email : null;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.paddingOf(context).bottom + 72,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('profile.screenTitle'),
                      style: base.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: c.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t('profile.friends')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.person_add_outlined, color: c.textHeading, size: 26),
                  ),
                  IconButton(
                    onPressed: _openSettingsSheet,
                    icon: Icon(Icons.settings_outlined, color: c.textHeading, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: c.accentBlue.withValues(alpha: 0.15),
                    child: Icon(Icons.person_rounded, color: c.accentBlue, size: 40),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(),
                          style: base.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: c.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                email ?? t('profile.learnerSubtitle'),
                                style: base.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: c.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyChip(label: _selectedDifficulty, isDark: isDark),
                ],
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        t('profile.friends'),
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textHeading,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '0',
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onboardingBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ProfileSegmentedTabs(
                isDark: isDark,
                selectedIndex: _mainTab,
                labels: [
                  t('profile.tabProgress'),
                  t('profile.tabPractice'),
                  t('profile.tabInsights'),
                ],
                onChanged: (i) => setState(() => _mainTab = i),
              ),
              const SizedBox(height: 20),
              if (_mainTab == 0) ...[
                Row(
                  children: [
                    Text(_languageEmoji(), style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      _languageShortLabel(),
                      style: base.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textHeading,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '—',
                        style: base.copyWith(color: c.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t('profile.languageLine'),
                        style: base.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: _SpeechRingGauge(
                    progress: progressPct / 100.0,
                    centerLabel: '$progressPct%',
                    caption: t('profile.speakingProgressLabel'),
                    base: base,
                    c: c,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatTile(
                        base: base,
                        c: c,
                        icon: Icons.bar_chart_rounded,
                        title: '$sessions',
                        subtitle: t('profile.sessionsPracticed'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompactStatTile(
                        base: base,
                        c: c,
                        icon: Icons.verified_outlined,
                        title: '${avgScore > 0 ? 1 : 0}',
                        subtitle: t('profile.milestones'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  t('profile.studyDays'),
                  style: base.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                  ),
                ),
                const SizedBox(height: 14),
                _StudyDaysRow(
                  labels: _weekdayShort,
                  filledCount: filledStudyDots,
                  isDark: isDark,
                  c: c,
                  base: base,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: c.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      t('profile.activeDays', params: {'n': '$activeDayCount'}),
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  t('profile.highlights'),
                  style: base.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _RatingPill(
                        base: base,
                        c: c,
                        icon: Icons.forum_outlined,
                        text: t('profile.highlightSessions', params: {'n': '$sessions'}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RatingPill(
                        base: base,
                        c: c,
                        icon: Icons.favorite_border_rounded,
                        text: t('profile.highlightStreak', params: {'n': '$streak'}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RatingPill(
                        base: base,
                        c: c,
                        icon: Icons.star_border_rounded,
                        text: t('profile.highlightScore', params: {'n': '$avgScore'}),
                      ),
                    ),
                  ],
                ),
              ] else if (_mainTab == 1) ...[
                Text(
                  t('profile.exercisesTabBody'),
                  style: base.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatTile(
                        base: base,
                        c: c,
                        icon: Icons.fitness_center_rounded,
                        title: '$sessions',
                        subtitle: t('profile.totalSessions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompactStatTile(
                        base: base,
                        c: c,
                        icon: Icons.timer_outlined,
                        title: (_profile?.totalSpeakingMinutes ?? 0).toStringAsFixed(0),
                        subtitle: t('profile.speakingTime'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  t('profile.insightsTabBody'),
                  style: base.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.borderColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insights_outlined, color: AppColors.onboardingBlue, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('profile.averageScore'),
                              style: base.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textMuted,
                              ),
                            ),
                            Text(
                              '${_profile?.averageScore ?? 0}',
                              style: base.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: c.textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _DifficultyChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final bg = isDark
        ? const Color(0xFF1A2744)
        : const Color(0xFFE8F2FF);
    final fg = isDark ? Colors.white : const Color(0xFF1B2F4B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onboardingBlue.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: base.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _ProfileSegmentedTabs extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _ProfileSegmentedTabs({
    required this.isDark,
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final c = context.colors;

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark && selectedIndex == i
                          ? AppColors.onboardingBlue.withValues(alpha: 0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isDark && selectedIndex == i
                          ? null
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: base.copyWith(
                          fontSize: 15,
                          fontWeight:
                              selectedIndex == i ? FontWeight.w800 : FontWeight.w600,
                          color: selectedIndex == i
                              ? AppColors.onboardingBlue
                              : c.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: !isDark && selectedIndex == i
                          ? AppColors.onboardingBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeechRingGauge extends StatelessWidget {
  final double progress;
  final String centerLabel;
  final String caption;
  final TextStyle base;
  final AppColorsExtension c;

  const _SpeechRingGauge({
    required this.progress,
    required this.centerLabel,
    required this.caption,
    required this.base,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final track = isDark(context)
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE8E8ED);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              trackColor: track,
              strokeWidth: 14,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: base.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: c.textHeading,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [
          AppColors.onboardingBlue,
          Color(0xFF5AB0FF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor;
}

class _CompactStatTile extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final IconData icon;
  final String title;
  final String subtitle;

  const _CompactStatTile({
    required this.base,
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c.textHeading),
          const SizedBox(height: 12),
          Text(
            title,
            style: base.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: base.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyDaysRow extends StatelessWidget {
  final List<String> labels;
  final int filledCount;
  final bool isDark;
  final AppColorsExtension c;
  final TextStyle base;

  const _StudyDaysRow({
    required this.labels,
    required this.filledCount,
    required this.isDark,
    required this.c,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < labels.length; i++)
          _DayDot(
            label: labels[i],
            active: i < filledCount,
            isDark: isDark,
            c: c,
            base: base,
          ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final AppColorsExtension c;
  final TextStyle base;

  const _DayDot({
    required this.label,
    required this.active,
    required this.isDark,
    required this.c,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveBg =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.onboardingBlue : inactiveBg,
          ),
          child: active
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: base.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final TextStyle base;
  final AppColorsExtension c;
  final IconData icon;
  final String text;

  const _RatingPill({
    required this.base,
    required this.c,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: c.textHeading),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.textHeading,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final TextStyle base;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final AppColorsExtension c;

  const _SettingsRow({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: base.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: base.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: c.textMuted.withValues(alpha: 0.65),
                size: 24,
              ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: body,
        ),
      ),
    );
  }
}
