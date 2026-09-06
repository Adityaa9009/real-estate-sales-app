import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../widgets/role_badge.dart';
import '../../widgets/search_bar_widget.dart';

class EmployeesTab extends StatefulWidget {
  const EmployeesTab({super.key});

  @override
  State<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab> {
  String _searchQuery = '';
  AppRole? _selectedRoleFilter;

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    AppRole selectedRole = AppRole.insideSales;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('Add New Employee', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 14),
                const Text('Employee Position / Role', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<AppRole>(
                  initialValue: selectedRole,
                  dropdownColor: AppColors.surfaceCard,
                  items: AppRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;
                final id = 'emp_${DateTime.now().millisecondsSinceEpoch}';
                await DatabaseService.addEmployee(
                  id: id,
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  role: selectedRole,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Employee'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls: Search + Filter tabs
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search employees by name, email, or role...',
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddEmployeeDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add Employee'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Role Filter Chips
              Row(
                children: [
                  _filterChip(label: 'All Employees', role: null),
                  const SizedBox(width: 8),
                  _filterChip(label: 'Inside Sales', role: AppRole.insideSales),
                  const SizedBox(width: 8),
                  _filterChip(label: 'Outside Sales', role: AppRole.outsideSales),
                  const SizedBox(width: 8),
                  _filterChip(label: 'Executive', role: AppRole.executive),
                ],
              ),
            ],
          ),
        ),

        // Stream list of employees
        Expanded(
          child: StreamBuilder<List<Employee>>(
            stream: DatabaseService.getEmployeesStream(roleFilter: _selectedRoleFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final employees = (snapshot.data ?? []).where((e) {
                if (_searchQuery.isEmpty) return true;
                return e.name.toLowerCase().contains(_searchQuery) ||
                    e.email.toLowerCase().contains(_searchQuery) ||
                    e.role.label.toLowerCase().contains(_searchQuery);
              }).toList();

              if (employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('No employees found.', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => DatabaseService.seedDemoData(),
                        child: const Text('Seed Sample Employees'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: emp.role.color.withAlpha(40),
                          child: Icon(emp.role.icon, color: emp.role.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${emp.email}  •  ${emp.phone}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        RoleBadge(role: emp.role),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                          tooltip: 'Remove',
                          onPressed: () => DatabaseService.deleteEmployee(emp.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip({required String label, required AppRole? role}) {
    final isSelected = _selectedRoleFilter == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedRoleFilter = role),
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
