import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/theme_notifier.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 2;

  late final PageController _pageController;
  late final TapGestureRecognizer _logInRecognizer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _logInRecognizer = TapGestureRecognizer()..onTap = _skipOnboarding;
  }

  @override
  void dispose() {
    _logInRecognizer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onComplete();
    }
  }

  void _skipOnboarding() => _onComplete();

  void _onComplete() => widget.onComplete();

  Color _welcomeBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF121212) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();

    return Scaffold(
      backgroundColor: _welcomeBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: [
                  const _SpeechUpLogo(),
                  const Spacer(),
                  const _OnboardingThemeToggle(),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        const _WelcomeHero(),
                        const SizedBox(height: 28),
                        Text(
                          t('onboarding.welcomeHeadline'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.3,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  _OnboardingSecondPage(
                    title: t('onboarding.trackProgress'),
                    subtitle: t('onboarding.subtitle2'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                children: [
                  if (_currentPage == 0) ...[
                    _SolidPrimaryCta(
                      label: t('onboarding.startLearning'),
                      showArrow: false,
                      onPressed: _nextPage,
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        style: base.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textMuted,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: '${t('onboarding.alreadyHaveAccount')} '),
                          TextSpan(
                            text: t('onboarding.logIn'),
                            style: base.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onboardingBlue,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.onboardingBlue,
                            ),
                            recognizer: _logInRecognizer,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final active = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 8,
                        width: active ? 28 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.onboardingBlue
                              : c.onboardingDotInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  if (_currentPage == 1) ...[
                    const SizedBox(height: 22),
                    _SolidPrimaryCta(
                      label: t('onboarding.getStarted'),
                      showArrow: false,
                      onPressed: _nextPage,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingThemeToggle extends StatelessWidget {
  const _OnboardingThemeToggle();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final isDark = notifier.isDark;
    final c = context.colors;

    return IconButton(
      onPressed: () => notifier.toggle(),
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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
          : Icon(
              Icons.dark_mode_outlined,
              color: c.textMuted,
              size: 26,
            ),
    );
  }
}

class _SpeechUpLogo extends StatelessWidget {
  const _SpeechUpLogo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.onboardingBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 6,
                top: 11,
                child: Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white.withValues(alpha: 0.82),
                  size: 17,
                ),
              ),
              Positioned(
                right: 6,
                bottom: 9,
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'SpeechUp',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: c.textHeading,
          ),
        ),
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blobLight = const Color(0xFFE3EFFF);
    final blobDark = const Color(0xFF152238);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final h = math.min(maxW * 0.92, 276.0);
        return SizedBox(
          height: h,
          width: maxW,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(maxW, h),
                painter: _OrganicBlobPainter(
                  color: isDark ? blobDark : blobLight,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(
                  'assets/images/onboarding_welcome_hero.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _HeroFallback(isDark: isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrganicBlobPainter extends CustomPainter {
  final Color color;

  _OrganicBlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.12, h * 0.58);
    path.quadraticBezierTo(w * 0.02, h * 0.22, w * 0.42, h * 0.11);
    path.quadraticBezierTo(w * 0.78, h * 0.04, w * 0.94, h * 0.38);
    path.quadraticBezierTo(w * 1.04, h * 0.72, w * 0.62, h * 0.94);
    path.quadraticBezierTo(w * 0.32, h * 1.02, w * 0.1, h * 0.78);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OrganicBlobPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HeroFallback extends StatelessWidget {
  final bool isDark;

  const _HeroFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.record_voice_over_rounded,
      size: 120,
      color: AppColors.onboardingBlue.withValues(alpha: isDark ? 0.45 : 0.35),
    );
  }
}

class _SolidPrimaryCta extends StatelessWidget {
  final String label;
  final bool showArrow;
  final VoidCallback onPressed;

  const _SolidPrimaryCta({
    required this.label,
    required this.showArrow,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.onboardingBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: base.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingSecondPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _OnboardingSecondPage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const _TrackProgressCardIllustration(),
          const SizedBox(height: 36),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
              color: c.textHeading,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: c.textMuted,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _TermsFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TermsFooter extends StatefulWidget {
  const _TermsFooter();

  @override
  State<_TermsFooter> createState() => _TermsFooterState();
}

class _TermsFooterState extends State<_TermsFooter> {
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
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: c.textMuted,
      height: 1.5,
    );
    final link = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: c.textMuted,
      decoration: TextDecoration.underline,
      decorationColor: c.textMuted,
      height: 1.5,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '${appLanguage.t('onboarding.termsPrefix')} '),
          TextSpan(
            text: appLanguage.t('onboarding.terms'),
            style: link,
            recognizer: _termsTap,
          ),
          TextSpan(text: ' ${appLanguage.t('onboarding.and')} '),
          TextSpan(
            text: appLanguage.t('onboarding.privacy'),
            style: link,
            recognizer: _privacyTap,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _TrackProgressCardIllustration extends StatelessWidget {
  const _TrackProgressCardIllustration();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const w = 18.0;
    final heights = [44.0, 62.0, 84.0, 108.0];
    final colors = [
      const Color(0xFFC8DCF9),
      const Color(0xFF93B8F5),
      const Color(0xFF4E84E8),
      AppColors.onboardingBlue,
    ];

    return SizedBox(
      height: 240,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.borderColor.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: c.shadowColor,
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < heights.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
                  child: _ChartBar(
                    width: w,
                    height: heights[i],
                    color: colors[i],
                    showTrend: i == heights.length - 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final bool showTrend;

  const _ChartBar({
    required this.width,
    required this.height,
    required this.color,
    required this.showTrend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showTrend)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: const Icon(
              Icons.show_chart_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
