import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class InterestedView extends StatelessWidget {
  const InterestedView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(
        statusFilter: CustomerStatus.interested,
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

        final interested = snapshot.data ?? [];
        if (interested.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.thumb_up_alt_outlined,
            title: 'No Interested Leads Yet',
            message: 'When you qualify leads as Interested during calls, they will appear here ready for field visit scheduling.',
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
                      color: AppColors.success.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.thumb_up_alt_rounded, color: AppColors.success, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Qualified Interested Leads (${interested.length})',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Next: Assign Site Visit',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryLight),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: interested.length,
                itemBuilder: (context, index) {
                  final cust = interested[index];
                  return CustomerTile(
                    customer: cust,
                    showActions: true,
                    onScheduleVisit: () => _showScheduleModal(context, cust),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showScheduleModal(BuildContext context, Customer customer) {
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
                color: AppColors.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Site Visit',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    customer.name,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: StreamBuilder<List<Employee>>(
            stream: DatabaseService.getEmployeesStream(
              roleFilter: AppRole.outsideSales,
              onlyActive: true,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                );
              }

              final outsideStaff = snapshot.data ?? [];
              if (outsideStaff.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No active Outside Sales staff available.',
                    style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: outsideStaff.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceBorder, height: 1),
                  itemBuilder: (context, index) {
                    final rep = outsideStaff[index];
                    final initials = rep.name.trim().isNotEmpty
                        ? rep.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                        : '?';

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.secondary.withAlpha(35),
                          child: Text(
                            initials,
                            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                          ),
                        ),
                        title: Text(
                          rep.name,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          'Outside Sales Representative',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final time = DateTime.now().add(const Duration(hours: 4));
                            final messenger = ScaffoldMessenger.of(context);
                            await DatabaseService.scheduleOutsideSalesVisit(
                              customerId: customer.id,
                              customerName: customer.name,
                              maskedPhone: customer.maskedPhone,
                              outsideSalesId: rep.id,
                              outsideSalesName: rep.name,
                              visitDateTime: time,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('Visit assigned to ${rep.name}!'),
                              ),
                            );
                          },
                          child: Text('Assign', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
