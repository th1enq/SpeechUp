import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _showWeekly = true;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.progressNavyText.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.onboardingBlue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SpeechUp',
                      style: base.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.progressNavyText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.progressNavyText,
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'My Journey',
              style: base.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.progressNavyText,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: base.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dashboardTextMuted,
                  height: 1.45,
                ),
                children: const [
                  TextSpan(text: 'You’ve spoken for '),
                  TextSpan(
                    text: '128 minutes',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onboardingBlue,
                    ),
                  ),
                  TextSpan(text: ' this month. Keep it up!'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.progressToggleTrack,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PeriodToggleChip(
                      label: 'Weekly',
                      selected: _showWeekly,
                      onTap: () => setState(() => _showWeekly = true),
                    ),
                  ),
                  Expanded(
                    child: _PeriodToggleChip(
                      label: 'Monthly',
                      selected: !_showWeekly,
                      onTap: () => setState(() => _showWeekly = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _FluencyScoreCard(base: base),
            const SizedBox(height: 14),
            _PronunciationCard(base: base),
            const SizedBox(height: 14),
            _SpeechSpeedTrendCard(base: base),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestones',
                  style: base.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.progressNavyText,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onboardingBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: base.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onboardingBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MilestoneItem(
                    base: base,
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.progressMilestonePurple,
                    label: '7-day practice streak',
                  ),
                ),
                Expanded(
                  child: _MilestoneItem(
                    base: base,
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppColors.onboardingBlue,
                    label: 'Improved fluency',
                  ),
                ),
                Expanded(
                  child: _MilestoneItem(
                    base: base,
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.progressMilestonePurple,
                    label: '1 hour practice',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: AppColors.progressAccentBlue,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.progressAccentBlue.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Recommendation',
                          style: base.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your pronunciation of \'S\' sounds has improved by 20% this week. Focus on vocal resonance next!',
                          style: base.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
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

class _PeriodToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.progressNavyText.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: font.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.progressAccentBlue
                    : AppColors.dashboardTextMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FluencyScoreCard extends StatelessWidget {
  final TextStyle base;

  const _FluencyScoreCard({required this.base});

  static const List<double> _barHeights = [44.0, 58.0, 50.0, 64.0, 78.0];

  @override
  Widget build(BuildContext context) {
    final f = base;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.progressNavyText.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FLUENCY SCORE',
                style: f.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.dashboardTextMuted,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.progressTrendRed,
                    size: 18,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '+12%',
                    style: f.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.progressTrendRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '84',
                  style: f.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.progressNavyText,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: '/100',
                  style: f.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dashboardTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _barHeights.length; i++)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: _barHeights[i],
                        decoration: BoxDecoration(
                          color: i == _barHeights.length - 1
                              ? AppColors.progressAccentBlue
                              : AppColors.progressBarPale.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PronunciationCard extends StatelessWidget {
  final TextStyle base;

  const _PronunciationCard({required this.base});

  @override
  Widget build(BuildContext context) {
    final f = base;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.progressNavyText.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRONUNCIATION',
                  style: f.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.dashboardTextMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Steady Growth',
                  style: f.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.progressNavyText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechSpeedTrendCard extends StatelessWidget {
  final TextStyle base;

  const _SpeechSpeedTrendCard({required this.base});

  @override
  Widget build(BuildContext context) {
    final f = base;
    const targetProgress = 0.62;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.progressSpeedCardGradientStart,
            AppColors.progressSpeedCardGradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.progressNavyText.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speech Speed Trend',
            style: f.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.progressNavyText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Average Speed',
                style: f.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.progressNavyText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onboardingBlue.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '142 wpm',
                  style: f.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onboardingBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.85)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: targetProgress,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.progressAccentBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your target is 130–150 words per minute for clear professional delivery.',
            style: f.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.dashboardTextMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final TextStyle base;
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MilestoneItem({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final f = base;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.progressNavyText.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: f.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.dashboardTextMuted,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}
