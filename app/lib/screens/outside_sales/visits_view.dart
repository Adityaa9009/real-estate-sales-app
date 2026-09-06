import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../models/visit.dart';
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
  bool _isStorageAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStorage();
  }

  Future<void> _checkInitialStorage() async {
    final available = await StorageAvailabilityService.isStorageAvailable();
    if (mounted) {
      setState(() {
        _isStorageAvailable = available;
      });
    }
  }

  Future<bool> _ensureStorageAvailable() async {
    // Show a loading spinner briefly while checking
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

    final available = await StorageAvailabilityService.isStorageAvailable(
      forceRefresh: true,
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isStorageAvailable = available;
      });
    }

    if (!available && mounted) {
      _showStorageRequiredDialog();
    }

    return available;
  }

  void _showStorageRequiredDialog() {
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
        content: const Text(
          'Visit recordings and verification selfies are stored securely in '
          'Firebase Cloud Storage. This project\'s Firebase Storage has not been '
          'enabled yet — it requires upgrading to the Blaze (pay-as-you-go) billing plan.\n\n'
          'This feature is fully built and will work as soon as Storage is enabled. '
          'No charges apply unless usage exceeds Firebase\'s generous free quota.',
          style: TextStyle(
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
            child: const Text('View Setup Instructions'),
          ),
        ],
      ),
    );
  }

  void _onReachedLocationTapped(Visit visit) async {
    final storageOk = await _ensureStorageAvailable();
    if (!storageOk) return;

    _handleReachedLocation(visit);
  }

  void _handleReachedLocation(Visit visit) async {
    try {
      await DatabaseService.reachVisit(
        visitId: visit.id,
        customerId: visit.customerId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Reached location confirmed! Visit status marked in-progress.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to update visit: $e'),
          ),
        );
      }
    }
  }

  void _onUploadSelfieTapped(Visit visit) async {
    final storageOk = await _ensureStorageAvailable();
    if (!storageOk) return;

    _handleUploadSelfie(visit);
  }

  void _handleUploadSelfie(Visit visit) async {
    final path = await MediaService.captureVerificationPhoto();
    if (path == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.info,
        content: Text('Uploading verification selfie to Cloud Storage...'),
      ),
    );

    try {
      final file = File(path);
      final ref = FirebaseStorage.instance.ref(
        'visits/${visit.id}/selfies/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Store in /visits/{visitId}/private/media subcollection per firestore.rules
      await FirebaseFirestore.instance
          .collection('visits')
          .doc(visit.id)
          .collection('private')
          .doc('media')
          .set({
            'selfieUrl': downloadUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Verification selfie uploaded successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to upload selfie: $e'),
          ),
        );
      }
    }
  }

  void _onCompletedVisitTapped(Visit visit) async {
    final storageOk = await _ensureStorageAvailable();
    if (!storageOk) return;

    _handleCompletedVisit(visit);
  }

  void _handleCompletedVisit(Visit visit) {
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
              'Confirm that the customer site visit has finished. Enter any visit notes below:',
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
              try {
                await DatabaseService.completeVisit(
                  visitId: visit.id,
                  customerId: visit.customerId,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Visit marked completed successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Error: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Complete Visit'),
          ),
        ],
      ),
    );
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
