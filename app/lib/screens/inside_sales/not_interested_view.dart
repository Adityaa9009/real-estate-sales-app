import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../services/database_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class NotInterestedView extends StatelessWidget {
  const NotInterestedView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(
        statusFilter: CustomerStatus.notInterested,
        assignedInsideSalesId: currentUid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.thumb_down_alt_rounded,
            title: 'No Inactive Leads',
            message: 'Customers marked as not interested will appear here with automated courtesy message status.',
          );
        }

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
                      color: AppColors.danger.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.thumb_down_alt_rounded, color: AppColors.danger, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Not Interested Leads (${list.length})',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Re-engage anytime',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final cust = list[index];
                  return CustomerTile(
                    customer: cust,
                    showActions: true,
                    onMarkInterested: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await DatabaseService.updateCustomerStatus(
                        customerId: cust.id,
                        status: CustomerStatus.interested,
                      );
                      await WhatsAppService.sendInterestedMessageByCustomerId(
                        customerId: cust.id,
                        customerName: cust.name,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('${cust.name} moved back to Interested!'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
