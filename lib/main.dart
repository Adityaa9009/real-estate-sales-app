import 'package:flutter/material.dart';
import 'repository/executive_repository.dart';
import 'screens/executive_dashboard_screen.dart';
import 'theme/app_theme.dart';

/// INTEGRATION NOTE:
/// When the team lead's Firebase backend is ready, replace
/// MockExecutiveRepository() below with FirebaseExecutiveRepository().
/// No other file needs to change.
void main() {
  runApp(const RealEstateExecutiveApp());
}

class RealEstateExecutiveApp extends StatelessWidget {
  const RealEstateExecutiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate — Executive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: ExecutiveDashboardScreen(
        repository: MockExecutiveRepository(),
        // When real auth is wired, replace this with the actual
        // FirebaseAuth.instance.currentUser!.uid
        currentExecutiveId: 'mock-executive-001',
      ),
    );
  }
}
