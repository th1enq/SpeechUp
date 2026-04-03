import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans();

    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.onboardingBlue,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SpeechUp',
                      textAlign: TextAlign.center,
                      style: base.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.profileNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.onboardingBlue,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    _ProfileAvatarGlow(
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.onboardingBlueSky.withValues(alpha: 0.35),
                              AppColors.onboardingBlue.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Jane Doe',
                      style: base.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.profileNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.profileStreakPillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: AppColors.profileStreakPillText,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '7-day practice streak',
                            style: base.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.profileStreakPillText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      base: base,
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppColors.onboardingBlue,
                      iconCircleBg: const Color(0xFFE8F1FF),
                      value: '45',
                      valueExtra: null,
                      label: 'Total Sessions',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      base: base,
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.progressMilestonePurple,
                      iconCircleBg: const Color(0xFFF3E8FF),
                      value: '2.5',
                      valueExtra: 'h',
                      label: 'Speaking Time',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: AppColors.dashboardHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onboardingBlue.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '84',
                          style: base.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Average Score',
                          style: base.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Account Settings',
                style: base.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.profileNavy,
                ),
              ),
              const SizedBox(height: 14),
              _SettingsRow(
                base: base,
                icon: Icons.language_rounded,
                iconColor: AppColors.onboardingBlue,
                iconBg: const Color(0xFFE8F1FF),
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                base: base,
                icon: Icons.psychology_outlined,
                iconColor: AppColors.progressMilestonePurple,
                iconBg: const Color(0xFFF3E8FF),
                title: 'Speech Difficulty',
                subtitle: 'Intermediate',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                base: base,
                icon: Icons.notifications_outlined,
                iconColor: AppColors.progressMilestonePurple,
                iconBg: const Color(0xFFF3E8FF),
                title: 'Notifications',
                subtitle: 'On • 8:00 PM Daily',
                onTap: () {},
                trailing: Switch.adaptive(
                  value: _notificationsOn,
                  activeTrackColor: AppColors.onboardingBlue.withValues(alpha: 0.55),
                  activeThumbColor: Colors.white,
                  onChanged: (v) => setState(() => _notificationsOn = v),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.profileLogoutMaroon,
                    side: BorderSide(
                      color: AppColors.dashboardTextMuted.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: base.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.profileLogoutMaroon,
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

class _ProfileAvatarGlow extends StatelessWidget {
  final Widget child;

  const _ProfileAvatarGlow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingBlue.withValues(alpha: 0.22),
                blurRadius: 28,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.onboardingBlueSky.withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        child,
        Positioned(
          right: 4,
          bottom: 4,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.profileNavy.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.progressMilestonePurple,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final TextStyle base;
  final IconData icon;
  final Color iconColor;
  final Color iconCircleBg;
  final String value;
  final String? valueExtra;
  final String label;

  const _StatCard({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.iconCircleBg,
    required this.value,
    this.valueExtra,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileNavy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconCircleBg,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          valueExtra == null
              ? Text(
                  value,
                  style: base.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.profileNavy,
                    height: 1,
                  ),
                )
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: base.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.profileNavy,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: valueExtra,
                        style: base.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.profileNavy,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 6),
          Text(
            label,
            style: base.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.dashboardTextMuted,
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

  const _SettingsRow({
    required this.base,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
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
                    color: AppColors.profileNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: base.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dashboardTextMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.dashboardTextMuted.withValues(alpha: 0.65),
                size: 24,
              ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileNavy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: trailing == null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: body,
              )
            : body,
      ),
    );
  }
}
