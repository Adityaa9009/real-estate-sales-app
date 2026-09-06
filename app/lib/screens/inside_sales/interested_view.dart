import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../widgets/customer_tile.dart';

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
        final interested = snapshot.data ?? [];
        if (interested.isEmpty) {
          return const Center(
            child: Text(
              'No customers currently tagged as Interested.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
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
        );
      },
    );
  }

  void _showScheduleModal(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Assign Site Visit: ${customer.name}',
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        content: StreamBuilder<List<Employee>>(
          stream: DatabaseService.getEmployeesStream(
            roleFilter: AppRole.outsideSales,
            onlyActive: true,
          ),
          builder: (context, snapshot) {
            final outsideStaff = snapshot.data ?? [];
            if (outsideStaff.isEmpty) {
              return const Text('No Outside Sales staff found.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: outsideStaff.map((rep) {
                return ListTile(
                  title: Text(
                    rep.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Field Representative',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    onPressed: () async {
                      final time = DateTime.now().add(const Duration(hours: 4));
                      await DatabaseService.scheduleOutsideSalesVisit(
                        customerId: customer.id,
                        customerName: customer.name,
                        maskedPhone: customer.maskedPhone,
                        outsideSalesId: rep.id,
                        outsideSalesName: rep.name,
                        visitDateTime: time,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Assign Visit'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
