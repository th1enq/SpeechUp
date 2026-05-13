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
import '../widgets/screen_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  String _selectedLanguage = 'English (US)';
  String _selectedDifficulty = 'Intermediate';
  String _customDisplayName = '';
  int _avatarIndex = 0;
  String _aiVoiceTone = 'Balanced';
  double _aiVoiceSpeed = 1.0;

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

  static const List<({IconData icon, Color color})> _avatarOptions = [
    (icon: Icons.person_rounded, color: Color(0xFF3B82F6)),
    (icon: Icons.record_voice_over_rounded, color: Color(0xFF8B5CF6)),
    (icon: Icons.mic_rounded, color: Color(0xFF10B981)),
    (icon: Icons.star_rounded, color: Color(0xFFF59E0B)),
    (icon: Icons.favorite_rounded, color: Color(0xFFEF4444)),
    (icon: Icons.sentiment_satisfied_rounded, color: Color(0xFF06B6D4)),
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
    final savedDisplayName = prefs.getString('profile_display_name');
    final savedAvatarIndex = prefs.getInt('profile_avatar_index');
    final savedAiVoiceTone = prefs.getString('profile_ai_voice_tone');
    final savedAiVoiceSpeed = prefs.getDouble('profile_ai_voice_speed');

    if (mounted) {
      setState(() {
        _selectedLanguage =
            savedLanguage ?? appLanguage.currentLanguageDisplayName;
        _selectedDifficulty = savedDifficulty ?? _selectedDifficulty;
        _notificationsOn = savedNotifications ?? _notificationsOn;
        _customDisplayName = savedDisplayName ?? _customDisplayName;
        _avatarIndex =
            ((savedAvatarIndex ?? 0) % _avatarOptions.length +
                _avatarOptions.length) %
            _avatarOptions.length;
        _aiVoiceTone = savedAiVoiceTone ?? _aiVoiceTone;
        _aiVoiceSpeed = savedAiVoiceSpeed ?? _aiVoiceSpeed;
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
              _customDisplayName = profile.displayName.isNotEmpty
                  ? profile.displayName
                  : _customDisplayName;
              appLanguage.setByDisplayName(_selectedLanguage);
            } else {
              _customDisplayName = _displayName();
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
      await prefs.setBool(
        'profile_notifications_enabled',
        notificationsEnabled,
      );
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
            const SnackBar(
              content: Text('Notification permissions are required.'),
            ),
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

  Future<void> _pickAvatar() async {
    final c = context.colors;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.cardBg,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _avatarOptions.length; i++)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(i),
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: _avatarOptions[i].color.withValues(
                        alpha: 0.15,
                      ),
                      child: Icon(
                        _avatarOptions[i].icon,
                        color: _avatarOptions[i].color,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('profile_avatar_index', selected);
    if (mounted) {
      setState(() => _avatarIndex = selected);
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _customDisplayName);
    final c = context.colors;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: c.cardBg,
          title: Text(appLanguage.t('login.fullName')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLanguage.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(appLanguage.t('common.start')),
            ),
          ],
        );
      },
    );
    if (saved != true) return;
    final nextName = controller.text.trim();
    if (nextName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_display_name', nextName);
    if (isFirebaseSupported) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(nextName);
        await _firestoreService.updateUserProfile(user.uid, {
          'displayName': nextName,
        });
      }
    }
    if (mounted) {
      setState(() => _customDisplayName = nextName);
    }
  }

  Future<void> _openAiVoiceSettings() async {
    final c = context.colors;
    String tempTone = _aiVoiceTone;
    double tempSpeed = _aiVoiceSpeed;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: c.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final base = GoogleFonts.plusJakartaSans();
        return StatefulBuilder(
          builder: (context, setLocal) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cài đặt giọng nói AI',
                      style: base.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: c.textHeading,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chọn phong cách giọng',
                      style: base.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tone in const [
                          'Calm',
                          'Balanced',
                          'Energetic',
                        ])
                          ChoiceChip(
                            label: Text(tone),
                            selected: tempTone == tone,
                            onSelected: (_) => setLocal(() => tempTone = tone),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tốc độ phản hồi: ${tempSpeed.toStringAsFixed(1)}x',
                      style: base.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted,
                      ),
                    ),
                    Slider(
                      value: tempSpeed,
                      min: 0.8,
                      max: 1.3,
                      divisions: 5,
                      onChanged: (v) => setLocal(() => tempSpeed = v),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (saved != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_ai_voice_tone', tempTone);
    await prefs.setDouble('profile_ai_voice_speed', tempSpeed);
    if (mounted) {
      setState(() {
        _aiVoiceTone = tempTone;
        _aiVoiceSpeed = tempSpeed;
      });
    }
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
        (isFirebaseSupported
            ? FirebaseAuth.instance.currentUser?.displayName
            : null) ??
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
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomContentPadding =
        kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom + 20;

    final email = isFirebaseSupported
        ? FirebaseAuth.instance.currentUser?.email
        : null;
    final avatar = _avatarOptions[_avatarIndex];

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomContentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: t('profile.screenTitle'),
                subtitle: email ?? t('profile.learnerSubtitle'),
                trailing: IconButton(
                  tooltip: t('profile.settingsSheetTitle'),
                  onPressed: _openSettingsSheet,
                  style: IconButton.styleFrom(
                    backgroundColor: c.cardBg,
                    foregroundColor: c.textHeading,
                    minimumSize: const Size(44, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: c.borderColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.settings_rounded, size: 22),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: c.borderColor.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadowColor.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _pickAvatar,
                      borderRadius: BorderRadius.circular(999),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: avatar.color.withValues(alpha: 0.15),
                        child: Icon(avatar.icon, color: avatar.color, size: 34),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _editDisplayName,
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _customDisplayName.isEmpty
                                        ? _displayName()
                                        : _customDisplayName,
                                    style: base.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: c.textHeading,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: c.textMuted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 16,
                                color: c.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email ?? t('profile.learnerSubtitle'),
                                  style: base.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _DifficultyChip(
                          label: _selectedDifficulty,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: c.borderColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  children: [
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
                      icon: Icons.tune_rounded,
                      iconColor: c.accentBlue,
                      iconBg: c.speedIconBg,
                      title: 'Cài đặt giọng nói AI',
                      subtitle:
                          '$_aiVoiceTone • ${_aiVoiceSpeed.toStringAsFixed(1)}x',
                      onTap: _openAiVoiceSettings,
                      c: c,
                    ),
                    const SizedBox(height: 10),
                    _SettingsRow(
                      base: base,
                      icon: Icons.language_rounded,
                      iconColor: c.accentBlue,
                      iconBg: c.speedIconBg,
                      title: t('profile.language'),
                      subtitle: _selectedLanguage,
                      onTap: _pickLanguage,
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
                      onTap: _pickDifficulty,
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
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
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
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _DifficultyChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final bg = isDark ? const Color(0xFF1A2744) : const Color(0xFFE8F2FF);
    final fg = isDark ? Colors.white : const Color(0xFF1B2F4B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onboardingBlue.withValues(alpha: 0.35),
        ),
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
                          fontWeight: selectedIndex == i
                              ? FontWeight.w800
                              : FontWeight.w600,
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
        colors: const [AppColors.onboardingBlue, Color(0xFF5AB0FF)],
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
      oldDelegate.progress != progress || oldDelegate.trackColor != trackColor;
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
    final inactiveBg = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE8E8ED);

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
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
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
