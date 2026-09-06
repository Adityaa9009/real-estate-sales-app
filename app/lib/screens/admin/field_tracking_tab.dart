import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/database_service.dart';

class FieldTrackingTab extends StatelessWidget {
  const FieldTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: DatabaseService.getVisitsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final visits = snapshot.data ?? [];
        if (visits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_front_rounded,
                  size: 54,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'No field visits recorded yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visits.length,
          itemBuilder: (context, index) {
            final visit = visits[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.location_city_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visit.customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Outside Rep: ${visit.outsideSalesName ?? "Assigned Staff"}',
                                style: const TextStyle(
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
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: switch (visit.status) {
                            VisitStatus.visitCompleted =>
                              AppColors.success.withAlpha(35),
                            VisitStatus.visitInProgress =>
                              AppColors.warning.withAlpha(35),
                            VisitStatus.visitScheduled =>
                              AppColors.info.withAlpha(35),
                          },
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: switch (visit.status) {
                              VisitStatus.visitCompleted => AppColors.success,
                              VisitStatus.visitInProgress => AppColors.warning,
                              VisitStatus.visitScheduled => AppColors.info,
                            },
                          ),
                        ),
                        child: Text(
                          visit.status.label.toUpperCase(),
                          style: TextStyle(
                            color: switch (visit.status) {
                              VisitStatus.visitCompleted => AppColors.success,
                              VisitStatus.visitInProgress => AppColors.warning,
                              VisitStatus.visitScheduled => AppColors.info,
                            },
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                    Text(
                      'Notes: ${visit.notes!}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Media verification status with honest Cloud Storage gate
                  _MediaVerificationCard(visitId: visit.id),
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
  const _MediaVerificationCard({required this.visitId});

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
        final selfieUrl = data?['selfieUrl'] as String?;
        final audioUrl = data?['audioUrl'] as String?;

        final hasMedia = (selfieUrl != null && selfieUrl.isNotEmpty) ||
            (audioUrl != null && audioUrl.isNotEmpty);

        if (!hasMedia) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recordings & selfies will appear here once Cloud Storage is enabled',
                    style: TextStyle(
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selfieUrl != null && selfieUrl.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Customer Verification Selfie',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    selfieUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (audioUrl != null && audioUrl.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Site Audio Recording',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Audio proof recorded and stored securely.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
