import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/call_service.dart';
import '../../services/database_service.dart';
import '../../services/media_service.dart';

class VisitsView extends StatefulWidget {
  const VisitsView({super.key});

  @override
  State<VisitsView> createState() => _VisitsViewState();
}

class _VisitsViewState extends State<VisitsView> {
  String? _activeRecordingVisitId;
  int _recordingSeconds = 0;

  void _handleReachedLocation(Visit visit) {
    setState(() {
      _activeRecordingVisitId = visit.id;
      _recordingSeconds = 0;
    });

    MediaService.startRecording(onTick: (sec) {
      if (mounted) setState(() => _recordingSeconds = sec);
    });

    DatabaseService.updateVisitStatus(
      visit.id,
      status: 'in_progress',
      reachedAt: DateTime.now(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.danger,
        content: Row(
          children: [
            Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Reached location recorded! Background audio recording started.'),
          ],
        ),
      ),
    );
  }

  void _handleUploadSelfie(Visit visit) async {
    final path = await MediaService.pickSelfieWithCustomer();
    if (path != null) {
      await DatabaseService.updateVisitStatus(visit.id, status: visit.status, selfiePath: path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Customer verification selfie uploaded successfully!'),
          ),
        );
      }
    }
  }

  void _handleCompletedVisit(Visit visit) async {
    final audioResult = MediaService.stopRecording();
    setState(() => _activeRecordingVisitId = null);

    await DatabaseService.updateVisitStatus(
      visit.id,
      status: 'completed',
      completedAt: DateTime.now(),
      recordingPath: audioResult.recordingPath,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Visit marked completed! Audio recorded (${audioResult.duration.inSeconds}s) and saved to database.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

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
                const Icon(Icons.assignment_turned_in_outlined, size: 54, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No scheduled customer visits assigned.', style: TextStyle(color: AppColors.textSecondary)),
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
            final v = visits[index];
            final isRecordingThis = _activeRecordingVisitId == v.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRecordingThis ? AppColors.danger : AppColors.surfaceBorder,
                  width: isRecordingThis ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Name: ${v.customerName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.call_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withAlpha(40),
                          foregroundColor: AppColors.primary,
                        ),
                        tooltip: 'Call Customer Confirmation',
                        onPressed: () => CallService.makePhoneCall(v.customerPhone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${v.maskedPhone}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled Time: ${dateFormat.format(v.scheduledAt)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.w500),
                  ),

                  // Live Recording Indicator if currently recording
                  if (isRecordingThis) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic_rounded, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Recording in progress: ${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // 3-Step Action Buttons (PDF Page 11)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Step 1: Reached Location Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.location_on_rounded, size: 16),
                        label: const Text('Reached Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: v.status == 'in_progress' ? AppColors.warning : AppColors.primary,
                        ),
                        onPressed: v.status == 'completed' ? null : () => _handleReachedLocation(v),
                      ),

                      // Step 2: Upload Selfie with Customer Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: const Text('Upload Selfie'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: const BorderSide(color: AppColors.info),
                        ),
                        onPressed: v.status == 'completed' ? null : () => _handleUploadSelfie(v),
                      ),

                      // Step 3: Completed Visit Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Completed Visit'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: v.status == 'completed' ? null : () => _handleCompletedVisit(v),
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
