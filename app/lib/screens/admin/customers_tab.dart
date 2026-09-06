import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  String _searchQuery = '';
  CustomerStatus? _selectedStatusFilter;
  bool _showChart = true;

  static const Map<CustomerStatus, _StatusMetadata> _statusMetadata = {
    CustomerStatus.unassigned: _StatusMetadata('Unassigned', Color(0xFF8A9099)),
    CustomerStatus.assignedToInsideSales: _StatusMetadata('Assigned', Color(0xFF3D8BFF)),
    CustomerStatus.interested: _StatusMetadata('Interested', Color(0xFF1FA971)),
    CustomerStatus.notInterested: _StatusMetadata('Not Interested', Color(0xFFE0294B)),
    CustomerStatus.visitScheduled: _StatusMetadata('Visit Scheduled', Color(0xFFFFC043)),
    CustomerStatus.visitInProgress: _StatusMetadata('In Progress', Color(0xFF7C5CFC)),
    CustomerStatus.visitCompleted: _StatusMetadata('Completed', Color(0xFF1FA971)),
  };

  void _showAssignDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text(
          'Assign ${customer.name} to Inside Sales',
          style: GoogleFonts.sora(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
                return Text(
                  'No active Inside Sales employees found. Please add or seed staff first.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: insideStaff.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1, color: AppColors.surfaceBorder),
                itemBuilder: (context, index) {
                  final emp = insideStaff[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withAlpha(40),
                      radius: 18,
                      child: const Icon(
                        Icons.headset_mic_rounded,
                        color: AppColors.primaryLight,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      emp.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      emp.phone,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text(
          'Add New Customer Lead',
          style: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(),
      builder: (context, allCustSnapshot) {
        final allCustomers = allCustSnapshot.data ?? [];

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
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _showAddCustomerDialog,
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: Text(
                            'Add Lead',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Collapsible Status Breakdown Chart Card
                  if (allCustomers.isNotEmpty) ...[
                    _buildChartCard(allCustomers),
                    const SizedBox(height: 12),
                  ],

                  // Filter Chips for All 7 Real Enum Values
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('All (${allCustomers.length})', null),
                        const SizedBox(width: 8),
                        ...CustomerStatus.values.map((status) {
                          final count = allCustomers
                              .where((c) => c.status == status)
                              .length;
                          final meta = _statusMetadata[status]!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _chip('${meta.label} ($count)', status),
                          );
                        }),
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
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 4,
                      itemBuilder: (context, index) => const SkeletonListTile(),
                    );
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
                    return EmptyStateWidget(
                      icon: Icons.people_outline_rounded,
                      title: 'No Customers Found',
                      message: _searchQuery.isNotEmpty || _selectedStatusFilter != null
                          ? 'Try adjusting your search query or status filter.'
                          : 'No leads in the database yet. Click "Add Lead" to get started.',
                      actionLabel: _searchQuery.isNotEmpty || _selectedStatusFilter != null
                          ? 'Reset Filters'
                          : null,
                      onAction: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedStatusFilter = null;
                        });
                      },
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
      },
    );
  }

  Widget _buildChartCard(List<Customer> customers) {
    final Map<CustomerStatus, int> counts = {};
    for (final s in CustomerStatus.values) {
      counts[s] = customers.where((c) => c.status == s).length;
    }
    final total = customers.length;

    final nonZeroSlices = CustomerStatus.values
        .where((s) => (counts[s] ?? 0) > 0)
        .map((s) {
          final count = counts[s]!;
          final meta = _statusMetadata[s]!;
          return PieChartSectionData(
            value: count.toDouble(),
            color: meta.color,
            radius: 16,
            showTitle: false,
          );
        })
        .toList();

    return Container(
      decoration: CardStyles.primary(borderRadius: 16),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _showChart = !_showChart),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.donut_large_rounded,
                    size: 16,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status Pipeline Overview ($total)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showChart
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showChart) ...[
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Donut Pie Chart
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: nonZeroSlices.isEmpty
                            ? [
                                PieChartSectionData(
                                  value: 1,
                                  color: AppColors.surfaceLight,
                                  radius: 14,
                                  showTitle: false,
                                ),
                              ]
                            : nonZeroSlices,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend with all 7 statuses
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: CustomerStatus.values.map((status) {
                        final count = counts[status] ?? 0;
                        final meta = _statusMetadata[status]!;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: meta.color,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${meta.label}: ',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '$count',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
      labelStyle: GoogleFonts.inter(
        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _StatusMetadata {
  final String label;
  final Color color;
  const _StatusMetadata(this.label, this.color);
}
