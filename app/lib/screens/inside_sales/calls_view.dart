import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../models/staff_directory.dart';
import '../../services/database_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class CallsView extends StatefulWidget {
  const CallsView({super.key});

  @override
  State<CallsView> createState() => _CallsViewState();
}

class _CallsViewState extends State<CallsView> {
  String _search = '';

  void _handleMarkInterested(Customer customer) {
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
              child: const Icon(Icons.thumb_up_alt_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mark ${customer.name} as Interested',
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
              'Customer has shown interest in the project. The following automated sequence will execute:',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _workflowStep(
              Icons.chat_rounded,
              const Color(0xFF25D366),
              'Step 1: Send WhatsApp Brochure',
              'Dispatch project brochure PDF and formal thank-you note via WhatsApp.',
            ),
            const SizedBox(height: 12),
            _workflowStep(
              Icons.calendar_month_rounded,
              AppColors.secondary,
              'Step 2: Schedule Field Visit',
              'Book an on-site property tour with an assigned Outside Sales representative.',
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
              await DatabaseService.updateCustomerStatus(
                customerId: customer.id,
                status: CustomerStatus.interested,
              );
              await WhatsAppService.sendInterestedMessageByCustomerId(
                customerId: customer.id,
                customerName: customer.name,
              );
              if (mounted) _openScheduleVisitDialog(customer);
            },
            child: Text('Confirm & Trigger Actions', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _workflowStep(IconData icon, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMarkNotInterested(Customer customer) {
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
                color: AppColors.danger.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.thumb_down_alt_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mark as Not Interested',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          'Marking ${customer.name} as Not Interested will log the outcome and automatically dispatch a polite courtesy follow-up message with our contact info.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.updateCustomerStatus(
                customerId: customer.id,
                status: CustomerStatus.notInterested,
              );
              await WhatsAppService.sendNotInterestedMessageByCustomerId(
                customerId: customer.id,
                customerName: customer.name,
              );
            },
            child: Text('Confirm Outcome', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _openScheduleVisitDialog(Customer customer) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 11, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
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
                      'Schedule Site Visit',
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
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time Selector Strip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, MMM d • hh:mm a').format(
                              DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogCtx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (pickedDate != null && dialogCtx.mounted) {
                            final pickedTime = await showTimePicker(
                              context: dialogCtx,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setDialogState(() {
                                selectedDate = pickedDate;
                                selectedTime = pickedTime;
                              });
                            }
                          }
                        },
                        child: Text(
                          'Change Time',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Select Outside Sales Field Representative:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<StaffDirectoryEntry>>(
                  stream: DatabaseService.getStaffDirectoryStream(
                    roleFilter: AppRole.outsideSales,
                    onlyActive: true,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: AppColors.secondary),
                        ),
                      );
                    }

                    final reps = snapshot.data ?? [];
                    if (reps.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No active Outside Sales employees found.',
                          style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reps.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceBorder, height: 1),
                        itemBuilder: (context, index) {
                          final rep = reps[index];
                          final initials = rep.name.trim().isNotEmpty
                              ? rep.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                              : '?';

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.secondary.withAlpha(35),
                                radius: 18,
                                child: Text(
                                  initials,
                                  style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                              title: Text(
                                rep.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Field Rep • Ready',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.success),
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
                                  final fullDateTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );

                                  final messenger = ScaffoldMessenger.of(context);
                                  await DatabaseService.scheduleOutsideSalesVisit(
                                    customerId: customer.id,
                                    customerName: customer.name,
                                    maskedPhone: customer.maskedPhone,
                                    outsideSalesId: rep.id,
                                    outsideSalesName: rep.name,
                                    visitDateTime: fullDateTime,
                                    propertyNotes: customer.propertyNotes,
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.success,
                                      content: Text('Site visit booked with ${rep.name}!'),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Assign',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: SearchBarWidget(
            hintText: 'Search call queue by name or notes...',
            onChanged: (val) => setState(() => _search = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: DatabaseService.getCustomersStream(
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

              final allCustomers = snapshot.data ?? [];
              final filtered = allCustomers.where((c) {
                if (_search.isEmpty) return true;
                return c.name.toLowerCase().contains(_search) ||
                    c.maskedPhone.contains(_search) ||
                    (c.propertyNotes ?? '').toLowerCase().contains(_search);
              }).toList();

              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.support_agent_rounded,
                  title: 'No Pending Calls',
                  message: _search.isNotEmpty
                      ? 'No leads in your queue match the search filter.'
                      : 'You have caught up with all assigned lead calls for today.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final cust = filtered[index];
                  return CustomerTile(
                    customer: cust,
                    showActions: true,
                    onMarkInterested: () => _handleMarkInterested(cust),
                    onMarkNotInterested: () => _handleMarkNotInterested(cust),
                    onScheduleVisit: () => _openScheduleVisitDialog(cust),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
