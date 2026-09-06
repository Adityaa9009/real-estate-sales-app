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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_front_rounded, size: 54, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No field visits recorded yet.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => DatabaseService.seedDemoData(),
                  child: const Text('Seed Sample Visits'),
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
                            child: Icon(Icons.location_city_rounded, color: Colors.white, size: 18),
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
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: visit.status == 'completed'
                              ? AppColors.success.withAlpha(35)
                              : AppColors.warning.withAlpha(35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: visit.status == 'completed' ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        child: Text(
                          visit.status.toUpperCase(),
                          style: TextStyle(
                            color: visit.status == 'completed' ? AppColors.success : AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visit.notes != null) ...[
                    Text(
                      visit.notes!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Selfie & Audio Cards (PDF Page 1: Admin can see updates of outside sales like selfies and voice recordings)
                  Row(
                    children: [
                      // Customer Selfie Preview
                      Expanded(
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.info),
                                  SizedBox(width: 6),
                                  Text(
                                    'Customer Selfie',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              visit.selfiePath != null
                                  ? Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            visit.selfiePath!,
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => const Icon(Icons.person_rounded, size: 36),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text('Verified on Site', style: TextStyle(fontSize: 11, color: AppColors.success)),
                                        ),
                                      ],
                                    )
                                  : const Text('No selfie uploaded yet', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Audio Recording Track
                      Expanded(
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.mic_rounded, size: 14, color: AppColors.danger),
                                  SizedBox(width: 6),
                                  Text(
                                    'Site Audio Record',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              visit.recordingPath != null
                                  ? Row(
                                      children: [
                                        IconButton.filled(
                                          style: IconButton.styleFrom(
                                            backgroundColor: AppColors.danger,
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Playing recording: ${visit.recordingPath}')),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text('Audio Logged (12m)', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                        ),
                                      ],
                                    )
                                  : const Text('Recording in progress...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ],
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
