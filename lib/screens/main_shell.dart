import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show isFirebaseSupported;
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'practice_screen.dart';
import 'conversation_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final t = appLanguage.t;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigate: _navigateTo,
            userName: isFirebaseSupported
                ? (FirebaseAuth.instance.currentUser?.displayName ?? 'User')
                : 'User',
          ),
          const PracticeScreen(),
          const ConversationScreen(),
          const ProgressScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.dashboardNavPill,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.onboardingBlue
                      : AppColors.dashboardNavInactive,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 24,
                  color: selected
                      ? AppColors.onboardingBlue
                      : AppColors.dashboardNavInactive,
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
                  icon: Icon(Icons.home_rounded),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: t('nav.home'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_rounded),
                  selectedIcon: Icon(Icons.fitness_center_rounded),
                  label: t('nav.practice'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: t('nav.chat'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_rounded),
                  selectedIcon: Icon(Icons.show_chart_rounded),
                  label: t('nav.progress'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
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
