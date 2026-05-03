import 'package:flutter/material.dart';

// ── Static color tokens (kept for backward compatibility) ──
class AppColors {
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

  // Feedback colors
  static const Color feedbackGood = Color(0xFF059669);
  static const Color feedbackWarning = Color(0xFFF59E0B);
  static const Color feedbackAttention = Color(0xFFF97316);

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

  /// Onboarding
  static const Color onboardingBackground = Color(0xFFF2F6FB);
  static const Color onboardingNavy = Color(0xFF1B2F4B);
  static const Color onboardingBlue = Color(0xFF2B7FFF);
  static const Color onboardingBlueDeep = Color(0xFF1E5FCC);
  static const Color onboardingBlueSky = Color(0xFF5AB0FF);
  static const Color onboardingTextMuted = Color(0xFF6B7A8F);
  static const Color onboardingDotInactive = Color(0xFFC9D4E5);
  static const Color onboardingAccentSoft = Color(0xFFE8B4E8);

  static const Color onboardingWaveOuter = Color(0xFFB3D7FF);
  static const Color onboardingWaveMid = Color(0xFF6BA6FF);

  static const LinearGradient onboardingCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1E4A9A), onboardingBlue],
  );

  /// Home Dashboard
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

  /// Practice exercises
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

  /// Recording screen
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

  static const LinearGradient recordingMicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [onboardingBlueSky, Color(0xFF1556C8)],
  );

  static const Color recordingCloseBtnBg = Color(0xFFDCE8FF);
  static const Color recordingDotRecording = Color(0xFFEF4444);

  /// Progress / My Journey
  static const Color progressAccentBlue = Color(0xFF005A9C);
  static const Color progressNavyText = Color(0xFF1A2B48);
  static const Color progressToggleTrack = Color(0xFFE6F0FF);
  static const Color progressTrendRed = Color(0xFFDC2626);
  static const Color progressBarPale = Color(0xFFC8E0FF);
  static const Color progressSpeedCardGradientStart = Color(0xFFF5F9FF);
  static const Color progressSpeedCardGradientEnd = Color(0xFFE8EFFC);
  static const Color progressMilestonePurple = Color(0xFF7C3AED);

  /// Profile screen
  static const Color profileBackground = Color(0xFFF8F9FE);
  static const Color profileNavy = Color(0xFF1A2B4B);
  static const Color profileLogoutMaroon = Color(0xFF8B1538);
  static const Color profileStreakPillBg = Color(0xFFEDE9FE);
  static const Color profileStreakPillText = Color(0xFF5B21B6);

  // ── Legacy widget compatibility (previously undefined) ──
  static const Color postItYellow = Color(0xFFFFF9C4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF1D2D50);
  static const Color border = Color(0xFFCBD5E1);
  static const Color shadowHard = Color(0x40000000);
  static const Color muted = Color(0xFFF1F5F9);
  static const Color accentSecondary = Color(0xFF6366F1);
}

// ── ThemeExtension: semantic colors that adapt to light/dark ──

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  // Scaffold / page backgrounds
  final Color scaffoldBg;
  final Color surfaceBg;
  final Color cardBg;
  final Color metricRowBg;

  // Text
  final Color textHeading;
  final Color textBody;
  final Color textMuted;
  final Color textOnAccent;

  // Primary / accent
  final Color accentBlue;
  final Color accentBlueDeep;
  final Color accentBlueSky;
  final Color accentPurple;
  final Color accentPurpleDeep;

  // Gradients
  final LinearGradient heroGradient;
  final LinearGradient recordingBgGradient;
  final LinearGradient micGradient;

  // Navigation
  final Color navPill;
  final Color navInactive;

  // Cards / containers
  final Color shadowColor;
  final Color borderColor;
  final Color toggleTrackBg;

  // Feedback
  final Color feedbackGood;
  final Color feedbackWarning;
  final Color feedbackAttention;
  final Color error;

  // Domain-specific
  final Color fluencyIconBg;
  final Color fluencyAccent;
  final Color pronunciationIconBg;
  final Color pronunciationAccent;
  final Color speedIconBg;
  final Color speedAccent;

  final Color streakPillBg;
  final Color streakPillText;
  final Color logoutColor;

  // Practice cards
  final Color practiceCardLavender;
  final Color practiceCardBlush;
  final Color practiceTagEasyBg;
  final Color practiceTagEasyText;
  final Color practiceTagMidBg;
  final Color practiceTagMidText;

  // Progress bars
  final Color progressBarPale;
  final Color progressTrendRed;
  final Color progressSpeedStart;
  final Color progressSpeedEnd;

  // Recording
  final Color recordingCloseBtnBg;

  // Onboarding
  final Color onboardingBg;
  final Color onboardingDotInactive;

  const AppColorsExtension({
    required this.scaffoldBg,
    required this.surfaceBg,
    required this.cardBg,
    required this.metricRowBg,
    required this.textHeading,
    required this.textBody,
    required this.textMuted,
    required this.textOnAccent,
    required this.accentBlue,
    required this.accentBlueDeep,
    required this.accentBlueSky,
    required this.accentPurple,
    required this.accentPurpleDeep,
    required this.heroGradient,
    required this.recordingBgGradient,
    required this.micGradient,
    required this.navPill,
    required this.navInactive,
    required this.shadowColor,
    required this.borderColor,
    required this.toggleTrackBg,
    required this.feedbackGood,
    required this.feedbackWarning,
    required this.feedbackAttention,
    required this.error,
    required this.fluencyIconBg,
    required this.fluencyAccent,
    required this.pronunciationIconBg,
    required this.pronunciationAccent,
    required this.speedIconBg,
    required this.speedAccent,
    required this.streakPillBg,
    required this.streakPillText,
    required this.logoutColor,
    required this.practiceCardLavender,
    required this.practiceCardBlush,
    required this.practiceTagEasyBg,
    required this.practiceTagEasyText,
    required this.practiceTagMidBg,
    required this.practiceTagMidText,
    required this.progressBarPale,
    required this.progressTrendRed,
    required this.progressSpeedStart,
    required this.progressSpeedEnd,
    required this.recordingCloseBtnBg,
    required this.onboardingBg,
    required this.onboardingDotInactive,
  });

  // ── Light palette ──
  static const light = AppColorsExtension(
    scaffoldBg: Color(0xFFF8FAFF),
    surfaceBg: Color(0xFFFFFFFF),
    cardBg: Color(0xFFFFFFFF),
    metricRowBg: Color(0xFFEEF4FF),
    textHeading: Color(0xFF1D2D50),
    textBody: Color(0xFF334155),
    textMuted: Color(0xFF6B7A9E),
    textOnAccent: Color(0xFFFFFFFF),
    accentBlue: Color(0xFF2B7FFF),
    accentBlueDeep: Color(0xFF1E5FCC),
    accentBlueSky: Color(0xFF5AB0FF),
    accentPurple: Color(0xFF7C3AED),
    accentPurpleDeep: Color(0xFF5B21B6),
    heroGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF1E4A9A), Color(0xFF2B7FFF)],
    ),
    recordingBgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FF), Color(0xFFE9EDFA)],
      stops: [0.0, 0.45, 1.0],
    ),
    micGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF5AB0FF), Color(0xFF1556C8)],
    ),
    navPill: Color(0xFFE8EFFF),
    navInactive: Color(0xFF8B96B5),
    shadowColor: Color(0x12000000),
    borderColor: Color(0xFFE2E8F0),
    toggleTrackBg: Color(0xFFE6F0FF),
    feedbackGood: Color(0xFF059669),
    feedbackWarning: Color(0xFFF59E0B),
    feedbackAttention: Color(0xFFF97316),
    error: Color(0xFFEF4444),
    fluencyIconBg: Color(0xFFF0EBFF),
    fluencyAccent: Color(0xFF8B7ADB),
    pronunciationIconBg: Color(0xFFFFE8F3),
    pronunciationAccent: Color(0xFFD97BB0),
    speedIconBg: Color(0xFFE6F0FF),
    speedAccent: Color(0xFF2B7FFF),
    streakPillBg: Color(0xFFEDE9FE),
    streakPillText: Color(0xFF5B21B6),
    logoutColor: Color(0xFF8B1538),
    practiceCardLavender: Color(0xFFE8EAF6),
    practiceCardBlush: Color(0xFFF3E5F5),
    practiceTagEasyBg: Color(0xFFDBEAFE),
    practiceTagEasyText: Color(0xFF1D4ED8),
    practiceTagMidBg: Color(0xFFEDE9FE),
    practiceTagMidText: Color(0xFF6D28D9),
    progressBarPale: Color(0xFFC8E0FF),
    progressTrendRed: Color(0xFFDC2626),
    progressSpeedStart: Color(0xFFF5F9FF),
    progressSpeedEnd: Color(0xFFE8EFFC),
    recordingCloseBtnBg: Color(0xFFDCE8FF),
    onboardingBg: Color(0xFFF2F6FB),
    onboardingDotInactive: Color(0xFFC9D4E5),
  );

  // ── Dark palette ──
  static const dark = AppColorsExtension(
    scaffoldBg: Color(0xFF11111A),
    surfaceBg: Color(0xFF171722),
    cardBg: Color(0xFF1D1D2A),
    metricRowBg: Color(0xFF1A1A26),
    textHeading: Color(0xFFF1EFF7),
    textBody: Color(0xFFD7D3E0),
    textMuted: Color(0xFF9A95A6),
    textOnAccent: Color(0xFFFFFFFF),
    accentBlue: Color(0xFF8CB3FF),
    accentBlueDeep: Color(0xFF5E93F9),
    accentBlueSky: Color(0xFFB8D1FF),
    accentPurple: Color(0xFFD0BCFF),
    accentPurpleDeep: Color(0xFFB69DF8),
    heroGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF3B1D6A), Color(0xFF3450D3)],
    ),
    recordingBgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF11111A), Color(0xFF14141F), Color(0xFF171722)],
      stops: [0.0, 0.45, 1.0],
    ),
    micGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8CB3FF), Color(0xFF3450D3)],
    ),
    navPill: Color(0xFF232334),
    navInactive: Color(0xFF7E7A8A),
    shadowColor: Color(0x66000000),
    borderColor: Color(0xFF2C2B38),
    toggleTrackBg: Color(0xFF232334),
    feedbackGood: Color(0xFF34D399),
    feedbackWarning: Color(0xFFFBBF24),
    feedbackAttention: Color(0xFFFB923C),
    error: Color(0xFFFF6B6B),
    fluencyIconBg: Color(0xFF2A2438),
    fluencyAccent: Color(0xFFD0BCFF),
    pronunciationIconBg: Color(0xFF332238),
    pronunciationAccent: Color(0xFFEA9CCF),
    speedIconBg: Color(0xFF1F2633),
    speedAccent: Color(0xFF8CB3FF),
    streakPillBg: Color(0xFF2A2438),
    streakPillText: Color(0xFFD0BCFF),
    logoutColor: Color(0xFFFF6B6B),
    practiceCardLavender: Color(0xFF24213A),
    practiceCardBlush: Color(0xFF2A1F33),
    practiceTagEasyBg: Color(0xFF1F2633),
    practiceTagEasyText: Color(0xFF8CB3FF),
    practiceTagMidBg: Color(0xFF2A2438),
    practiceTagMidText: Color(0xFFD0BCFF),
    progressBarPale: Color(0xFF232334),
    progressTrendRed: Color(0xFFFF6B6B),
    progressSpeedStart: Color(0xFF14141F),
    progressSpeedEnd: Color(0xFF171722),
    recordingCloseBtnBg: Color(0xFF232334),
    onboardingBg: Color(0xFF0F1729),
    onboardingDotInactive: Color(0xFF3B3A48),
  );

  @override
  AppColorsExtension copyWith({
    Color? scaffoldBg,
    Color? surfaceBg,
    Color? cardBg,
    Color? metricRowBg,
    Color? textHeading,
    Color? textBody,
    Color? textMuted,
    Color? textOnAccent,
    Color? accentBlue,
    Color? accentBlueDeep,
    Color? accentBlueSky,
    Color? accentPurple,
    Color? accentPurpleDeep,
    LinearGradient? heroGradient,
    LinearGradient? recordingBgGradient,
    LinearGradient? micGradient,
    Color? navPill,
    Color? navInactive,
    Color? shadowColor,
    Color? borderColor,
    Color? toggleTrackBg,
    Color? feedbackGood,
    Color? feedbackWarning,
    Color? feedbackAttention,
    Color? error,
    Color? fluencyIconBg,
    Color? fluencyAccent,
    Color? pronunciationIconBg,
    Color? pronunciationAccent,
    Color? speedIconBg,
    Color? speedAccent,
    Color? streakPillBg,
    Color? streakPillText,
    Color? logoutColor,
    Color? practiceCardLavender,
    Color? practiceCardBlush,
    Color? practiceTagEasyBg,
    Color? practiceTagEasyText,
    Color? practiceTagMidBg,
    Color? practiceTagMidText,
    Color? progressBarPale,
    Color? progressTrendRed,
    Color? progressSpeedStart,
    Color? progressSpeedEnd,
    Color? recordingCloseBtnBg,
    Color? onboardingBg,
    Color? onboardingDotInactive,
  }) {
    return AppColorsExtension(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      surfaceBg: surfaceBg ?? this.surfaceBg,
      cardBg: cardBg ?? this.cardBg,
      metricRowBg: metricRowBg ?? this.metricRowBg,
      textHeading: textHeading ?? this.textHeading,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accentBlue: accentBlue ?? this.accentBlue,
      accentBlueDeep: accentBlueDeep ?? this.accentBlueDeep,
      accentBlueSky: accentBlueSky ?? this.accentBlueSky,
      accentPurple: accentPurple ?? this.accentPurple,
      accentPurpleDeep: accentPurpleDeep ?? this.accentPurpleDeep,
      heroGradient: heroGradient ?? this.heroGradient,
      recordingBgGradient: recordingBgGradient ?? this.recordingBgGradient,
      micGradient: micGradient ?? this.micGradient,
      navPill: navPill ?? this.navPill,
      navInactive: navInactive ?? this.navInactive,
      shadowColor: shadowColor ?? this.shadowColor,
      borderColor: borderColor ?? this.borderColor,
      toggleTrackBg: toggleTrackBg ?? this.toggleTrackBg,
      feedbackGood: feedbackGood ?? this.feedbackGood,
      feedbackWarning: feedbackWarning ?? this.feedbackWarning,
      feedbackAttention: feedbackAttention ?? this.feedbackAttention,
      error: error ?? this.error,
      fluencyIconBg: fluencyIconBg ?? this.fluencyIconBg,
      fluencyAccent: fluencyAccent ?? this.fluencyAccent,
      pronunciationIconBg: pronunciationIconBg ?? this.pronunciationIconBg,
      pronunciationAccent: pronunciationAccent ?? this.pronunciationAccent,
      speedIconBg: speedIconBg ?? this.speedIconBg,
      speedAccent: speedAccent ?? this.speedAccent,
      streakPillBg: streakPillBg ?? this.streakPillBg,
      streakPillText: streakPillText ?? this.streakPillText,
      logoutColor: logoutColor ?? this.logoutColor,
      practiceCardLavender: practiceCardLavender ?? this.practiceCardLavender,
      practiceCardBlush: practiceCardBlush ?? this.practiceCardBlush,
      practiceTagEasyBg: practiceTagEasyBg ?? this.practiceTagEasyBg,
      practiceTagEasyText: practiceTagEasyText ?? this.practiceTagEasyText,
      practiceTagMidBg: practiceTagMidBg ?? this.practiceTagMidBg,
      practiceTagMidText: practiceTagMidText ?? this.practiceTagMidText,
      progressBarPale: progressBarPale ?? this.progressBarPale,
      progressTrendRed: progressTrendRed ?? this.progressTrendRed,
      progressSpeedStart: progressSpeedStart ?? this.progressSpeedStart,
      progressSpeedEnd: progressSpeedEnd ?? this.progressSpeedEnd,
      recordingCloseBtnBg: recordingCloseBtnBg ?? this.recordingCloseBtnBg,
      onboardingBg: onboardingBg ?? this.onboardingBg,
      onboardingDotInactive: onboardingDotInactive ?? this.onboardingDotInactive,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      metricRowBg: Color.lerp(metricRowBg, other.metricRowBg, t)!,
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentBlueDeep: Color.lerp(accentBlueDeep, other.accentBlueDeep, t)!,
      accentBlueSky: Color.lerp(accentBlueSky, other.accentBlueSky, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentPurpleDeep: Color.lerp(accentPurpleDeep, other.accentPurpleDeep, t)!,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
      recordingBgGradient: t < 0.5 ? recordingBgGradient : other.recordingBgGradient,
      micGradient: t < 0.5 ? micGradient : other.micGradient,
      navPill: Color.lerp(navPill, other.navPill, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      toggleTrackBg: Color.lerp(toggleTrackBg, other.toggleTrackBg, t)!,
      feedbackGood: Color.lerp(feedbackGood, other.feedbackGood, t)!,
      feedbackWarning: Color.lerp(feedbackWarning, other.feedbackWarning, t)!,
      feedbackAttention: Color.lerp(feedbackAttention, other.feedbackAttention, t)!,
      error: Color.lerp(error, other.error, t)!,
      fluencyIconBg: Color.lerp(fluencyIconBg, other.fluencyIconBg, t)!,
      fluencyAccent: Color.lerp(fluencyAccent, other.fluencyAccent, t)!,
      pronunciationIconBg: Color.lerp(pronunciationIconBg, other.pronunciationIconBg, t)!,
      pronunciationAccent: Color.lerp(pronunciationAccent, other.pronunciationAccent, t)!,
      speedIconBg: Color.lerp(speedIconBg, other.speedIconBg, t)!,
      speedAccent: Color.lerp(speedAccent, other.speedAccent, t)!,
      streakPillBg: Color.lerp(streakPillBg, other.streakPillBg, t)!,
      streakPillText: Color.lerp(streakPillText, other.streakPillText, t)!,
      logoutColor: Color.lerp(logoutColor, other.logoutColor, t)!,
      practiceCardLavender: Color.lerp(practiceCardLavender, other.practiceCardLavender, t)!,
      practiceCardBlush: Color.lerp(practiceCardBlush, other.practiceCardBlush, t)!,
      practiceTagEasyBg: Color.lerp(practiceTagEasyBg, other.practiceTagEasyBg, t)!,
      practiceTagEasyText: Color.lerp(practiceTagEasyText, other.practiceTagEasyText, t)!,
      practiceTagMidBg: Color.lerp(practiceTagMidBg, other.practiceTagMidBg, t)!,
      practiceTagMidText: Color.lerp(practiceTagMidText, other.practiceTagMidText, t)!,
      progressBarPale: Color.lerp(progressBarPale, other.progressBarPale, t)!,
      progressTrendRed: Color.lerp(progressTrendRed, other.progressTrendRed, t)!,
      progressSpeedStart: Color.lerp(progressSpeedStart, other.progressSpeedStart, t)!,
      progressSpeedEnd: Color.lerp(progressSpeedEnd, other.progressSpeedEnd, t)!,
      recordingCloseBtnBg: Color.lerp(recordingCloseBtnBg, other.recordingCloseBtnBg, t)!,
      onboardingBg: Color.lerp(onboardingBg, other.onboardingBg, t)!,
      onboardingDotInactive: Color.lerp(onboardingDotInactive, other.onboardingDotInactive, t)!,
    );
  }
}

// ── Convenience extension on BuildContext ──
extension AppColorsX on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      AppColorsExtension.light;
}
