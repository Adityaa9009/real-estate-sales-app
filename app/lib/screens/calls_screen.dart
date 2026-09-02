import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/customer_call_tile.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F1A),
      child: StreamBuilder<List<Customer>>(
        stream: CustomerService.assignedForCalling(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customers = snapshot.data!;
          if (customers.isEmpty) {
            return const Center(
              child: Text('No customers to call', style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return CustomerCallTile(
                customer: customer,
                onInterested: () => CustomerService.markInterested(customer.id),
                onNotInterested: () => CustomerService.markNotInterested(customer.id),
              );
            },
          );
        },
      ),
    );
  }
}
