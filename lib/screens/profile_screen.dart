import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/microphone_settings_service.dart';
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
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final MicrophoneSettingsService _micSettingsService =
      MicrophoneSettingsService();
  UserProfile? _profile;
  MicrophoneSettings _micSettings = MicrophoneSettings.defaults;

  static const List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
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
    final micSettings = await _micSettingsService.load();

    if (mounted) {
      setState(() {
        _selectedLanguage = savedLanguage ?? appLanguage.currentLanguageDisplayName;
        _selectedDifficulty = savedDifficulty ?? _selectedDifficulty;
        _notificationsOn = savedNotifications ?? _notificationsOn;
        _micSettings = micSettings;
      });
    }
    appLanguage.setByDisplayName(_selectedLanguage);

    if (!isFirebaseSupported) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          if (profile != null) {
            _selectedLanguage = profile.language;
            _selectedDifficulty = profile.difficulty;
            _notificationsOn = profile.notificationsEnabled;
            _micSettings = _micSettings.copyWith(
              localeId: profile.microphoneLocaleId,
              privateMode: profile.privateMode,
              saveTranscripts: profile.saveTranscripts,
            );
            appLanguage.setByDisplayName(_selectedLanguage);
          }
        });
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
    setState(() => _notificationsOn = nextValue);
    await _updateSettings(notificationsEnabled: nextValue);
  }

  Future<void> _saveMicSettings(MicrophoneSettings settings) async {
    setState(() => _micSettings = settings);
    await _micSettingsService.save(settings);
    if (!isFirebaseSupported) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestoreService.updateUserProfile(user.uid, {
      'microphoneLocaleId': settings.localeId,
      'privateMode': settings.privateMode,
      'saveTranscripts': settings.saveTranscripts,
    });
  }

  void _showMicrophoneSettings() {
    var draft = _micSettings;
    final base = GoogleFonts.plusJakartaSans();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Microphone',
                        style: base.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.profileNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SpeechUp only listens during your practice session.',
                        style: base.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.dashboardTextMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language_rounded),
                        title: const Text('Recognition language'),
                        subtitle: Text(
                          draft.localeId == 'vi_VN'
                              ? 'Tiếng Việt'
                              : 'English (US)',
                        ),
                        trailing: const Icon(Icons.swap_horiz_rounded),
                        onTap: () {
                          setSheetState(() {
                            draft = draft.copyWith(
                              localeId: draft.localeId == 'vi_VN'
                                  ? 'en_US'
                                  : 'vi_VN',
                            );
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: draft.privateMode,
                        title: const Text('Private mode'),
                        subtitle:
                            const Text('Ask before saving session details.'),
                        onChanged: (value) {
                          setSheetState(() {
                            draft = draft.copyWith(privateMode: value);
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: draft.saveTranscripts,
                        title: const Text('Save transcripts'),
                        subtitle:
                            const Text('Turn off to save only summary insights.'),
                        onChanged: (value) {
                          setSheetState(() {
                            draft = draft.copyWith(saveTranscripts: value);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _saveMicSettings(draft);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Save microphone settings'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => _micSettingsService.openSettings(),
                          child: const Text('Open system settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showOptionSheet({
    required String title,
    required List<String> options,
    required String currentValue,
  }) {
    final base = GoogleFonts.plusJakartaSans();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
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
                        color: AppColors.profileNavy,
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
                        color: AppColors.profileNavy,
                      ),
                    ),
                    trailing: option == currentValue
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.onboardingBlue,
                          )
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

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final t = appLanguage.t;

    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.onboardingBlue,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SpeechUp',
                      textAlign: TextAlign.center,
                      style: base.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.profileNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleNotifications,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      _notificationsOn
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: AppColors.onboardingBlue,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    _ProfileAvatarGlow(
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.onboardingBlueSky.withValues(alpha: 0.35),
                              AppColors.onboardingBlue.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _profile?.displayName ?? (isFirebaseSupported ? FirebaseAuth.instance.currentUser?.displayName : null) ?? 'User',
                      style: base.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.profileNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.profileStreakPillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: AppColors.profileStreakPillText,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appLanguage.dayPracticeStreak(_profile?.streakDays ?? 0),
                            style: base.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.profileStreakPillText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      base: base,
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppColors.onboardingBlue,
                      iconCircleBg: const Color(0xFFE8F1FF),
                      value: '${_profile?.totalSessions ?? 0}',
                      valueExtra: null,
                      label: t('profile.totalSessions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      base: base,
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.progressMilestonePurple,
                      iconCircleBg: const Color(0xFFF3E8FF),
                      value: (_profile?.totalSpeakingMinutes ?? 0).toStringAsFixed(1),
                      valueExtra: 'm',
                      label: t('profile.speakingTime'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: AppColors.dashboardHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onboardingBlue.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_profile?.averageScore ?? 0}',
                          style: base.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('profile.averageScore'),
                          style: base.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                t('profile.accountSettings'),
                style: base.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.profileNavy,
                ),
              ),
              const SizedBox(height: 14),
              _SettingsRow(
                base: base,
                icon: Icons.mic_none_rounded,
                iconColor: AppColors.calmMint,
                iconBg: AppColors.calmMintSurface,
                title: 'Microphone',
                subtitle: _micSettings.localeId == 'vi_VN'
                    ? 'Tiếng Việt • Private practice'
                    : 'English (US) • Private practice',
                onTap: _showMicrophoneSettings,
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                base: base,
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.calmText,
                iconBg: AppColors.calmBlueSurface,
                title: 'Privacy',
                subtitle: _micSettings.privateMode
                    ? 'Private mode on • You choose what to save'
                    : 'Private mode off • Progress can be saved',
                onTap: _showMicrophoneSettings,
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                base: base,
                icon: Icons.language_rounded,
                iconColor: AppColors.onboardingBlue,
                iconBg: const Color(0xFFE8F1FF),
                title: t('profile.language'),
                subtitle: _selectedLanguage,
                onTap: _pickLanguage,
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                base: base,
                icon: Icons.psychology_outlined,
                iconColor: AppColors.progressMilestonePurple,
                iconBg: const Color(0xFFF3E8FF),
                title: t('profile.speechDifficulty'),
                subtitle: _selectedDifficulty,
                onTap: _pickDifficulty,
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                base: base,
                icon: Icons.notifications_outlined,
                iconColor: AppColors.progressMilestonePurple,
                iconBg: const Color(0xFFF3E8FF),
                title: t('profile.notifications'),
                subtitle: _notificationsOn
                    ? t('profile.notificationsOn')
                    : t('profile.notificationsOff'),
                onTap: _toggleNotifications,
                trailing: Switch.adaptive(
                  value: _notificationsOn,
                  activeTrackColor: AppColors.onboardingBlue.withValues(alpha: 0.55),
                  activeThumbColor: Colors.white,
                  onChanged: (_) => _toggleNotifications(),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    if (!isFirebaseSupported) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('profile.firebaseOnlyLogout')),
                          ),
                        );
                      }
                      return;
                    }
                    await _authService.signOut();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.profileLogoutMaroon,
                    side: BorderSide(
                      color: AppColors.dashboardTextMuted.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    t('profile.logout'),
                    style: base.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.profileLogoutMaroon,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarGlow extends StatelessWidget {
  final Widget child;

  const _ProfileAvatarGlow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingBlue.withValues(alpha: 0.22),
                blurRadius: 28,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.onboardingBlueSky.withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        child,
        Positioned(
          right: 4,
          bottom: 4,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.profileNavy.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.progressMilestonePurple,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final TextStyle base;
  final IconData icon;
  final Color iconColor;
  final Color iconCircleBg;
  final String value;
  final String? valueExtra;
  final String label;

  const _StatCard({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.iconCircleBg,
    required this.value,
    this.valueExtra,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileNavy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconCircleBg,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          valueExtra == null
              ? Text(
                  value,
                  style: base.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.profileNavy,
                    height: 1,
                  ),
                )
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: base.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.profileNavy,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: valueExtra,
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.profileNavy,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 6),
          Text(
            label,
            style: base.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.dashboardTextMuted,
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

  const _SettingsRow({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
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
                    color: AppColors.profileNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: base.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dashboardTextMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.dashboardTextMuted.withValues(alpha: 0.65),
                size: 24,
              ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileNavy.withValues(alpha: 0.05),
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
