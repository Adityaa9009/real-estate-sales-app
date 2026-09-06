import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/metric_card.dart';

class OutsideHomeView extends StatelessWidget {
  final VoidCallback onNavigateToVisits;

  const OutsideHomeView({super.key, required this.onNavigateToVisits});

  @override
  Widget build(BuildContext context) {
    final emp = AuthService.currentEmployee;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final todayStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field Operations: ${emp?.name ?? "Outside Rep"}',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Conduct on-site customer property visits, capture verification media, and securely log client interactions.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // KPI Stats
          StreamBuilder<List<Visit>>(
            stream: DatabaseService.getVisitsStream(outsideSalesId: currentUid),
            builder: (context, snapshot) {
              final visits = snapshot.data ?? [];
              final totalVisits = visits.length;
              final completedVisits = visits
                  .where((v) => v.status == VisitStatus.visitCompleted)
                  .length;
              final pendingVisits = visits
                  .where(
                    (v) =>
                        v.status == VisitStatus.visitScheduled ||
                        v.status == VisitStatus.visitInProgress,
                  )
                  .length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  final cards = [
                    MetricCard(
                      title: 'Scheduled Visits',
                      value: '$totalVisits',
                      icon: Icons.calendar_today_rounded,
                      accentColor: AppColors.primary,
                      onTap: onNavigateToVisits,
                    ),
                    MetricCard(
                      title: 'Pending Today',
                      value: '$pendingVisits',
                      icon: Icons.pending_actions_rounded,
                      accentColor: AppColors.warning,
                      onTap: onNavigateToVisits,
                    ),
                    MetricCard(
                      title: 'Completed',
                      value: '$completedVisits',
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: AppColors.success,
                      onTap: onNavigateToVisits,
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: cards
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: c,
                              ))
                          .toList(),
                    );
                  }

                  return Row(
                    children: cards
                        .map((c) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: c,
                              ),
                            ))
                        .toList(),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // Workflow Guidelines Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.checklist_rtl_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mandatory Visit Protocol',
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Compliance standard for all field representatives',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: 18),
                _workflowStep(
                  1,
                  Icons.phone_in_talk_rounded,
                  AppColors.primary,
                  'Confirmation Call',
                  'Place a quick call to the customer to confirm the appointment time before traveling.',
                ),
                _workflowStep(
                  2,
                  Icons.location_on_rounded,
                  AppColors.warning,
                  'Reached Location & Audio',
                  'Tap "Reached Location" on site to start meeting notes and automatically begin audio capture.',
                ),
                _workflowStep(
                  3,
                  Icons.camera_alt_rounded,
                  AppColors.info,
                  'Client Verification Selfie',
                  'Capture a verification photo with the customer on site and upload it to secure storage.',
                ),
                _workflowStep(
                  4,
                  Icons.check_circle_rounded,
                  AppColors.success,
                  'Complete & Conclude',
                  'Tap "Completed Visit" to stop audio recording, verify cloud upload, and submit visit summary.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workflowStep(int num, IconData icon, Color color, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                '$num',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
