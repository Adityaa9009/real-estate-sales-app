import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/customer_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(backgroundColor: const Color(0xFF2F9BFF), title: const Text('Profile')),
      body: FutureBuilder<Employee>(
        future: CustomerService.getProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      (p.profileImageUrl != null && p.profileImageUrl!.isNotEmpty)
                          ? NetworkImage(p.profileImageUrl!)
                          : null,
                  child: (p.profileImageUrl == null || p.profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 24),
                _row('Name', p.name),
                _row('Email', p.email),
                _row('Phone', p.phone),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
