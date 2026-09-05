import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/role_badge.dart';
import '../../widgets/search_bar_widget.dart';
import '../login_screen.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() => _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  int _selectedSidebarIndex = 0; // 0: Add Emp, 1: Add Cust, 2: All Emp, 3: All Cust / Assign

  void _handleLogout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.manage_accounts_rounded, color: AppColors.secondary, size: 24),
            SizedBox(width: 10),
            Text('Executive Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Sidebar (PDF Page 5: Add Employee, Add Customer, All Employees, All Customer, Settings, Logout)
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _sidebarItem(0, Icons.person_add_rounded, 'Add Employee'),
                _sidebarItem(1, Icons.group_add_rounded, 'Add Customer'),
                _sidebarItem(2, Icons.badge_rounded, 'All Employees'),
                _sidebarItem(3, Icons.assignment_ind_rounded, 'Assign Customers'),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.textMuted, size: 20),
                  title: const Text('Settings', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Executive system settings configured.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                  title: const Text('Logout', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),

          // Main View
          Expanded(
            child: IndexedStack(
              index: _selectedSidebarIndex,
              children: [
                _buildAddEmployeeView(),
                _buildAddCustomerView(),
                _buildAllEmployeesView(),
                _buildAssignCustomersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedSidebarIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary.withAlpha(40) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppColors.secondary.withAlpha(100)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.secondary : AppColors.textSecondary, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () => setState(() => _selectedSidebarIndex = index),
      ),
    );
  }

  // ================= 1. ADD EMPLOYEE VIEW (PDF Page 5) =================
  final _empNameCtrl = TextEditingController();
  final _empEmailCtrl = TextEditingController();
  final _empPassCtrl = TextEditingController();
  final _empPhoneCtrl = TextEditingController();
  final _empDobCtrl = TextEditingController(text: '1998-05-15');
  AppRole _empRole = AppRole.insideSales;
  bool _savingEmp = false;

  Widget _buildAddEmployeeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Employee',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Register an Inside Sales, Outside Sales, or Executive staff member.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _empNameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Sudheer Kumar'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _empEmailCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Email', hintText: 'e.g. sudheer@company.com'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _empPassCtrl,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Password', hintText: '••••••••'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _empPhoneCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Phone', hintText: 'e.g. 9899001122'),
            ),
            const SizedBox(height: 16),
            const Text('Sales Position / Role', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<AppRole>(
              initialValue: _empRole,
              dropdownColor: AppColors.surfaceCard,
              items: const [
                DropdownMenuItem(value: AppRole.insideSales, child: Text('Inside Sales')),
                DropdownMenuItem(value: AppRole.outsideSales, child: Text('Outside Sales')),
                DropdownMenuItem(value: AppRole.executive, child: Text('Executive')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _empRole = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _empDobCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Date of Birth (DOB)', hintText: 'YYYY-MM-DD'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingEmp ? null : _saveEmployee,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                child: _savingEmp
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit & Create Employee', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (_empNameCtrl.text.trim().isEmpty || _empEmailCtrl.text.trim().isEmpty) return;
    setState(() => _savingEmp = true);
    try {
      final id = 'emp_${DateTime.now().millisecondsSinceEpoch}';
      await DatabaseService.addEmployee(
        id: id,
        name: _empNameCtrl.text.trim(),
        email: _empEmailCtrl.text.trim(),
        phone: _empPhoneCtrl.text.trim(),
        role: _empRole,
        dob: _empDobCtrl.text.trim(),
      );
      _empNameCtrl.clear();
      _empEmailCtrl.clear();
      _empPassCtrl.clear();
      _empPhoneCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.success, content: Text('Employee added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _savingEmp = false);
    }
  }

  // ================= 2. ADD CUSTOMER & EXCEL (PDF Page 5) =================
  final _custNameCtrl = TextEditingController();
  final _custEmailCtrl = TextEditingController();
  final _custPhoneCtrl = TextEditingController();
  bool _savingCust = false;

  Widget _buildAddCustomerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Customer Lead',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a single customer lead or bulk import leads via Excel file.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _custNameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Customer Name', hintText: 'e.g. Ramesh Chandra'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _custEmailCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Email Address', hintText: 'e.g. ramesh@example.com'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _custPhoneCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. 9811223344'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingCust ? null : _saveCustomer,
                child: _savingCust
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Customer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: AppColors.textMuted))),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            // Upload Excel Button (PDF Page 5)
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _simulateExcelUpload,
                icon: const Icon(Icons.table_view_rounded, color: AppColors.success),
                label: const Text('Upload Excel (.xlsx / .csv)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (_custNameCtrl.text.trim().isEmpty || _custPhoneCtrl.text.trim().isEmpty) return;
    setState(() => _savingCust = true);
    try {
      await DatabaseService.addCustomer(
        name: _custNameCtrl.text.trim(),
        phone: _custPhoneCtrl.text.trim(),
        email: _custEmailCtrl.text.trim().isEmpty ? null : _custEmailCtrl.text.trim(),
      );
      _custNameCtrl.clear();
      _custEmailCtrl.clear();
      _custPhoneCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.success, content: Text('Customer added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _savingCust = false);
    }
  }

  void _simulateExcelUpload() async {
    // Bulk imports 3 customer leads from simulated Excel sheet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Parsing customers.xlsx and importing leads...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    final excelCustomers = [
      {'name': 'Vikram Malhotra', 'phone': '9811442200', 'budget': '3.0 Cr', 'notes': 'Imported from Excel campaign'},
      {'name': 'Deepak Singhania', 'phone': '9899331122', 'budget': '1.7 Cr', 'notes': 'Imported from Excel campaign'},
      {'name': 'Ananya Roy', 'phone': '9711665544', 'budget': '85 Lakhs', 'notes': 'Imported from Excel campaign'},
    ];

    for (var c in excelCustomers) {
      await DatabaseService.addCustomer(
        name: c['name']!,
        phone: c['phone']!,
        budget: c['budget'],
        propertyNotes: c['notes'],
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Successfully imported 3 customer leads from Excel sheet!'),
      ),
    );
  }

  // ================= 3. ALL EMPLOYEES DIRECTORY (PDF Page 6) =================
  String _empSearch = '';
  AppRole? _empFilter;

  Widget _buildAllEmployeesView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: SearchBarWidget(
                  hintText: 'Search employees...',
                  onChanged: (val) => setState(() => _empSearch = val.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('All'),
                selected: _empFilter == null,
                onSelected: (_) => setState(() => _empFilter = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Inside Sales'),
                selected: _empFilter == AppRole.insideSales,
                onSelected: (_) => setState(() => _empFilter = AppRole.insideSales),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Outside Sales'),
                selected: _empFilter == AppRole.outsideSales,
                onSelected: (_) => setState(() => _empFilter = AppRole.outsideSales),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Employee>>(
            stream: DatabaseService.getEmployeesStream(roleFilter: _empFilter),
            builder: (context, snapshot) {
              final emps = (snapshot.data ?? []).where((e) {
                if (_empSearch.isEmpty) return true;
                return e.name.toLowerCase().contains(_empSearch) || e.email.toLowerCase().contains(_empSearch);
              }).toList();

              if (emps.isEmpty) {
                return const Center(child: Text('No employees found.', style: TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: emps.length,
                itemBuilder: (context, index) {
                  final e = emps[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: e.role.color.withAlpha(40),
                        child: Icon(e.role.icon, color: e.role.color, size: 20),
                      ),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text('${e.email} • ${e.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: RoleBadge(role: e.role),
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

  // ================= 4. ASSIGN CUSTOMERS SCREEN (PDF Page 6) =================
  Widget _buildAssignCustomersView() {
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(),
      builder: (context, snapshot) {
        final customers = snapshot.data ?? [];
        if (customers.isEmpty) {
          return const Center(child: Text('No customers to assign.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final cust = customers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                subtitle: Text('Phone: ${cust.maskedPhone} • Status: ${cust.status.label}', style: const TextStyle(color: AppColors.textSecondary)),
                trailing: cust.assignedInsideSalesName != null
                    ? Chip(
                        label: Text('Assigned: ${cust.assignedInsideSalesName}'),
                        backgroundColor: AppColors.primary.withAlpha(40),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showQuickAssignDialog(cust),
                        child: const Text('Assign to Inside Sales'),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickAssignDialog(Customer cust) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Assign ${cust.name}', style: const TextStyle(color: AppColors.textPrimary)),
        content: StreamBuilder<List<Employee>>(
          stream: DatabaseService.getEmployeesStream(roleFilter: AppRole.insideSales),
          builder: (context, snapshot) {
            final staff = snapshot.data ?? [];
            if (staff.isEmpty) return const Text('No inside sales staff available.');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: staff
                  .map(
                    (s) => ListTile(
                      title: Text(s.name, style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(s.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      onTap: () async {
                        await DatabaseService.assignCustomerToInsideSales(
                          customerId: cust.id,
                          insideSalesId: s.id,
                          insideSalesName: s.name,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
