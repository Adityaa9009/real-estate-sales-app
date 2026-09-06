import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/search_bar_widget.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  String _searchQuery = '';
  CustomerStatus? _selectedStatusFilter;

  void _showAssignDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Assign ${customer.name} to Inside Sales',
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 400,
          child: StreamBuilder<List<Employee>>(
            stream: DatabaseService.getEmployeesStream(
              roleFilter: AppRole.insideSales,
            ),
            builder: (context, snapshot) {
              final insideStaff = snapshot.data ?? [];
              if (insideStaff.isEmpty) {
                return const Text(
                  'No active Inside Sales employees found. Please add or seed staff first.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: insideStaff.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final emp = insideStaff[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 16,
                      child: Icon(
                        Icons.headset_mic_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      emp.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      emp.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        await DatabaseService.assignCustomerToInsideSales(
                          customerId: customer.id,
                          insideSalesId: emp.id,
                          insideSalesName: emp.name,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Assign'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final budgetController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Add New Customer Lead',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget / Property Type',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Preferences',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                return;
              }
              await DatabaseService.addCustomer(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                budget: budgetController.text.trim().isEmpty
                    ? null
                    : budgetController.text.trim(),
                propertyNotes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search customer name, budget, or notes...',
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomerDialog,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Customer'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', null),
                    const SizedBox(width: 8),
                    _chip('Unassigned', CustomerStatus.unassigned),
                    const SizedBox(width: 8),
                    _chip('Assigned', CustomerStatus.assignedToInsideSales),
                    const SizedBox(width: 8),
                    _chip('Interested', CustomerStatus.interested),
                    const SizedBox(width: 8),
                    _chip('Visit Scheduled', CustomerStatus.visitScheduled),
                    const SizedBox(width: 8),
                    _chip('Completed', CustomerStatus.visitCompleted),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: DatabaseService.getCustomersStream(
              statusFilter: _selectedStatusFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final customers = (snapshot.data ?? []).where((c) {
                if (_searchQuery.isEmpty) return true;
                return c.name.toLowerCase().contains(_searchQuery) ||
                    (c.propertyNotes ?? '').toLowerCase().contains(
                      _searchQuery,
                    ) ||
                    (c.budget ?? '').toLowerCase().contains(_searchQuery);
              }).toList();

              if (customers.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No customer leads in this view.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return CustomerTile(
                    customer: customer,
                    showActions: true,
                    onScheduleVisit:
                        customer.status == CustomerStatus.unassigned
                        ? () => _showAssignDialog(customer)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, CustomerStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = status),
      selectedColor: AppColors.primary.withAlpha(50),
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
      ),
    );
  }
}
