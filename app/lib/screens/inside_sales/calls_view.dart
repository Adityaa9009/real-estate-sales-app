import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/customer_tile.dart';

class CallsView extends StatefulWidget {
  const CallsView({super.key});

  @override
  State<CallsView> createState() => _CallsViewState();
}

class _CallsViewState extends State<CallsView> {
  void _handleMarkInterested(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Row(
          children: [
            const Icon(Icons.thumb_up_alt_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Text('Mark ${customer.name} as Interested', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer has shown interest! Next steps (PDF Page 7):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '1. Send WhatsApp message with property brochure and thank you note.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '2. Schedule site visit with an Outside Sales employee.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              // 1. Update status
              await DatabaseService.updateCustomerStatus(
                customerId: customer.id,
                status: CustomerStatus.interested,
              );
              // 2. Trigger WhatsApp
              await WhatsAppService.sendInterestedMessage(
                customerName: customer.name,
                customerPhone: customer.phone,
              );
              // 3. Open schedule dialog
              if (mounted) _openScheduleVisitDialog(customer);
            },
            child: const Text('Confirm & Send WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _handleMarkNotInterested(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Row(
          children: [
            const Icon(Icons.thumb_down_alt_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text('Mark ${customer.name} as Not Interested', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Marking as Not Interested will send a polite follow-up WhatsApp message thanking them for their time and providing our contact details (PDF Page 7).',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.updateCustomerStatus(
                customerId: customer.id,
                status: CustomerStatus.notInterested,
              );
              await WhatsAppService.sendNotInterestedMessage(
                customerName: customer.name,
                customerPhone: customer.phone,
              );
            },
            child: const Text('Mark & Send WhatsApp'),
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
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Text('Schedule Visit for ${customer.name}', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Outside Sales representative and appointment time:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                StreamBuilder<List<Employee>>(
                  stream: DatabaseService.getEmployeesStream(roleFilter: AppRole.outsideSales),
                  builder: (context, snapshot) {
                    final reps = snapshot.data ?? [];
                    if (reps.isEmpty) {
                      return const Text('No active Outside Sales employees found.', style: TextStyle(color: AppColors.danger));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reps.map((rep) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.success,
                            radius: 16,
                            child: Icon(Icons.directions_walk_rounded, color: Colors.white, size: 16),
                          ),
                          title: Text(rep.name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          subtitle: Text(rep.phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, visualDensity: VisualDensity.compact),
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
                                customerPhone: customer.phone,
                                outsideSalesId: rep.id,
                                outsideSalesName: rep.name,
                                visitDateTime: fullDateTime,
                                propertyNotes: customer.propertyNotes,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Site visit scheduled with ${rep.name}!'),
                                ),
                              );
                            },
                            child: const Text('Schedule'),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = snapshot.data ?? [];
        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.support_agent_rounded, size: 54, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No leads assigned to call.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => DatabaseService.seedDemoData(),
                  child: const Text('Seed Sample Leads'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final cust = customers[index];
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
    );
  }
}
