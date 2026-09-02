import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/whatsapp_service.dart';

class NotInterestedScreen extends StatelessWidget {
  const NotInterestedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F9BFF),
        title: const Text('Not Interested Customers'),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: CustomerService.notInterestedCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customers = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1F2E)),
              columns: const [
                DataColumn(label: Text('Customer Name', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Customer Phone', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
              ],
              rows: customers.map((c) {
                return DataRow(cells: [
                  DataCell(Text(c.name, style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(c.maskedPhone, style: const TextStyle(color: Colors.white70))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.chat, color: Colors.greenAccent),
                    onPressed: () => WhatsAppService.sendNotInterestedMessage(c),
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
