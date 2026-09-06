import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../widgets/empty_state_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class VisitsView extends StatefulWidget {
  const VisitsView({super.key});

  @override
  State<VisitsView> createState() => _VisitsViewState();
}

class _VisitsViewState extends State<VisitsView> {
  final AudioRecordingService _audioService = AudioRecordingService();
  bool _isStorageAvailable = false;
  String _search = '';
  VisitStatus? _statusFilter;

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verifying Cloud Storage...',
                  style: GoogleFonts.inter(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cloud Storage Required',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          result.isUnauthorized
              ? 'Your account is currently unauthorized to access Cloud Storage for this visit. Please verify your field assignment and active status.'
              : 'Site audio recordings and verification selfies are stored securely in Firebase Cloud Storage. '
                  'Cloud Storage requires active project configuration and bucket provisioning.\n\n'
                  'Once Firebase Cloud Storage is set up, site audio recording and customer selfie verification '
                  'will be fully operational.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final uri = Uri.parse('https://firebase.google.com/pricing');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text('Storage Documentation', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _onReachedLocationTapped(Visit visit) async {
    final check = await _ensureStorageAvailable(visitId: visit.id);
    if (!check.isReady) return;

    final hasMic = await _audioService.hasPermission();
    if (!hasMic) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Microphone permission is required to record visit audio.'),
          ),
        );
      }
      return;
    }

    try {
      await _audioService.startRecording(visit.id);
      await DatabaseService.reachVisit(
        visitId: visit.id,
        customerId: visit.customerId,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Reached location confirmed! Audio recording started for this visit.'),
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

    final storagePath = 'visits/${visit.id}/selfies/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      await ref.delete().catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to save selfie metadata: $firestoreError. Upload was rolled back.'),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete Site Visit',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finalize the customer visit. Visit audio recording will be uploaded and verified before completion.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Visit Notes & Client Feedback',
                hintText: 'Customer feedback, budget confirmation, or next steps...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processVisitCompletion(visit, notesController.text.trim());
            },
            child: Text('Complete Visit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _processVisitCompletion(Visit visit, String notes) async {
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
            content: Text('Audio recording is required to complete this visit. Please record the visit audio before completing.'),
          ),
        );
      }
      return;
    }

    final audioStoragePath = 'visits/${visit.id}/audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
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
      await audioRef.delete().catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to save visit audio metadata: $firestoreError. Completion aborted and upload rolled back.'),
          ),
        );
      }
      return;
    }

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

    return Column(
      children: [
        // Storage Status notification strip if storage unconfigured
        if (!_isStorageAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.warning.withAlpha(25),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cloud Storage setup required for media recording & selfies',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => _ensureStorageAvailable(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Check Status', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryLight)),
                ),
              ],
            ),
          ),

        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBarWidget(
                hintText: 'Search visits by customer name or notes...',
                onChanged: (val) => setState(() => _search = val.toLowerCase()),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All Visits', _statusFilter == null, () => setState(() => _statusFilter = null)),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Scheduled',
                      _statusFilter == VisitStatus.visitScheduled,
                      () => setState(() => _statusFilter = VisitStatus.visitScheduled),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'In Progress',
                      _statusFilter == VisitStatus.visitInProgress,
                      () => setState(() => _statusFilter = VisitStatus.visitInProgress),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Completed',
                      _statusFilter == VisitStatus.visitCompleted,
                      () => setState(() => _statusFilter = VisitStatus.visitCompleted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Visits List Stream
        Expanded(
          child: StreamBuilder<List<Visit>>(
            stream: DatabaseService.getVisitsStream(outsideSalesId: currentUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (context, index) => const SkeletonListTile(),
                );
              }

              final allVisits = snapshot.data ?? [];
              final filtered = allVisits.where((v) {
                if (_statusFilter != null && v.status != _statusFilter) return false;
                if (_search.isEmpty) return true;
                return v.customerName.toLowerCase().contains(_search) ||
                    v.maskedPhone.contains(_search) ||
                    (v.notes ?? '').toLowerCase().contains(_search);
              }).toList();

              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'No Visits Found',
                  message: _search.isNotEmpty || _statusFilter != null
                      ? 'No customer visits match the selected filter.'
                      : 'You do not have any on-site customer visits assigned currently.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final v = filtered[index];
                  final isCurrentRecording =
                      _audioService.isRecording && _audioService.currentVisitId == v.id;
                  final initials = v.customerName.trim().isNotEmpty
                      ? v.customerName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withAlpha(35),
                                child: Text(
                                  initials,
                                  style: GoogleFonts.sora(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          v.customerName,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildVisitStatusPill(v.status),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          v.maskedPhone,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.info),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateFormat.format(v.scheduledAt),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.info,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.call_rounded, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withAlpha(35),
                                  foregroundColor: AppColors.primaryLight,
                                ),
                                tooltip: 'Call Customer Confirmation',
                                onPressed: () async {
                                  final res = await CallService.callCustomerById(v.customerId);
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
                          if (v.notes != null && v.notes!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight.withAlpha(100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Notes: ${v.notes}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                          if (isCurrentRecording) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.danger.withAlpha(90)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.mic, size: 16, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Audio recording in progress for this visit...',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.surfaceBorder, height: 1),
                          const SizedBox(height: 14),

                          // Action Buttons with Lock Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _wrapWithLockBadge(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on_rounded, size: 15),
                                  label: Text(
                                    v.status == VisitStatus.visitInProgress ? 'In Progress' : 'Reached Location',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: v.status == VisitStatus.visitInProgress
                                        ? AppColors.warning
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: !_isStorageAvailable
                                      ? () => _onReachedLocationTapped(v)
                                      : (v.status == VisitStatus.visitScheduled
                                          ? () => _onReachedLocationTapped(v)
                                          : null),
                                ),
                              ),
                              _wrapWithLockBadge(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.camera_alt_rounded, size: 15),
                                  label: Text(
                                    'Upload Selfie',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.info,
                                    side: BorderSide(color: AppColors.info.withAlpha(120)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: !_isStorageAvailable
                                      ? () => _onUploadSelfieTapped(v)
                                      : (v.status == VisitStatus.visitInProgress
                                          ? () => _onUploadSelfieTapped(v)
                                          : null),
                                ),
                              ),
                              _wrapWithLockBadge(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle_rounded, size: 15),
                                  label: Text(
                                    'Completed Visit',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onSelected) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.success.withAlpha(40) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitStatusPill(VisitStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case VisitStatus.visitScheduled:
        bg = AppColors.info.withAlpha(30);
        fg = AppColors.info;
        label = 'SCHEDULED';
        break;
      case VisitStatus.visitInProgress:
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
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
