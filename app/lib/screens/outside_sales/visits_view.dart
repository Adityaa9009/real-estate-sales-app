import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
import '../../services/audio_recording_service.dart';
import '../../services/call_service.dart';
import '../../services/database_service.dart';
import '../../services/media_service.dart';
import '../../services/storage_availability_service.dart';

class VisitsView extends StatefulWidget {
  const VisitsView({super.key});

  @override
  State<VisitsView> createState() => _VisitsViewState();
}

class _VisitsViewState extends State<VisitsView> {
  final AudioRecordingService _audioService = AudioRecordingService();
  bool _isStorageAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStorage();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _checkInitialStorage() async {
    final res = await StorageAvailabilityService.check();
    if (mounted) {
      setState(() {
        _isStorageAvailable = res.isReady;
      });
    }
  }

  Future<StorageCheckResult> _ensureStorageAvailable({String? visitId}) async {
    // Show brief progress spinner while checking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            color: AppColors.surfaceCard,
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Checking Cloud Storage...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final res = await StorageAvailabilityService.check(
      visitId: visitId,
      forceRefresh: true,
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isStorageAvailable = res.isReady;
      });
    }

    if (!res.isReady && mounted) {
      _showStorageRequiredDialog(res);
    }

    return res;
  }

  void _showStorageRequiredDialog(StorageCheckResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cloud Storage Required',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          result.isUnauthorized
              ? 'Your account is currently unauthorized to access Cloud Storage for this visit. Please verify your assignment and active employee status.'
              : 'Visit recordings and verification selfies are stored securely in Firebase Cloud Storage. '
                  'This project\'s Firebase Storage has not been configured yet — audio recording and '
                  'media upload require Firebase Storage configuration on the Blaze (pay-as-you-go) billing plan.\n\n'
                  'Once Firebase Cloud Storage is set up, site audio recording and customer selfie verification '
                  'will be operational.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              final uri = Uri.parse('https://firebase.google.com/pricing');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Firebase Storage setup information'),
          ),
        ],
      ),
    );
  }

  void _onReachedLocationTapped(Visit visit) async {
    final check = await _ensureStorageAvailable(visitId: visit.id);
    if (!check.isReady) return;

    // Check microphone permission before starting
    final hasMic = await _audioService.hasPermission();
    if (!hasMic) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Microphone permission is required to record visit audio.',
            ),
          ),
        );
      }
      return;
    }

    try {
      // 1. Start real audio recording
      await _audioService.startRecording(visit.id);

      // 2. Mark visit in-progress atomically with customer status
      await DatabaseService.reachVisit(
        visitId: visit.id,
        customerId: visit.customerId,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Reached location confirmed! Audio recording started for this visit.',
            ),
          ),
        );
      }
    } catch (e) {
      await _audioService.cancelRecording();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to start visit & recording: $e'),
          ),
        );
      }
    }
  }

  void _onUploadSelfieTapped(Visit visit) async {
    final check = await _ensureStorageAvailable(visitId: visit.id);
    if (!check.isReady) return;

    final XFile? photo = await MediaService.captureVerificationPhoto();
    if (photo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text('Verification photo capture cancelled.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.info,
        content: Text('Uploading verification selfie to Cloud Storage...'),
      ),
    );

    final storagePath =
        'visits/${visit.id}/selfies/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(storagePath);

    try {
      final bytes = await photo.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } catch (uploadError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to upload selfie: $uploadError'),
          ),
        );
      }
      return;
    }

    // Write Firestore metadata only after successful Storage upload
    try {
      await FirebaseFirestore.instance
          .collection('visits')
          .doc(visit.id)
          .collection('private')
          .doc('media')
          .set({
            'selfiePath': storagePath,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Verification selfie uploaded successfully!'),
          ),
        );
      }
    } catch (firestoreError) {
      // Rollback: best-effort delete uploaded object
      await ref.delete().catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Failed to save selfie metadata: $firestoreError. Upload was rolled back.',
            ),
          ),
        );
      }
    }
  }

  void _onCompletedVisitTapped(Visit visit) async {
    final check = await _ensureStorageAvailable(visitId: visit.id);
    if (!check.isReady) return;
    if (!mounted) return;

    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Complete Site Visit',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finalize the customer visit. Visit audio recording will be uploaded and verified before completion.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Visit Notes',
                hintText:
                    'Customer feedback, budget confirmation, or next steps...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processVisitCompletion(visit, notesController.text.trim());
            },
            child: const Text('Complete Visit'),
          ),
        ],
      ),
    );
  }

  Future<void> _processVisitCompletion(Visit visit, String notes) async {
    // 1. Stop audio recording
    String? audioPath;
    try {
      audioPath = await _audioService.stopRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to stop audio recording: $e. Visit completion aborted.'),
          ),
        );
      }
      return;
    }

    if (audioPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Audio recording is required to complete this visit. Please record the visit audio before completing.',
            ),
          ),
        );
      }
      return;
    }

    // 2. Upload audio to Cloud Storage cross-platform
    final audioStoragePath =
        'visits/${visit.id}/audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
    final audioRef = FirebaseStorage.instance.ref(audioStoragePath);

    try {
      final audioFile = XFile(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      await audioRef.putData(
        audioBytes,
        SettableMetadata(contentType: 'audio/mp4'),
      );
    } catch (uploadError) {
      await _audioService.cancelRecording();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to upload visit audio: $uploadError. Completion aborted.'),
          ),
        );
      }
      return;
    }

    // 3. Write metadata to /visits/{id}/private/media
    try {
      await FirebaseFirestore.instance
          .collection('visits')
          .doc(visit.id)
          .collection('private')
          .doc('media')
          .set({
            'recordingPath': audioStoragePath,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (firestoreError) {
      // Rollback: best-effort delete uploaded audio object
      await audioRef.delete().catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Failed to save visit audio metadata: $firestoreError. Completion aborted and audio upload rolled back.',
            ),
          ),
        );
      }
      return;
    }

    // 4. Complete visit atomically with customer document
    try {
      await DatabaseService.completeVisit(
        visitId: visit.id,
        customerId: visit.customerId,
        notes: notes.isEmpty ? null : notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Visit marked completed successfully with audio proof!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Error updating visit status: $e'),
          ),
        );
      }
    }
  }

  Widget _wrapWithLockBadge({required Widget child}) {
    if (_isStorageAvailable) return child;

    return Badge(
      alignment: const Alignment(0.9, -0.9),
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      label: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textMuted.withAlpha(140),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          size: 11,
          color: AppColors.textMuted,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Visit>>(
      stream: DatabaseService.getVisitsStream(outsideSalesId: currentUid),
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
                  Icons.assignment_turned_in_outlined,
                  size: 54,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'No scheduled customer visits assigned.',
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
            final v = visits[index];
            final isCurrentRecording =
                _audioService.isRecording && _audioService.currentVisitId == v.id;

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
                      Expanded(
                        child: Text(
                          v.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: switch (v.status) {
                            VisitStatus.visitCompleted =>
                              AppColors.success.withAlpha(30),
                            VisitStatus.visitInProgress =>
                              AppColors.warning.withAlpha(30),
                            VisitStatus.visitScheduled =>
                              AppColors.info.withAlpha(30),
                          },
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          v.status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: switch (v.status) {
                              VisitStatus.visitCompleted => AppColors.success,
                              VisitStatus.visitInProgress => AppColors.warning,
                              VisitStatus.visitScheduled => AppColors.info,
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.call_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withAlpha(40),
                          foregroundColor: AppColors.primary,
                        ),
                        tooltip: 'Call Customer Confirmation',
                        onPressed: () async {
                          final res = await CallService.callCustomerById(
                            v.customerId,
                          );
                          if (!res.success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${v.maskedPhone}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled Time: ${dateFormat.format(v.scheduledAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (v.notes != null && v.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Notes: ${v.notes}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (isCurrentRecording) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withAlpha(80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mic, size: 16, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text(
                            'Audio recording active for this site visit...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // 3-Step Action Buttons (PDF Page 11) with Honest Storage Gate
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Step 1: Reached Location Button
                      _wrapWithLockBadge(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on_rounded, size: 16),
                          label: Text(
                            v.status == VisitStatus.visitInProgress
                                ? 'In Progress'
                                : 'Reached Location',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                v.status == VisitStatus.visitInProgress
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                          onPressed: !_isStorageAvailable
                              ? () => _onReachedLocationTapped(v)
                              : (v.status == VisitStatus.visitScheduled
                                  ? () => _onReachedLocationTapped(v)
                                  : null),
                        ),
                      ),

                      // Step 2: Upload Selfie with Customer Button
                      _wrapWithLockBadge(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Upload Selfie'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: const BorderSide(color: AppColors.info),
                          ),
                          onPressed: !_isStorageAvailable
                              ? () => _onUploadSelfieTapped(v)
                              : (v.status == VisitStatus.visitInProgress
                                  ? () => _onUploadSelfieTapped(v)
                                  : null),
                        ),
                      ),

                      // Step 3: Completed Visit Button
                      _wrapWithLockBadge(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                          ),
                          label: const Text('Completed Visit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          onPressed: !_isStorageAvailable
                              ? () => _onCompletedVisitTapped(v)
                              : (v.status == VisitStatus.visitInProgress
                                  ? () => _onCompletedVisitTapped(v)
                                  : null),
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
