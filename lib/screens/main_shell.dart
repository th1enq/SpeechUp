import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'practice_screen.dart';
import 'conversation_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  bool _didCheckFirstLoginSetup = false;
  String? _pendingChatTopic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFirstLoginSetup();
    });
  }

  String _firstLoginSetupKey(String uid) => 'first_login_setup_completed_$uid';
  String _firstLoginSetupPendingKey(String uid) =>
      'first_login_setup_pending_$uid';

  Future<void> _maybeShowFirstLoginSetup() async {
    if (_didCheckFirstLoginSetup || !mounted || !isFirebaseSupported) return;
    _didCheckFirstLoginSetup = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pending =
        prefs.getBool(_firstLoginSetupPendingKey(user.uid)) ?? false;
    final completed = prefs.getBool(_firstLoginSetupKey(user.uid)) ?? false;
    if (!pending || completed) return;

    final t = appLanguage.t;
    final profile = await _firestoreService.getUserProfile(user.uid);
    final displayNameController = TextEditingController(
      text:
          (profile?.displayName ??
                  user.displayName ??
                  user.email?.split('@').first ??
                  '')
              .trim(),
    );
    var language = profile?.language ?? 'English (US)';
    final selectedGoals = Set<String>.from(
      profile?.practiceGoals ?? const <String>[],
    );
    String? error;
    var saving = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetContext) {
        final c = sheetContext.colors;
        final base = GoogleFonts.plusJakartaSans();
        Widget goalChip(String key) {
          return FilterChip(
            label: Text(t('signup.purpose.$key')),
            selected: selectedGoals.contains(key),
            onSelected: (value) {
              (sheetContext as Element).markNeedsBuild();
              if (value) {
                selectedGoals.add(key);
              } else {
                selectedGoals.remove(key);
              }
            },
          );
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t('signup.usernameTitle'),
                      style: base.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.textHeading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: displayNameController,
                      decoration: InputDecoration(
                        hintText: t('signup.usernameHint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: language,
                      decoration: InputDecoration(
                        labelText: t('signup.languageTitle'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'English (US)',
                          child: Text('English (US)'),
                        ),
                        DropdownMenuItem(
                          value: 'Tiếng Việt',
                          child: Text('Tiếng Việt'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => language = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('signup.purposeMultiHint'),
                      style: base.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        goalChip('clarity'),
                        goalChip('fluency'),
                        goalChip('confidence'),
                        goalChip('professional'),
                        goalChip('habit'),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: base.copyWith(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = displayNameController.text.trim();
                              if (name.isEmpty) {
                                setModalState(
                                  () => error = t('signup.valUsername'),
                                );
                                return;
                              }
                              if (selectedGoals.isEmpty) {
                                setModalState(
                                  () => error = t('signup.valPickPurposes'),
                                );
                                return;
                              }
                              setModalState(() {
                                error = null;
                                saving = true;
                              });
                              try {
                                await user.updateDisplayName(name);
                                final goals = selectedGoals.toList()..sort();
                                await _firestoreService
                                    .updateUserProfile(user.uid, {
                                      'displayName': name,
                                      'language': language,
                                      'practiceGoals': goals,
                                    });
                                appLanguage.setByDisplayName(language);
                                await prefs.setBool(
                                  _firstLoginSetupKey(user.uid),
                                  true,
                                );
                                await prefs.setBool(
                                  _firstLoginSetupPendingKey(user.uid),
                                  false,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              } catch (e) {
                                setModalState(() => error = e.toString());
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => saving = false);
                                }
                              }
                            },
                      child: Text(saving ? 'Loading...' : t('login.continue')),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    displayNameController.dispose();
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  void _openChatTopic(String topic) {
    setState(() {
      _pendingChatTopic = topic;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigate: _navigateTo,
            onOpenChatTopic: _openChatTopic,
            userName: isFirebaseSupported
                ? (FirebaseAuth.instance.currentUser?.displayName ?? 'User')
                : 'User',
          ),
          const PracticeScreen(),
          ConversationScreen(
            initialCustomPrompt: _pendingChatTopic,
            onNavigateProfile: () => _navigateTo(4),
            onInitialPromptConsumed: () {
              if (!mounted) return;
              setState(() => _pendingChatTopic = null);
            },
          ),
          const SocialScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surfaceBg,
          boxShadow: [
            BoxShadow(
              color: c.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: c.navPill,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.accentBlue : c.navInactive,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 24,
                  color: selected ? c.accentBlue : c.navInactive,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _navigateTo,
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 72,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_rounded),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: t('nav.home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.fitness_center_rounded),
                  selectedIcon: const Icon(Icons.fitness_center_rounded),
                  label: t('nav.practice'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_rounded),
                  selectedIcon: const Icon(Icons.chat_bubble_rounded),
                  label: t('nav.chat'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.groups_2_rounded),
                  selectedIcon: const Icon(Icons.groups_2_rounded),
                  label: t('nav.social'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: t('nav.profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
