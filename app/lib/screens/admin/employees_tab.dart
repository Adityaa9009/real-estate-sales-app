import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/role_badge.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/skeleton_shimmer.dart';

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          title: Text(
            'Add New Employee',
            style: GoogleFonts.sora(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
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
                            style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'PERSONAL DETAILS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SECURITY & CONTACT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password (min. 6 characters)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primaryLight),
                    fillColor: AppColors.primary.withAlpha(10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withAlpha(80)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
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
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ORGANIZATIONAL ROLE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AppRole>(
                  initialValue: selectedRole,
                  dropdownColor: AppColors.surfaceCard,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                  items: AppRole.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.label,
                            style: GoogleFonts.inter(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
                      onPressed: _showAddEmployeeDialog,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(
                        'Add Staff',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(label: 'All Staff', role: null),
                    const SizedBox(width: 8),
                    _filterChip(label: 'Inside Sales', role: AppRole.insideSales),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Outside Sales',
                      role: AppRole.outsideSales,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(label: 'Executive', role: AppRole.executive),
                    const SizedBox(width: 8),
                    _filterChip(label: 'Admin', role: AppRole.admin),
                  ],
                ),
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
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (context, index) => const SkeletonListTile(),
                );
              }

              final employees = (snapshot.data ?? []).where((e) {
                if (_searchQuery.isEmpty) return true;
                return e.name.toLowerCase().contains(_searchQuery) ||
                    e.email.toLowerCase().contains(_searchQuery) ||
                    e.role.label.toLowerCase().contains(_searchQuery);
              }).toList();

              if (employees.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: 'No Staff Found',
                  message: _searchQuery.isNotEmpty || _selectedRoleFilter != null
                      ? 'No staff members match the selected search or filter.'
                      : 'No employees registered yet. Click "Add Staff" to create an account.',
                  actionLabel: _searchQuery.isNotEmpty || _selectedRoleFilter != null
                      ? 'Reset Filters'
                      : null,
                  onAction: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedRoleFilter = null;
                    });
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: CardStyles.secondary(borderRadius: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: emp.role.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: emp.role.color.withAlpha(70)),
                            boxShadow: [
                              BoxShadow(
                                color: emp.role.color.withAlpha(35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
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
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_rounded,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      emp.email,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (emp.phone.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.phone_rounded,
                                      size: 12,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      emp.phone,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
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
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: emp.active
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            emp.active
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            color: emp.active
                                ? AppColors.danger
                                : AppColors.success,
                            size: 18,
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
