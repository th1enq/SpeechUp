import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_notifier.dart';

/// Keys stored in [UserProfile.practiceGoals] for onboarding.
const _purposeOptionKeys = [
  'clarity',
  'fluency',
  'confidence',
  'professional',
  'habit',
];

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final _credentialFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Login: 0 = email, 1 = password. Sign-up: 0 = email, 1 = password.
  int _step = 0;
  bool _isLogin = true;
  bool _isLoading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  String? _selectedLanguageDisplay;
  final Set<String> _selectedPurposeKeys = {};

  static final RegExp _emailShapeRegex =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  bool get _firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Color _pageBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF121212) : Colors.white;
  }

  Color _fieldFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String value) => _emailShapeRegex.hasMatch(value.trim());

  /// When [methods] is empty, Firebase may be hiding providers (enumeration protection).
  /// We only block when the API returns a non-empty list we can interpret.
  String? _emailGateMessageAfterLookup(List<String> methods) {
    if (methods.isEmpty) return null;

    if (_isLogin) {
      if (!methods.contains('password')) {
        return appLanguage.t('login.useGoogleInstead');
      }
      return null;
    }

    return appLanguage.t('signup.emailAlreadyRegistered');
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step--;
        _errorMessage = null;
      });
      return;
    }
    Navigator.maybePop(context);
  }

  bool _validateEmailStep() {
    final email = _emailController.text.trim();
    final t = appLanguage.t;
    if (email.isEmpty) {
      setState(() => _errorMessage = t('login.valEmail'));
      return false;
    }
    if (!_looksLikeEmail(email)) {
      setState(() => _errorMessage = t('login.valEmailInvalid'));
      return false;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  Future<void> _onContinueEmail() async {
    FocusScope.of(context).unfocus();
    if (!_validateEmailStep()) return;

    final emailForLookup = _emailController.text.trim().toLowerCase();

    if (_firebaseReady) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final methods =
            await _authService.fetchSignInMethodsForEmail(emailForLookup);
        if (!mounted) return;

        String? blocked = _emailGateMessageAfterLookup(methods);

        // If Firebase hides providers (methods empty), use profile collection
        // as immediate fallback for signup duplicate-email messaging.
        if (blocked == null && !_isLogin && methods.isEmpty) {
          final exists = await _firestoreService.isEmailRegistered(emailForLookup);
          if (!mounted) return;
          if (exists) {
            blocked = appLanguage.t('signup.emailAlreadyRegistered');
          }
        }

        if (blocked != null) {
          setState(() {
            _errorMessage = blocked;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    }

    setState(() => _step = 1);
  }

  bool _isStrongPassword(String s) {
    if (s.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(s)) return false;
    if (!RegExp(r'[0-9]').hasMatch(s)) return false;
    return true;
  }

  void _signUpContinueFromPassword() {
    FocusScope.of(context).unfocus();
    final t = appLanguage.t;
    final p = _passwordController.text;
    if (!_isStrongPassword(p)) {
      setState(() => _errorMessage = t('signup.valPasswordStrong'));
      return;
    }
    setState(() => _errorMessage = null);
    _completeSignUp();
  }

  Future<void> _ensureUserProfile(User user) async {
    final existing = await _firestoreService.getUserProfile(user.uid);
    if (existing != null) return;
    final name = user.displayName?.trim();
    final mail = user.email ?? '';
    await _firestoreService.createUserProfile(
      UserProfile(
        uid: user.uid,
        displayName: (name != null && name.isNotEmpty)
            ? name
            : (mail.isNotEmpty ? mail.split('@').first : 'User'),
        email: mail,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _submitSignIn() async {
    if (!_credentialFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      widget.onLoginSuccess();
    } catch (e) {
      setState(
        () => _errorMessage = 'Tài khoản hoặc mật khẩu không đúng',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignUp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Re-check right before creating account so duplicate-email always surfaces
      // even when users return to this step after a while.
      if (_firebaseReady) {
        final methods = await _authService.fetchSignInMethodsForEmail(
          _emailController.text.trim().toLowerCase(),
        );
        if (!mounted) return;
        if (methods.isNotEmpty) {
          setState(() {
            _step = 0;
            _errorMessage = appLanguage.t('signup.emailAlreadyRegistered');
            _isLoading = false;
          });
          return;
        }
      }

      final credential = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _emailController.text.trim().split('@').first,
      );
      if (credential.user != null) {
        await _firestoreService.createUserProfile(
          UserProfile(
            uid: credential.user!.uid,
            displayName: _emailController.text.trim().split('@').first,
            email: _emailController.text.trim(),
            createdAt: DateTime.now(),
            language: 'English (US)',
            practiceGoals: const [],
          ),
        );
        await _setFirstLoginSetupPending(credential.user!.uid, true);
      }
      widget.onLoginSuccess();
    } catch (e) {
      final raw = e.toString().toLowerCase();
      final duplicate = raw.contains('email-already-in-use') ||
          raw.contains('email này đã được sử dụng') ||
          raw.contains('already in use');
      setState(() {
        if (duplicate) {
          _step = 0;
          _errorMessage = appLanguage.t('signup.emailAlreadyRegistered');
        } else {
          _errorMessage = e.toString();
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firstLoginSetupKey(String uid) => 'first_login_setup_completed_$uid';
  String _firstLoginSetupPendingKey(String uid) =>
      'first_login_setup_pending_$uid';

  Future<bool?> _getFirstLoginSetupCompleted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLoginSetupKey(uid));
  }

  Future<void> _setFirstLoginSetupCompleted(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLoginSetupKey(uid), value);
  }

  Future<bool?> _getFirstLoginSetupPending(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLoginSetupPendingKey(uid));
  }

  Future<void> _setFirstLoginSetupPending(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLoginSetupPendingKey(uid), value);
  }

  Future<void> _runFirstLoginSetupIfNeeded(User user, {bool force = false}) async {
    final savedFlag = await _getFirstLoginSetupCompleted(user.uid);
    final pendingFlag = await _getFirstLoginSetupPending(user.uid);

    if (!force) {
      if (pendingFlag == false && savedFlag == true) return;
      if (pendingFlag == true) {
        if (!mounted) return;
        await _openFirstLoginSetupSheet(user);
        return;
      }

      if (savedFlag == true) return;
      if (savedFlag == null) {
        final profile = await _firestoreService.getUserProfile(user.uid);
        final hasName = (profile?.displayName.trim().isNotEmpty ?? false);
        final hasGoals = (profile?.practiceGoals.isNotEmpty ?? false);
        if (hasName && hasGoals) {
          await _setFirstLoginSetupCompleted(user.uid, true);
          return;
        }
      }
    }

    if (!mounted) return;
    await _openFirstLoginSetupSheet(user);
  }

  Future<void> _openFirstLoginSetupSheet(User user) async {
    final t = appLanguage.t;
    final profile = await _firestoreService.getUserProfile(user.uid);

    final displayNameController = TextEditingController(
      text: (profile?.displayName ?? user.displayName ?? user.email?.split('@').first ?? '')
          .trim(),
    );
    var language = profile?.language ?? _selectedLanguageDisplay ?? 'English (US)';
    final selectedGoals = Set<String>.from(profile?.practiceGoals ?? const <String>[]);
    String? localError;
    var saving = false;

    try {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) {
          final c = sheetContext.colors;
          final base = GoogleFonts.plusJakartaSans();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t('signup.usernameTitle'),
                        style: base.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.textHeading,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: displayNameController,
                        decoration: _filledDecoration(
                          sheetContext,
                          hint: t('signup.usernameHint'),
                          fill: _fieldFill(sheetContext),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LanguagePickCard(
                        title: t('signup.langEnglish'),
                        subtitle: 'English (US)',
                        emoji: '🇺🇸',
                        selected: language == 'English (US)',
                        isDark: Theme.of(sheetContext).brightness == Brightness.dark,
                        onTap: () => setModalState(() => language = 'English (US)'),
                      ),
                      const SizedBox(height: 10),
                      _LanguagePickCard(
                        title: t('signup.langVietnamese'),
                        subtitle: 'Tiếng Việt',
                        emoji: '🇻🇳',
                        selected: language == 'Tiếng Việt',
                        isDark: Theme.of(sheetContext).brightness == Brightness.dark,
                        onTap: () => setModalState(() => language = 'Tiếng Việt'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('signup.purposeMultiHint'),
                        style: base.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final key in _purposeOptionKeys) ...[
                        _PurposePickCard(
                          title: t('signup.purpose.$key'),
                          icon: _purposeIcon(key),
                          selected: selectedGoals.contains(key),
                          isDark: Theme.of(sheetContext).brightness == Brightness.dark,
                          onTap: () {
                            setModalState(() {
                              if (selectedGoals.contains(key)) {
                                selectedGoals.remove(key);
                              } else {
                                selectedGoals.add(key);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (localError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            localError!,
                            style: base.copyWith(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final name = displayNameController.text.trim();
                                if (name.isEmpty) {
                                  setModalState(
                                    () => localError = t('signup.valUsername'),
                                  );
                                  return;
                                }
                                if (selectedGoals.isEmpty) {
                                  setModalState(
                                    () => localError = t('signup.valPickPurposes'),
                                  );
                                  return;
                                }
                                setModalState(() {
                                  localError = null;
                                  saving = true;
                                });
                                try {
                                  await user.updateDisplayName(name);
                                  final goals = selectedGoals.toList()..sort();
                                  await _firestoreService.updateUserProfile(
                                    user.uid,
                                    {
                                      'displayName': name,
                                      'language': language,
                                      'practiceGoals': goals,
                                    },
                                  );
                                  appLanguage.setByDisplayName(language);
                                  await _setFirstLoginSetupCompleted(user.uid, true);
                                  await _setFirstLoginSetupPending(user.uid, false);
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                } catch (e) {
                                  setModalState(() => localError = e.toString());
                                } finally {
                                  if (sheetContext.mounted) {
                                    setModalState(() => saving = false);
                                  }
                                }
                              },
                        child: Text(
                          saving ? 'Loading...' : t('login.continue'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    } finally {
      displayNameController.dispose();
    }
  }

  void _onPrimaryButton() {
    if (_isLogin) {
      if (_step == 0) {
        unawaited(_onContinueEmail());
      } else {
        _submitSignIn();
      }
      return;
    }
    switch (_step) {
      case 0:
        unawaited(_onContinueEmail());
        break;
      case 1:
        _signUpContinueFromPassword();
        break;
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user != null) {
        await _ensureUserProfile(credential!.user!);
        widget.onLoginSuccess();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showPhoneSoonSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLanguage.t('login.phoneSoon'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _titleForStep() {
    final t = appLanguage.t;
    if (_isLogin) {
      return _step == 0 ? t('login.signInHeadline') : t('login.signInHeadline');
    }
    switch (_step) {
      case 0:
        return t('login.signUpHeadline');
      case 1:
        return t('signup.createPasswordTitle');
      default:
        return '';
    }
  }

  String _primaryLabel() {
    final t = appLanguage.t;
    if (_isLogin) {
      return _step == 0 ? t('login.continue') : t('login.signIn');
    }
    return _step == 1 ? t('login.createAccount') : t('login.continue');
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 370;

    return Scaffold(
      backgroundColor: _pageBg(context),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: c.textHeading,
                            ),
                          ),
                          const Spacer(),
                          const _LoginThemeToggle(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(compact ? 18 : 24, 0, compact ? 18 : 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_step == 0) ...[
                            Center(child: _LogoHelloRow(textColor: c.textHeading)),
                            SizedBox(height: compact ? 20 : 28),
                          ],
                          Text(
                            _titleForStep(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: compact ? 23 : 26,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.35,
                              color: c.textHeading,
                            ),
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          ..._buildStepContent(context, base, c),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 28),
                    Padding(
                      padding: EdgeInsets.fromLTRB(compact ? 18 : 24, 0, compact ? 18 : 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 56),
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: _errorMessage == null
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                    decoration: BoxDecoration(
                      color: _errorMessage == null
                          ? Colors.transparent
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage == null
                            ? Colors.transparent
                            : AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: _errorMessage == null
                        ? null
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  maxLines: 3,
                                  overflow: TextOverflow.fade,
                                  style: base.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  _PrimaryBlueButton(
                    label: _primaryLabel(),
                    loading: _isLoading,
                    onPressed: _onPrimaryButton,
                  ),
                  if (_step == 0) ...[
                    const SizedBox(height: 28),
                    _OrDivider(label: t('login.or'), mutedColor: c.textMuted),
                    const SizedBox(height: 22),
                    _GoogleSignInButton(
                      label: t('login.google'),
                      loading: _googleLoading,
                      isDark: isDark,
                      onPressed: _signInWithGoogle,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 28),
                      _LoginTermsRichText(textMuted: c.textMuted),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 24),
                    _AuthModeFooter(
                      isLogin: _isLogin,
                      onToggle: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _step = 0;
                          _errorMessage = null;
                          _passwordController.clear();
                          _selectedLanguageDisplay = null;
                          _selectedPurposeKeys.clear();
                          _credentialFormKey.currentState?.reset();
                        });
                      },
                    ),
                  ] else if (_isLogin && _step == 1) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => _showForgotPassword(context),
                        style: TextButton.styleFrom(
                          foregroundColor: c.textMuted,
                        ),
                        child: Text(
                          t('login.forgotPassword'),
                          style: base.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildEmailFieldSection(
    BuildContext context,
    TextStyle base,
    AppColorsExtension c,
  ) {
    final t = appLanguage.t;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              t('login.emailLabel'),
              style: base.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: _showPhoneSoonSnack,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.onboardingBlue,
            ),
            child: Text(
              t('login.signInWithPhone'),
              style: base.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onboardingBlue,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        style: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: c.textHeading,
        ),
        decoration: _filledDecoration(
          context,
          hint: t('login.emailHint'),
          fill: _fieldFill(context),
        ),
        onSubmitted: (_) => unawaited(_onContinueEmail()),
      ),
    ];
  }

  List<Widget> _buildStepContent(
    BuildContext context,
    TextStyle base,
    AppColorsExtension c,
  ) {
    final t = appLanguage.t;

    if (_isLogin) {
      if (_step == 0) {
        return _buildEmailFieldSection(context, base, c);
      }
      return [
        Form(
          key: _credentialFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('login.password'),
                style: base.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: base.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textHeading,
                ),
                decoration: _filledDecoration(
                  context,
                  hint: t('signup.passwordHint'),
                  fill: _fieldFill(context),
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: c.textMuted,
                      size: 22,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('login.valPassword');
                  }
                  if (value.length < 6) {
                    return t('login.valPasswordShort');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ];
    }

    switch (_step) {
      case 0:
        return _buildEmailFieldSection(context, base, c);
      case 1:
        return [
          Text.rich(
            TextSpan(
              style: base.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.textMuted,
                height: 1.45,
              ),
              children: [
                TextSpan(text: t('signup.passwordHelperBefore')),
                TextSpan(
                  text: t('signup.passwordHelperBold'),
                  style: base.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textHeading,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('login.password'),
            style: base.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: base.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textHeading,
            ),
            decoration: _filledDecoration(
              context,
              hint: t('signup.passwordHint'),
              fill: _fieldFill(context),
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: c.textMuted,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  IconData _purposeIcon(String key) {
    switch (key) {
      case 'clarity':
        return Icons.record_voice_over_outlined;
      case 'fluency':
        return Icons.speed_outlined;
      case 'confidence':
        return Icons.mic_none_rounded;
      case 'professional':
        return Icons.work_outline_rounded;
      case 'habit':
        return Icons.event_repeat_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  InputDecoration _filledDecoration(
    BuildContext context, {
    required String hint,
    required Color fill,
  }) {
    final base = GoogleFonts.plusJakartaSans();
    final c = context.colors;
    final radius = BorderRadius.circular(14);

    return InputDecoration(
      hintText: hint,
      hintStyle: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: c.textMuted.withValues(alpha: 0.75),
      ),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.onboardingBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.45)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final resetEmailController = TextEditingController(text: _emailController.text);
    final c = context.colors;
    final sheetDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: sheetDark ? c.surfaceBg : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onboardingDotInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                appLanguage.t('login.resetTitle'),
                style: base.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLanguage.t('login.resetHint'),
                textAlign: TextAlign.center,
                style: base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: base.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textHeading,
                ),
                decoration: _filledDecoration(
                  ctx,
                  hint: appLanguage.t('login.emailHint'),
                  fill: _fieldFill(ctx),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    final email = resetEmailController.text.trim();
                    if (email.isEmpty) return;
                    try {
                      await _authService.resetPassword(email);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appLanguage.t('login.resetSent'),
                              style: base.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.feedbackGood,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.onboardingBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    appLanguage.t('login.resetSubmit'),
                    style: base.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
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

class _LanguagePickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguagePickCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final border = Border.all(
      color: selected ? AppColors.onboardingBlue : Colors.transparent,
      width: selected ? 1.5 : 0,
    );
    final bg = selected
        ? (isDark ? const Color(0xFF1A2744) : const Color(0xFFE8F2FF))
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: base.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: base.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurposePickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PurposePickCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final border = Border.all(
      color: selected ? AppColors.onboardingBlue : Colors.transparent,
      width: selected ? 1.5 : 0,
    );
    final bg = selected
        ? (isDark ? const Color(0xFF1A2744) : const Color(0xFFE8F2FF))
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 26, color: context.colors.textHeading),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: base.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textHeading,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 24,
                color: selected
                    ? AppColors.onboardingBlue
                    : context.colors.textMuted.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginThemeToggle extends StatelessWidget {
  const _LoginThemeToggle();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final isDark = notifier.isDark;
    final c = context.colors;

    return IconButton(
      onPressed: () => notifier.toggle(),
      icon: isDark
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 22,
                color: Colors.amber.shade300,
              ),
            )
          : SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.dark_mode_outlined,
                color: c.textMuted,
                size: 22,
              ),
            ),
    );
  }
}

class _LogoHelloRow extends StatelessWidget {
  final Color textColor;

  const _LogoHelloRow({required this.textColor});

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    return Center(
      child: Text(
        t('login.hello'),
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _PrimaryBlueButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryBlueButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.onboardingBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.onboardingDotInactive,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: base.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  final Color mutedColor;

  const _OrDivider({required this.label, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: mutedColor,
    );

    return Row(
      children: [
        Expanded(child: Divider(color: mutedColor.withValues(alpha: 0.35))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label, style: base),
        ),
        Expanded(child: Divider(color: mutedColor.withValues(alpha: 0.35))),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool isDark;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.label,
    required this.loading,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    final bg = isDark ? const Color(0xFF2C2C3A) : const Color(0xFFE8F1FC);
    final fg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1C1E);

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'G',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoginTermsRichText extends StatefulWidget {
  final Color textMuted;

  const _LoginTermsRichText({required this.textMuted});

  @override
  State<_LoginTermsRichText> createState() => _LoginTermsRichTextState();
}

class _LoginTermsRichTextState extends State<_LoginTermsRichText> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = () {};
    _privacyTap = TapGestureRecognizer()..onTap = () {};
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: widget.textMuted,
      height: 1.45,
    );
    final link = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.onboardingBlue,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.onboardingBlue,
      height: 1.45,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: t('login.termsJoin')),
          TextSpan(text: t('login.termsLink'), style: link, recognizer: _termsTap),
          TextSpan(text: t('login.termsAnd')),
          TextSpan(
            text: t('login.privacyLink'),
            style: link,
            recognizer: _privacyTap,
          ),
          TextSpan(text: t('login.termsEnd')),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _AuthModeFooter extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const _AuthModeFooter({
    required this.isLogin,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final base = GoogleFonts.plusJakartaSans();
    final muted = context.colors.textMuted;

    final lead = isLogin ? t('login.noAccount') : t('login.haveAccount');
    final action = isLogin ? t('login.signUp') : t('login.logIn');

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          lead,
          style: base.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: muted,
          ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            action,
            style: base.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onboardingBlue,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.onboardingBlue,
            ),
          ),
        ),
      ],
    );
  }
}
