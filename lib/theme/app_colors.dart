import 'package:flutter/material.dart';

class AppColors {
  // SpeechUp Calm refresh
  static const Color calmMint = Color(0xFF7FD8C3);
  static const Color calmBlue = Color(0xFFA9D6F5);
  static const Color calmBackground = Color(0xFFF8F7F3);
  static const Color calmText = Color(0xFF2F3640);
  static const Color calmTextSecondary = Color(0xFF6B7280);
  static const Color calmAmber = Color(0xFFF4B96A);
  static const Color calmCoral = Color(0xFFF28B82);
  static const Color calmMintSurface = Color(0xFFEAF8F4);
  static const Color calmBlueSurface = Color(0xFFEEF7FE);

  // Primary palette - Calm Cyan + Health Green
  static const Color primary = Color(0xFF0891B2);
  static const Color primaryLight = Color(0xFF22D3EE);
  static const Color primaryDark = Color(0xFF0E7490);

  // CTA / Success
  static const Color cta = Color(0xFF059669);
  static const Color ctaLight = Color(0xFF34D399);

  // Backgrounds
  static const Color background = Color(0xFFECFEFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0FDFA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF164E63);
  static const Color textSecondary = Color(0xFF0E7490);
  static const Color textMuted = Color(0xFF67A3B3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Feedback colors (NO scores — just colors!)
  static const Color feedbackGood = Color(0xFF059669);      // Trôi chảy
  static const Color feedbackWarning = Color(0xFFF59E0B);    // Khá tốt
  static const Color feedbackAttention = Color(0xFFF97316);  // Cần cải thiện

  // Accent
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFC4B5FD);

  // Badge / Gamification
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color streakFlame = Color(0xFFFF6B35);

  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Claymorphism shadow colors
  static const Color shadowLight = Color(0x15000000);
  static const Color shadowDark = Color(0x25000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cta, ctaLight],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
  );

  /// Onboarding (Figma) — navy + blue, cool off-white background
  static const Color onboardingBackground = Color(0xFFF2F6FB);
  static const Color onboardingNavy = Color(0xFF1B2F4B);
  static const Color onboardingBlue = Color(0xFF2B7FFF);
  static const Color onboardingBlueDeep = Color(0xFF1E5FCC);
  static const Color onboardingBlueSky = Color(0xFF5AB0FF);
  static const Color onboardingTextMuted = Color(0xFF6B7A8F);
  static const Color onboardingDotInactive = Color(0xFFC9D4E5);
  static const Color onboardingAccentSoft = Color(0xFFE8B4E8);

  /// Waveform bars (screen 1): symmetric pale / mid blues toward `onboardingBlue` at center
  static const Color onboardingWaveOuter = Color(0xFFB3D7FF);
  static const Color onboardingWaveMid = Color(0xFF6BA6FF);

  static const LinearGradient onboardingCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1E4A9A), onboardingBlue],
  );

  /// Home Dashboard (Figma Home Dashboard.png)
  static const Color dashboardBackground = Color(0xFFF8FAFF);
  static const Color dashboardNavy = Color(0xFF1D2D50);
  static const Color dashboardTextMuted = Color(0xFF6B7A9E);
  static const Color dashboardNavInactive = Color(0xFF8B96B5);
  static const Color dashboardNavPill = Color(0xFFE8EFFF);
  static const Color dashboardMetricRowBg = Color(0xFFEEF4FF);
  static const Color dashboardFluencyIconBg = Color(0xFFF0EBFF);
  static const Color dashboardFluencyAccent = Color(0xFF8B7ADB);
  static const Color dashboardPronunciationIconBg = Color(0xFFFFE8F3);
  static const Color dashboardPronunciationAccent = Color(0xFFD97BB0);
  static const Color dashboardSpeedIconBg = Color(0xFFE6F0FF);
  static const Color dashboardSpeedAccent = Color(0xFF2B7FFF);

  static const LinearGradient dashboardHeroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1E4A9A), onboardingBlue],
  );

  /// Practice exercises (Figma Practice Exercises.png)
  static const Color practiceCardLavender = Color(0xFFE8EAF6);
  static const Color practiceCardBlush = Color(0xFFF3E5F5);
  static const Color practicePurple = Color(0xFF7C3AED);
  static const Color practicePurpleDeep = Color(0xFF5B21B6);
  static const Color practiceTagEasyBg = Color(0xFFDBEAFE);
  static const Color practiceTagEasyText = Color(0xFF1D4ED8);
  static const Color practiceTagMidBg = Color(0xFFEDE9FE);
  static const Color practiceTagMidText = Color(0xFF6D28D9);
  static const Color practiceTagHardBg = Color(0xFFEDE9FE);
  static const Color practiceTagHardText = Color(0xFF5B21B6);
  static const Color practiceStreakBlue = Color(0xFF1E4A9A);

  /// Recording screen (Figma Recording Screen.png)
  static const LinearGradient recordingBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF5F7FF),
      Color(0xFFE9EDFA),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  /// Mic: lighter top → deeper bottom
  static const LinearGradient recordingMicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [onboardingBlueSky, Color(0xFF1556C8)],
  );

  static const Color recordingCloseBtnBg = Color(0xFFDCE8FF);
  static const Color recordingDotRecording = calmCoral;

  /// Progress / My Journey (Figma Progress Tracking.png)
  static const Color progressAccentBlue = Color(0xFF005A9C);
  static const Color progressNavyText = Color(0xFF1A2B48);
  static const Color progressToggleTrack = Color(0xFFE6F0FF);
  static const Color progressTrendRed = Color(0xFFDC2626);
  static const Color progressBarPale = Color(0xFFC8E0FF);
  static const Color progressSpeedCardGradientStart = Color(0xFFF5F9FF);
  static const Color progressSpeedCardGradientEnd = Color(0xFFE8EFFC);
  static const Color progressMilestonePurple = Color(0xFF7C3AED);

  /// Profile screen (Figma Profile Screen.png)
  static const Color profileBackground = Color(0xFFF8F9FE);
  static const Color profileNavy = Color(0xFF1A2B4B);
  static const Color profileLogoutMaroon = Color(0xFF8B1538);
  static const Color profileStreakPillBg = Color(0xFFEDE9FE);
  static const Color profileStreakPillText = Color(0xFF5B21B6);
}
