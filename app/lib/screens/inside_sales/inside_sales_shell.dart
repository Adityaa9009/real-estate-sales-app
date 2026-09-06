import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              switch (_navIndex) {
                0 => 'Inside Sales Dashboard',
                1 => 'Customer Calls',
                2 => 'Interested Leads',
                3 => 'Not Interested Leads',
                4 => 'Assigned Site Visits',
                5 => 'User Profile',
                _ => 'Inside Sales',
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.call_rounded), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.thumb_up_rounded), label: 'Interested'),
          BottomNavigationBarItem(icon: Icon(Icons.thumb_down_rounded), label: 'Not Int.'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_rounded), label: 'Assigned'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
