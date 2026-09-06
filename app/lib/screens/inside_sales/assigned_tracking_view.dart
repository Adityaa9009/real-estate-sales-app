import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/database_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class AssignedTrackingView extends StatelessWidget {
  const AssignedTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Visit>>(
      stream: DatabaseService.getVisitsStream(insideSalesId: currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
        }

        final visits = snapshot.data ?? [];
        if (visits.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.calendar_today_rounded,
            title: 'No Visits Assigned',
            message: 'When you assign qualified leads for on-site tours with Outside Sales, their visit status will appear here.',
          );
        }

        final completedCount = visits.where((v) => v.status == VisitStatus.visitCompleted).length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.secondary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Assigned Site Visits (${visits.length})',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completedCount Completed',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visits.length,
                itemBuilder: (context, index) {
                  final v = visits[index];
                  final initials = v.customerName.trim().isNotEmpty
                      ? v.customerName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.secondary.withAlpha(35),
                              child: Text(
                                initials,
                                style: GoogleFonts.sora(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        v.customerName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildVisitStatusPill(v.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_pin_circle_rounded, size: 13, color: AppColors.primaryLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Outside Rep: ${v.outsideSalesName ?? "Field Rep"}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(v.scheduledAt),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisitStatusPill(VisitStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case VisitStatus.visitScheduled:
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        label = 'SCHEDULED';
        break;
      case VisitStatus.visitInProgress:
        bg = AppColors.info.withAlpha(30);
        fg = AppColors.info;
        label = 'IN PROGRESS';
        break;
      case VisitStatus.visitCompleted:
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        label = 'COMPLETED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
