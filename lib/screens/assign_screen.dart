import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../repository/executive_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_header.dart';

class AssignScreen extends StatefulWidget {
  final ExecutiveRepository repository;
  final String currentExecutiveId;

  const AssignScreen({
    super.key,
    required this.repository,
    required this.currentExecutiveId,
  });

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  List<Customer> _customers = [];
  List<Employee> _insideSales = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _showAssigned = false; // toggle: Assigned Employees

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customers = await widget.repository.getAllCustomers();
    final employees = await widget.repository.getAllEmployees();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _insideSales =
          employees.where((e) => e.role == 'inside_sales').toList();
      _loading = false;
    });
  }

  List<Customer> get _displayedCustomers {
    if (_showAssigned) {
      return _customers
          .where((c) => c.assignedInsideSalesId != null)
          .toList();
    }
    return _customers;
  }

  Future<void> _assignSelected() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one customer')),
      );
      return;
    }
    if (_insideSales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inside sales employees available')),
      );
      return;
    }

    // Show dialog to pick which inside sales employee to assign to
    final chosen = await showDialog<Employee>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Assign to Inside Sales',
            style: TextStyle(color: AppColors.accentOrange)),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _insideSales.length,
            itemBuilder: (_, i) {
              final emp = _insideSales[i];
              return ListTile(
                title: Text(emp.name,
                    style:
                        const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(emp.email,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                onTap: () => Navigator.pop(context, emp),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );

    if (chosen == null) return;

    try {
      for (final customerId in _selected) {
        await widget.repository.assignCustomerToInsideSales(
          customerId: customerId,
          insideSalesId: chosen.id,
          assignedByExecutiveId: widget.currentExecutiveId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_selected.length} customer(s) assigned to ${chosen.name}')),
      );
      _selected.clear();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment failed: $e')),
      );
    }
  }

  Future<void> _delete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Customer',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove ${customer.name}?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.repository.deleteCustomer(customer.id);
    _selected.remove(customer.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedCustomers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardHeader(
          title: 'Assign Screen',
          onAddPressed: _selected.isEmpty ? null : _assignSelected,
        ),
        // Toggle pill
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _showAssigned = !_showAssigned),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _showAssigned
                      ? AppColors.accentOrange
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Assigned Employees',
                  style: TextStyle(
                    color: _showAssigned
                        ? Colors.black
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ElevatedButton.icon(
              onPressed: _assignSelected,
              icon: const Icon(Icons.assignment_ind, size: 18),
              label: Text('Assign ${_selected.length} selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentOrange))
              : displayed.isEmpty
                  ? Center(
                      child: Text(
                        _showAssigned
                            ? 'No assigned customers yet'
                            : 'No customers yet',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: displayed.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final c = displayed[index];
                        final isChecked = _selected.contains(c.id);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppColors.accentOrange.withOpacity(0.15)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: isChecked
                                ? Border.all(
                                    color: AppColors.accentOrange,
                                    width: 1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer Name: ${c.name}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Customer ID: ${c.id}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (c.assignedInsideSalesId != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Assigned ✓',
                                          style: TextStyle(
                                            color: Colors.green[400],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.accentOrange,
                                checkColor: Colors.black,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selected.add(c.id);
                                    } else {
                                      _selected.remove(c.id);
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                onPressed: () => _delete(c),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
