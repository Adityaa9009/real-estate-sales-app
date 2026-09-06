import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/employee.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_badge.dart';
import '../login_screen.dart';

class OutsideProfileView extends StatelessWidget {
  const OutsideProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final emp = AuthService.currentEmployee;
    final initials = emp?.name.trim().isNotEmpty == true
        ? emp!.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'OS';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Avatar with Gradient Ring
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.success, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withAlpha(60),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.sora(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceCard, width: 3),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  emp?.name ?? 'Outside Sales Specialist',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const RoleBadge(role: AppRole.outsideSales),
                const SizedBox(height: 24),
                const Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: 20),

                // Info Rows
                _infoRow(Icons.email_outlined, 'Email', emp?.email ?? 'N/A'),
                const SizedBox(height: 14),
                _infoRow(Icons.phone_outlined, 'Phone', emp?.phone ?? 'N/A'),
                const SizedBox(height: 14),
                _infoRow(Icons.directions_walk_rounded, 'Operations', 'Field Client Site Visits'),
                const SizedBox(height: 14),
                _infoRow(Icons.verified_user_outlined, 'Auth Security', 'Mobile Field Access Active'),
                const SizedBox(height: 28),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                    label: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.danger.withAlpha(80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppColors.danger.withAlpha(15),
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
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
