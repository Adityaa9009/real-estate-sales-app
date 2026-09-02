import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/whatsapp_service.dart';
import 'assign_visit_screen.dart';
import 'not_interested_screen.dart';

class InterestedScreen extends StatelessWidget {
  const InterestedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F1A),
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF2F9BFF),
            title: const Text('Interested Customers'),
            actions: [
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotInterestedScreen()),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: CustomerService.interestedCustomers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final customers = snapshot.data!;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1A1F2E)),
                    columns: const [
                      DataColumn(label: Text('Customer Name', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Customer Phone', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                    ],
                    rows: customers.map((c) {
                      return DataRow(cells: [
                        DataCell(Text(c.name, style: const TextStyle(color: Colors.white70))),
                        DataCell(Text(c.maskedPhone, style: const TextStyle(color: Colors.white70))),
                        DataCell(Row(children: [
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.greenAccent),
                            onPressed: () => WhatsAppService.sendInterestedMessage(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.event_available, color: Colors.white),
                            onPressed: c.status == 'interested'
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => AssignVisitScreen(customer: c)),
                                    )
                                : null,
                          ),
                        ])),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
