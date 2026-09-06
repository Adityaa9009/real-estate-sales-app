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
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    AppRole selectedRole = AppRole.insideSales;
    bool obscurePassword = true;
    String? validationError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text(
            'Add New Employee',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (validationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            validationError!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password (min. 6 characters)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Employee Position / Role',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<AppRole>(
                  initialValue: selectedRole,
                  dropdownColor: AppColors.surfaceCard,
                  items: AppRole.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        setDialogState(() => validationError = 'Full name is required.');
                        return;
                      }
                      if (emailController.text.trim().isEmpty) {
                        setDialogState(() => validationError = 'Email address is required.');
                        return;
                      }
                      if (passwordController.text.trim().length < 6) {
                        setDialogState(() => validationError = 'Password must be at least 6 characters long.');
                        return;
                      }
                      setDialogState(() {
                        validationError = null;
                        isSubmitting = true;
                      });
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await DatabaseService.registerNewEmployee(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          phone: phoneController.text.trim(),
                          role: selectedRole,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Employee registered successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          validationError = e.toString().replaceAll('Exception: ', '');
                          isSubmitting = false;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Employee'),
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
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddEmployeeDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add Employee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
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
                  _filterChip(
                    label: 'Outside Sales',
                    role: AppRole.outsideSales,
                  ),
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
            stream: DatabaseService.getEmployeesStream(
              roleFilter: _selectedRoleFilter,
            ),
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
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No employees found.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                          child: Icon(
                            emp.role.icon,
                            color: emp.role.color,
                            size: 20,
                          ),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RoleBadge(role: emp.role),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: emp.active
                                ? AppColors.success.withAlpha(25)
                                : AppColors.danger.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: emp.active
                                  ? AppColors.success.withAlpha(80)
                                  : AppColors.danger.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            emp.active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: emp.active
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(
                            emp.active
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            color: emp.active
                                ? AppColors.danger
                                : AppColors.success,
                            size: 20,
                          ),
                          tooltip: emp.active ? 'Deactivate' : 'Reactivate',
                          onPressed: () async {
                            if (emp.active) {
                              await DatabaseService.deactivateEmployee(emp.id);
                            } else {
                              await DatabaseService.reactivateEmployee(emp.id);
                            }
                          },
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
