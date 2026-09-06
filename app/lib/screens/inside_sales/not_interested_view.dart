import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../services/database_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/customer_tile.dart';

class NotInterestedView extends StatelessWidget {
  const NotInterestedView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(statusFilter: CustomerStatus.notInterested),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text('No customers marked as Not Interested.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final cust = list[index];
            return CustomerTile(
              customer: cust,
              showActions: true,
              onMarkInterested: () async {
                await DatabaseService.updateCustomerStatus(
                  customerId: cust.id,
                  status: CustomerStatus.interested,
                );
                await WhatsAppService.sendInterestedMessage(
                  customerName: cust.name,
                  customerPhone: cust.phone,
                );
              },
            );
          },
        );
      },
    );
  }
}
