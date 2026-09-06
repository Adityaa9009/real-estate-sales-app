import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'outside_home_view.dart';
import 'outside_profile_view.dart';
import 'visits_view.dart';

class OutsideSalesShell extends StatefulWidget {
  const OutsideSalesShell({super.key});

  @override
  State<OutsideSalesShell> createState() => _OutsideSalesShellState();
}

class _OutsideSalesShellState extends State<OutsideSalesShell> {
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
                  colors: [AppColors.success, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
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
                    0 => 'Field Operations Hub',
                    1 => 'Assigned Site Visits',
                    2 => 'Field Specialist Profile',
                    _ => 'Outside Sales',
                  },
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'On-Site Tours & Client Verification',
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
              color: AppColors.success.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Outside Sales',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
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
          OutsideHomeView(
            onNavigateToVisits: () => setState(() => _navIndex = 1),
          ),
          const VisitsView(),
          const OutsideProfileView(),
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
          indicatorColor: AppColors.success.withAlpha(40),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.success),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.pin_drop_rounded),
              selectedIcon: Icon(Icons.pin_drop_rounded, color: AppColors.success),
              label: 'Visits',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.success),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
