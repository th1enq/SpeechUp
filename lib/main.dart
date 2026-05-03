import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'l10n/app_language.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/theme_notifier.dart';
import 'services/notification_service.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';

/// Whether Firebase is available on the current platform.
bool get isFirebaseSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isFirebaseSupported) {
    await Firebase.initializeApp();
  }

  await NotificationService().init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const SpeechUpApp(),
    ),
  );
}

class SpeechUpApp extends StatefulWidget {
  const SpeechUpApp({super.key});

  @override
  State<SpeechUpApp> createState() => _SpeechUpAppState();
}

class _SpeechUpAppState extends State<SpeechUpApp> {
  void _applySystemUiOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      // Same nav bar treatment in both modes avoids layout jumping when toggling theme.
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySystemUiOverlay(isDark);
    });

    return AnimatedBuilder(
      animation: appLanguage,
      builder: (context, _) {
        return MaterialApp(
          title: appLanguage.t('app.title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.mode,
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
    final c = context.colors;

    if (_isCheckingOnboarding) {
      return Scaffold(
        backgroundColor: c.onboardingBg,
        body: Center(
          child: CircularProgressIndicator(color: c.accentBlue),
        ),
      );
    }

    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    if (!isFirebaseSupported) {
      return const MainShell();
    }

    // initialData avoids a transient `waiting` frame that replaced [LoginScreen]
    // when locale/theme rebuilds MaterialApp (was resetting signup state).
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return const MainShell();
        }
        return LoginScreen(
          key: const ValueKey<Object>('auth_login'),
          onLoginSuccess: () {},
        );
      },
    );
  }
}
