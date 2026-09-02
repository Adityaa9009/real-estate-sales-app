import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer_assignment.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../services/customer_service.dart';

class AssignedOutsideEmployeesScreen extends StatefulWidget {
  const AssignedOutsideEmployeesScreen({super.key});

  @override
  State<AssignedOutsideEmployeesScreen> createState() => _AssignedOutsideEmployeesScreenState();
}

class _AssignedOutsideEmployeesScreenState extends State<AssignedOutsideEmployeesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F1A),
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF2F9BFF),
            title: const Text('Details'),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Employees',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1F2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CustomerAssignment>>(
              stream: CustomerService.myOutsideAssignments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final grouped = <String, List<CustomerAssignment>>{};
                for (final a in snapshot.data!) {
                  grouped.putIfAbsent(a.outsideSalesId!, () => []).add(a);
                }
                final entries = grouped.entries.toList();
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final outsideEmployeeId = entries[index].key;
                    final assignments = entries[index].value;
                    return _EmployeeGroupTile(
                      outsideEmployeeId: outsideEmployeeId,
                      assignments: assignments,
                      query: _query,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeGroupTile extends StatelessWidget {
  final String outsideEmployeeId;
  final List<CustomerAssignment> assignments;
  final String query;

  const _EmployeeGroupTile({
    required this.outsideEmployeeId,
    required this.assignments,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Employee>(
      future: CustomerService.getEmployee(outsideEmployeeId),
      builder: (context, empSnap) {
        if (!empSnap.hasData) return const SizedBox.shrink();
        final employee = empSnap.data!;
        if (query.isNotEmpty && !employee.name.toLowerCase().contains(query)) {
          return const SizedBox.shrink();
        }
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            collapsedBackgroundColor: const Color(0xFF1A1F2E),
            backgroundColor: const Color(0xFF1A1F2E),
            title: Text('Employee: ${employee.name}', style: const TextStyle(color: Colors.white)),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              FutureBuilder<List<Customer>>(
                future: Future.wait(assignments.map((a) => CustomerService.getCustomer(a.customerId))),
                builder: (context, custSnap) {
                  if (!custSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }
                  final customers = custSnap.data!;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Customer Name', style: TextStyle(color: Colors.white))),
                        DataColumn(label: Text('Customer Phone', style: TextStyle(color: Colors.white))),
                        DataColumn(label: Text('Event Time', style: TextStyle(color: Colors.white))),
                      ],
                      rows: List.generate(assignments.length, (i) {
                        final visitTime = assignments[i].visitScheduledAt;
                        final formatted = visitTime != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(visitTime.toDate())
                            : '-';
                        return DataRow(cells: [
                          DataCell(Text(customers[i].name, style: const TextStyle(color: Colors.white70))),
                          DataCell(Text(customers[i].maskedPhone, style: const TextStyle(color: Colors.white70))),
                          DataCell(Text(formatted, style: const TextStyle(color: Colors.white70))),
                        ]);
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
