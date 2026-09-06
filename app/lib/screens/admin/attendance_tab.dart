import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/attendance.dart';
import '../../services/database_service.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Attendance>>(
      stream: DatabaseService.getAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.co_present_rounded,
                  size: 54,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'No attendance records logged.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final item = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: item.loginAllowed
                        ? AppColors.success.withAlpha(35)
                        : AppColors.danger.withAlpha(35),
                    radius: 18,
                    child: Icon(
                      item.loginAllowed
                          ? Icons.check_circle_outline_rounded
                          : Icons.block_rounded,
                      color: item.loginAllowed
                          ? AppColors.success
                          : AppColors.danger,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.employeeName ??
                              item.employeeEmail ??
                              'Staff ID: ${item.employeeId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Login: ${dateFormat.format(item.loginAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (item.logoutAt != null)
                          Text(
                            'Logout: ${dateFormat.format(item.logoutAt!)} (Logged: ${item.workingDuration.inHours}h ${item.workingDuration.inMinutes % 60}m)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          )
                        else
                          const Text(
                            'Currently Active in Office',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.loginAllowed
                          ? AppColors.success.withAlpha(25)
                          : AppColors.danger.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.loginAllowed ? 'VERIFIED' : 'GEOFENCE REJECTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.loginAllowed
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
