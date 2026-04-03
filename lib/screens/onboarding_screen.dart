import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SpeechUpLogo(),
                  if (_currentPage == 0)
                    TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onboardingTextMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onboardingTextMuted,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 56),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _OnboardingPage(
                    illustration: const _SoundWaveIllustration(),
                    titleWidget: Text.rich(
                      TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.onboardingNavy,
                        ),
                        children: const [
                          TextSpan(text: 'Improve Your '),
                          TextSpan(
                            text: 'Speaking',
                            style: TextStyle(color: AppColors.onboardingBlue),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    subtitle:
                        'SpeechUp helps you practice speaking and analyze your voice with AI.',
                    bottom: null,
                  ),
                  _OnboardingPage(
                    illustration: const _TrackProgressCardIllustration(),
                    titleWidget: Text(
                      'Track Your Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: AppColors.onboardingNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    subtitle: 'See how your speech improves over time.',
                    bottom: const _TermsFooter(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                children: [
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
                              ? AppColors.onboardingNavy
                              : AppColors.onboardingDotInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  _GradientCtaButton(
                    label: _currentPage == 0 ? 'Next' : 'Get Started',
                    showArrow: _currentPage == 0,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechUpLogo extends StatelessWidget {
  const _SpeechUpLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.onboardingBlueDeep,
                AppColors.onboardingBlue,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: 26,
              ),
              const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            children: const [
              TextSpan(text: 'Speech', style: TextStyle(color: AppColors.onboardingNavy)),
              TextSpan(text: 'Up', style: TextStyle(color: AppColors.onboardingBlue)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final Widget titleWidget;
  final String subtitle;
  final Widget? bottom;

  const _OnboardingPage({
    required this.illustration,
    required this.titleWidget,
    required this.subtitle,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          illustration,
          const SizedBox(height: 40),
          titleWidget,
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.onboardingTextMuted,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          if (bottom != null) ...[
            const SizedBox(height: 28),
            bottom!,
          ],
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
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.onboardingTextMuted,
      height: 1.5,
    );
    final link = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.onboardingTextMuted,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.onboardingTextMuted,
      height: 1.5,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(text: 'Terms of Service', style: link, recognizer: _termsTap),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacyTap),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _GradientCtaButton extends StatelessWidget {
  final String label;
  final bool showArrow;
  final VoidCallback onPressed;

  const _GradientCtaButton({
    required this.label,
    required this.showArrow,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.onboardingCtaGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingBlue.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundWaveIllustration extends StatelessWidget {
  const _SoundWaveIllustration();

  @override
  Widget build(BuildContext context) {
    // Symmetrical peak + symmetric blues: pale → medium → primary (Figma)
    final bars = [
      (52.0, AppColors.onboardingWaveOuter),
      (76.0, AppColors.onboardingWaveMid),
      (104.0, AppColors.onboardingBlue),
      (76.0, AppColors.onboardingWaveMid),
      (52.0, AppColors.onboardingWaveOuter),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            return SizedBox(
              width: maxW,
              height: 212,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: AppColors.onboardingBlue.withValues(alpha: 0.09),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 32,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onboardingAccentSoft.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < bars.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          _WaveBar(height: bars[i].$1, color: bars[i].$2),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onboardingNavy.withValues(alpha: 0.09),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.onboardingBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.onboardingBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE ANALYSIS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.onboardingTextMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '98% Clarity Achieved',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onboardingNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveBar extends StatelessWidget {
  final double height;
  final Color color;

  const _WaveBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    const barWidth = 13.0;
    return Container(
      width: barWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(barWidth / 2),
      ),
    );
  }
}

class _TrackProgressCardIllustration extends StatelessWidget {
  const _TrackProgressCardIllustration();

  @override
  Widget build(BuildContext context) {
    const w = 18.0;
    final heights = [44.0, 62.0, 84.0, 108.0];
    final colors = [
      const Color(0xFFC8DCF9),
      const Color(0xFF93B8F5),
      const Color(0xFF4E84E8),
      AppColors.onboardingNavy,
    ];

    return SizedBox(
      height: 240,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingNavy.withValues(alpha: 0.08),
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
