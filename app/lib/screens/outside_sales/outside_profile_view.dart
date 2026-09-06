import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class OutsideProfileView extends StatelessWidget {
  const OutsideProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final emp = AuthService.currentEmployee;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF009688),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder, width: 3),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Username: ${emp?.name ?? "Field Representative"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Email: ${emp?.email ?? "N/A"}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phone: ${emp?.phone ?? "N/A"}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Role: Outside Sales Specialist',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                  ),
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
