import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class DemoAccountBanner extends StatelessWidget {
  final void Function(String email, String password) onSelectAccount;

  const DemoAccountBanner({super.key, required this.onSelectAccount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: AppColors.primaryLight),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Demo Quick-Login (1-Tap for Evaluation)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                label: 'Admin',
                color: AppColors.danger,
                email: 'admin@realestate.com',
                password: 'password123',
              ),
              _buildChip(
                label: 'Executive',
                color: AppColors.secondary,
                email: 'executive@realestate.com',
                password: 'password123',
              ),
              _buildChip(
                label: 'Inside Sales',
                color: AppColors.primary,
                email: 'inside.sales@realestate.com',
                password: 'password123',
              ),
              _buildChip(
                label: 'Outside Sales',
                color: AppColors.success,
                email: 'outside.sales@realestate.com',
                password: 'password123',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required String email,
    required String password,
  }) {
    return InkWell(
      onTap: () => onSelectAccount(email, password),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
