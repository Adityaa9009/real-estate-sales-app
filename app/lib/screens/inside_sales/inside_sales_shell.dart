import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'assigned_tracking_view.dart';
import 'calls_view.dart';
import 'inside_home_view.dart';
import 'interested_view.dart';
import 'not_interested_view.dart';
import 'profile_view.dart';

class InsideSalesShell extends StatefulWidget {
  const InsideSalesShell({super.key});

  @override
  State<InsideSalesShell> createState() => _InsideSalesShellState();
}

class _InsideSalesShellState extends State<InsideSalesShell> {
  int _navIndex = 0;

  void _handleLogout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  switch (_navIndex) {
                    0 => 'Inside Sales Hub',
                    1 => 'Call Queue',
                    2 => 'Interested Leads',
                    3 => 'Not Interested Leads',
                    4 => 'Assigned Visits',
                    5 => 'Representative Profile',
                    _ => 'Inside Sales',
                  },
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Lead Qualification & Visit Scheduling',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Inside Sales',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surfaceBorder, height: 1),
        ),
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          InsideHomeView(
            onNavigateToCalls: () => setState(() => _navIndex = 1),
            onNavigateToInterested: () => setState(() => _navIndex = 2),
          ),
          const CallsView(),
          const InterestedView(),
          const NotInterestedView(),
          const AssignedTrackingView(),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (index) => setState(() => _navIndex = index),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withAlpha(40),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.phone_outlined),
              selectedIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
              label: 'Calls',
            ),
            NavigationDestination(
              icon: Icon(Icons.thumb_up_outlined),
              selectedIcon: Icon(Icons.thumb_up_rounded, color: AppColors.primary),
              label: 'Interested',
            ),
            NavigationDestination(
              icon: Icon(Icons.thumb_down_outlined),
              selectedIcon: Icon(Icons.thumb_down_rounded, color: AppColors.primary),
              label: 'Not Int.',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              label: 'Visits',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
