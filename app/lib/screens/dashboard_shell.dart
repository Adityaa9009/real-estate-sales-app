import 'dart:async';
import 'package:flutter/material.dart';
import '../config/office_location.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'calls_screen.dart';
import 'interested_screen.dart';
import 'assigned_outside_employees_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;
  StreamSubscription? _locationSub;

  final _screens = const [
    HomeScreen(),
    CallsScreen(),
    InterestedScreen(),
    AssignedOutsideEmployeesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _watchGeofence();
  }

  void _watchGeofence() {
    _locationSub = LocationService.watchPosition().listen((position) async {
      final distance = LocationService.distanceToOfficeMeters(position);
      if (distance > OfficeLocation.allowedRadiusMeters && mounted) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F9BFF),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF2F9BFF),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Interested'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Assigned'),
        ],
      ),
    );
  }
}
