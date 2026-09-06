import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/database_service.dart';

class AssignedTrackingView extends StatelessWidget {
  const AssignedTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Visit>>(
      stream: DatabaseService.getVisitsStream(insideSalesId: currentUid),
      builder: (context, snapshot) {
        final visits = snapshot.data ?? [];
        if (visits.isEmpty) {
          return const Center(
            child: Text(
              'No outside sales visits currently assigned.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visits.length,
          itemBuilder: (context, index) {
            final v = visits[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(
                    Icons.directions_walk_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  v.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Rep: ${v.outsideSalesName ?? "Outside Staff"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Visit Time: ${dateFormat.format(v.scheduledAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                trailing: Chip(
                  label: Text(v.status.label.toUpperCase()),
                  backgroundColor: v.status == VisitStatus.visitCompleted
                      ? AppColors.success.withAlpha(40)
                      : AppColors.warning.withAlpha(40),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
