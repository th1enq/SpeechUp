import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_language.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';

/// Whether Firebase is available on the current platform.
/// Firebase supports Android, iOS, Web, macOS — NOT Linux or Windows.
bool get isFirebaseSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on supported platforms
  if (isFirebaseSupported) {
    await Firebase.initializeApp();
  }

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SpeechUpApp());
}

class SpeechUpApp extends StatelessWidget {
  const SpeechUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguage,
      builder: (context, _) {
        return MaterialApp(
          title: appLanguage.t('app.title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: appLanguage.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppRoot(),
        );
      },
    );
  }
}

// App Root - Handles onboarding → auth → main app
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _hasCompletedOnboarding = false;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _hasCompletedOnboarding = completed;
      _isCheckingOnboarding = false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    setState(() {
      _hasCompletedOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking onboarding status
    if (_isCheckingOnboarding) {
      return const Scaffold(
        backgroundColor: AppColors.onboardingBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.onboardingBlue,
          ),
        ),
      );
    }

    // Step 1: Onboarding
    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onComplete: _completeOnboarding,
      );
    }

    // Step 2: On unsupported platforms (Linux/Windows), skip auth
    if (!isFirebaseSupported) {
      return const MainShell();
    }

    // Step 3: Auth check (only on supported platforms)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.onboardingBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.onboardingBlue,
              ),
            ),
          );
        }

        // Not authenticated → show login
        if (snapshot.data == null) {
          return LoginScreen(
            onLoginSuccess: () {
              // StreamBuilder will auto-rebuild when auth state changes
            },
          );
        }

        // Authenticated → show main app
        return const MainShell();
      },
    );
  }
}
