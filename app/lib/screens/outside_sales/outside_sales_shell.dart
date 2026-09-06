import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.directions_walk_rounded,
              color: AppColors.success,
              size: 22,
            ),
            SizedBox(width: 8),
            Text('Outside Sales Dashboard'),
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
          OutsideHomeView(
            onNavigateToVisits: () => setState(() => _navIndex = 1),
          ),
          const VisitsView(),
          const OutsideProfileView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pin_drop_rounded),
            label: 'Assigned Visits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
