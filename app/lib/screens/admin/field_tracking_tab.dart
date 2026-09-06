import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/database_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class FieldTrackingTab extends StatelessWidget {
  const FieldTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: DatabaseService.getVisitsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
        }

        final visits = snapshot.data ?? [];
        if (visits.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.photo_camera_front_rounded,
            title: 'No Field Visits Recorded',
            message: 'Visits conducted by Outside Sales reps will appear here with live status tracking, verification selfies, and audio recordings.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visits.length,
          itemBuilder: (context, index) {
            final visit = visits[index];
            final isInProgress = visit.status == VisitStatus.visitInProgress;
            final isCompleted = visit.status == VisitStatus.visitCompleted;

            final statusColor = switch (visit.status) {
              VisitStatus.visitCompleted => AppColors.success,
              VisitStatus.visitInProgress => AppColors.warning,
              VisitStatus.visitScheduled => AppColors.info,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isInProgress
                      ? AppColors.warning.withAlpha(120)
                      : AppColors.surfaceBorder,
                ),
                boxShadow: isInProgress
                    ? [
                        BoxShadow(
                          color: AppColors.warning.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withAlpha(70)),
                            ),
                            child: Icon(
                              Icons.location_city_rounded,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visit.customerName,
                                style: GoogleFonts.sora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Outside Rep: ${visit.outsideSalesName ?? "Assigned Staff"}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withAlpha(90)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isInProgress) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withAlpha(150),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              visit.status.label.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notes_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              visit.notes!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Media verification status with honest Cloud Storage gate
                  _MediaVerificationCard(visitId: visit.id, isCompleted: isCompleted),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MediaVerificationCard extends StatelessWidget {
  final String visitId;
  final bool isCompleted;

  const _MediaVerificationCard({
    required this.visitId,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('visits')
          .doc(visitId)
          .collection('private')
          .doc('media')
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final selfiePath = data?['selfiePath'] as String?;
        final recordingPath = data?['recordingPath'] as String?;

        final hasMedia = (selfiePath != null && selfiePath.isNotEmpty) ||
            (recordingPath != null && recordingPath.isNotEmpty);

        if (!hasMedia) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.cloud_off_rounded : Icons.pending_actions_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCompleted
                        ? 'Audio & selfie media will sync here once Cloud Storage is configured'
                        : 'Visit is in progress. Media will upload automatically upon visit completion',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selfiePath != null && selfiePath.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Customer Verification Selfie',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: FirebaseStorage.instance.ref(selfiePath).getDownloadURL(),
                  builder: (context, urlSnap) {
                    if (urlSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (urlSnap.hasError || !urlSnap.hasData) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBorder.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Path: $selfiePath',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urlSnap.data!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_rounded),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (recordingPath != null && recordingPath.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Site Audio Recording',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audiotrack_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recordingPath,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
