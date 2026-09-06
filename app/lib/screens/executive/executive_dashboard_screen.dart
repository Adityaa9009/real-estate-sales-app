import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../models/staff_directory.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/role_badge.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/skeleton_shimmer.dart';
import '../login_screen.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  int _selectedSidebarIndex = 0; // 0: Add Emp, 1: Add Cust, 2: All Emp, 3: Assign

  void _handleLogout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Executive Portal',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Sales Operations & Team Allocation',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Executive',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surfaceBorder, height: 1),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: NavigationBar(
                selectedIndex: _selectedSidebarIndex,
                onDestinationSelected: (idx) =>
                    setState(() => _selectedSidebarIndex = idx),
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.secondary.withAlpha(40),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.person_add_outlined),
                    selectedIcon: Icon(Icons.person_add_rounded, color: AppColors.secondary),
                    label: 'Add Staff',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.group_add_outlined),
                    selectedIcon: Icon(Icons.group_add_rounded, color: AppColors.secondary),
                    label: 'Add Lead',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge_rounded, color: AppColors.secondary),
                    label: 'Directory',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_ind_outlined),
                    selectedIcon: Icon(Icons.assignment_ind_rounded, color: AppColors.secondary),
                    label: 'Assign',
                  ),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 12),
                      child: Text(
                        'MANAGEMENT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    _sidebarItem(0, Icons.person_add_rounded, 'Add Employee'),
                    _sidebarItem(1, Icons.group_add_rounded, 'Add Customer'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 12),
                      child: Text(
                        'PIPELINE & STAFF',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    _sidebarItem(2, Icons.badge_rounded, 'All Employees'),
                    _sidebarItem(3, Icons.assignment_ind_rounded, 'Assign Customers'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppColors.surfaceBorder, height: 1),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: const Icon(Icons.settings_outlined, color: AppColors.textMuted, size: 20),
                      title: Text(
                        'Settings',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Executive system settings configured.')),
                        );
                      },
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                      title: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),
            ),
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary.withAlpha(35) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.secondary.withAlpha(90) : Colors.transparent,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () => setState(() => _selectedSidebarIndex = index),
      ),
    );
  }

  // ================= 1. ADD EMPLOYEE VIEW =================
  final _empNameCtrl = TextEditingController();
  final _empEmailCtrl = TextEditingController();
  final _empPassCtrl = TextEditingController();
  final _empPhoneCtrl = TextEditingController();
  final _empDobCtrl = TextEditingController(text: '1998-05-15');
  AppRole _empRole = AppRole.insideSales;
  bool _savingEmp = false;
  bool _obscurePass = true;

  Widget _buildAddEmployeeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_add_rounded, color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Employee',
                            style: GoogleFonts.sora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Register an Inside Sales or Outside Sales team member',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: 20),
                Text(
                  'Full Name',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _empNameCtrl,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.textMuted),
                    hintText: 'e.g. Sudheer Kumar',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Work Email',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _empEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                    hintText: 'e.g. sudheer@company.com',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Password (minimum 6 characters)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _empPassCtrl,
                  obscureText: _obscurePass,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Phone Number',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _empPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.textMuted),
                    hintText: 'e.g. 9899001122',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Role Assignment',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<AppRole>(
                  initialValue: _empRole,
                  dropdownColor: AppColors.surfaceCard,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.textMuted),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AppRole.insideSales,
                      child: Text('Inside Sales (Calling & Qualification)'),
                    ),
                    DropdownMenuItem(
                      value: AppRole.outsideSales,
                      child: Text('Outside Sales (On-Site Visits & Fieldwork)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _empRole = val);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Date of Birth (DOB)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _empDobCtrl,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textMuted),
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _savingEmp ? null : _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _savingEmp
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Register Employee',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (_empNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Name is required.'),
        ),
      );
      return;
    }
    if (_empEmailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Email is required.'),
        ),
      );
      return;
    }
    if (_empPassCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Password must be at least 6 characters long.'),
        ),
      );
      return;
    }
    setState(() => _savingEmp = true);
    try {
      await DatabaseService.registerNewEmployee(
        name: _empNameCtrl.text.trim(),
        email: _empEmailCtrl.text.trim(),
        password: _empPassCtrl.text.trim(),
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
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Employee registered successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingEmp = false);
    }
  }

  // ================= 2. ADD CUSTOMER & EXCEL LEAD VIEW =================
  final _custNameCtrl = TextEditingController();
  final _custEmailCtrl = TextEditingController();
  final _custPhoneCtrl = TextEditingController();
  bool _savingCust = false;

  Widget _buildAddCustomerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.group_add_rounded, color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Customer Lead',
                                style: GoogleFonts.sora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Create a prospective buyer profile in the system',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.surfaceBorder, height: 1),
                    const SizedBox(height: 20),
                    Text(
                      'Customer Full Name',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _custNameCtrl,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.textMuted),
                        hintText: 'e.g. Ramesh Chandra',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Phone Number',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _custPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.textMuted),
                        hintText: 'e.g. 9811223344',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email Address (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _custEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                        hintText: 'e.g. ramesh@example.com',
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _savingCust ? null : _saveCustomer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _savingCust
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save Customer Lead',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Excel bulk import showcase container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withAlpha(160),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(60),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.table_view_rounded,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bulk Lead Import (.xlsx / .csv)',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Format required: Full Name, Phone, Email. Files are validated and assigned through the pipeline.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Upload'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lead file upload queue ready. Select an .xlsx file.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (_custNameCtrl.text.trim().isEmpty || _custPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Name and Phone are required.'),
        ),
      );
      return;
    }
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
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Customer lead added successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingCust = false);
    }
  }

  // ================= 3. ALL EMPLOYEES DIRECTORY =================
  String _empSearch = '';
  AppRole? _empFilter;

  Widget _buildAllEmployeesView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search staff by name or role...',
                      onChanged: (val) => setState(() => _empSearch = val.toLowerCase()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All Staff', _empFilter == null, () => setState(() => _empFilter = null)),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Inside Sales',
                      _empFilter == AppRole.insideSales,
                      () => setState(() => _empFilter = AppRole.insideSales),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Outside Sales',
                      _empFilter == AppRole.outsideSales,
                      () => setState(() => _empFilter = AppRole.outsideSales),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<StaffDirectoryEntry>>(
            stream: DatabaseService.getStaffDirectoryStream(roleFilter: _empFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 4,
                  itemBuilder: (context, index) => const SkeletonListTile(),
                );
              }

              final emps = (snapshot.data ?? []).where((e) {
                if (_empSearch.isEmpty) return true;
                return e.name.toLowerCase().contains(_empSearch) ||
                    e.role.label.toLowerCase().contains(_empSearch);
              }).toList();

              if (emps.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No Staff Found',
                  message: 'No team members match the selected directory filter.',
                  icon: Icons.badge_outlined,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: emps.length,
                itemBuilder: (context, index) {
                  final e = emps[index];
                  final initials = e.name.trim().isNotEmpty
                      ? e.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: e.role.color.withAlpha(35),
                          child: Text(
                            initials,
                            style: GoogleFonts.sora(
                              color: e.role.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              e.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: e.active ? AppColors.success : AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                e.role.label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(
                                e.active ? 'Active Employee' : 'Deactivated',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: e.active ? AppColors.success : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: RoleBadge(role: e.role),
                      ),
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

  Widget _filterChip(String label, bool isSelected, VoidCallback onSelected) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withAlpha(40) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ================= 4. ASSIGN CUSTOMERS SCREEN & DISTRIBUTION =================
  String _custSearch = '';
  String _custFilter = 'all'; // 'all', 'unassigned', 'assigned'

  Widget _buildAssignCustomersView() {
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService.getCustomersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
        }

        final allCustomers = snapshot.data ?? [];
        if (allCustomers.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Customer Leads',
            message: 'Add customer leads to start managing team assignments.',
            icon: Icons.assignment_ind_outlined,
          );
        }

        final unassignedCount = allCustomers.where((c) => c.assignedInsideSalesId == null).length;
        final assignedCount = allCustomers.length - unassignedCount;

        final filtered = allCustomers.where((c) {
          if (_custFilter == 'unassigned' && c.assignedInsideSalesId != null) return false;
          if (_custFilter == 'assigned' && c.assignedInsideSalesId == null) return false;
          if (_custSearch.isEmpty) return true;
          return c.name.toLowerCase().contains(_custSearch) ||
              c.maskedPhone.contains(_custSearch) ||
              (c.assignedInsideSalesName?.toLowerCase().contains(_custSearch) ?? false);
        }).toList();

        return CustomScrollView(
          slivers: [
            // Top Analytics Breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAssignmentAnalyticsCard(allCustomers, unassignedCount, assignedCount),
                    const SizedBox(height: 16),
                    // Search and filter row
                    Row(
                      children: [
                        Expanded(
                          child: SearchBarWidget(
                            hintText: 'Search leads or assigned reps...',
                            onChanged: (val) => setState(() => _custSearch = val.toLowerCase()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All (${allCustomers.length})', _custFilter == 'all', () => setState(() => _custFilter = 'all')),
                          const SizedBox(width: 8),
                          _filterChip('Unassigned ($unassignedCount)', _custFilter == 'unassigned', () => setState(() => _custFilter = 'unassigned')),
                          const SizedBox(width: 8),
                          _filterChip('Assigned ($assignedCount)', _custFilter == 'assigned', () => setState(() => _custFilter = 'assigned')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Customers list
            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  title: 'No Matching Leads',
                  message: 'No customer leads match the current search or filter.',
                  icon: Icons.filter_alt_off_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cust = filtered[index];
                      final isAssigned = cust.assignedInsideSalesId != null;
                      final initials = cust.name.trim().isNotEmpty
                          ? cust.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                          : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAssigned ? AppColors.surfaceBorder : AppColors.secondary.withAlpha(80),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: (isAssigned ? AppColors.primary : AppColors.secondary).withAlpha(35),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.sora(
                                      color: isAssigned ? AppColors.primary : AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            cust.name,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusPill(cust.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            cust.maskedPhone,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          if (isAssigned) ...[
                                            const SizedBox(width: 10),
                                            const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.person_pin_circle_outlined, size: 13, color: AppColors.info),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                cust.assignedInsideSalesName ?? 'Inside Rep',
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.info,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (isAssigned)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.surfaceBorder),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _showQuickAssignDialog(cust),
                                    child: Text(
                                      'Reassign',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _showQuickAssignDialog(cust),
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                                    label: Text(
                                      'Assign',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentAnalyticsCard(List<Customer> customers, int unassignedCount, int assignedCount) {
    final Map<String, int> repCounts = {};
    for (final c in customers) {
      if (c.assignedInsideSalesName != null && c.assignedInsideSalesName!.isNotEmpty) {
        final name = c.assignedInsideSalesName!;
        repCounts[name] = (repCounts[name] ?? 0) + 1;
      }
    }

    final total = customers.length;
    final assignedPct = total > 0 ? ((assignedCount / total) * 100).toStringAsFixed(0) : '0';

    final sliceColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.success,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final List<PieChartSectionData> sections = [];
    if (unassignedCount > 0) {
      sections.add(
        PieChartSectionData(
          value: unassignedCount.toDouble(),
          color: AppColors.warning,
          radius: 14,
          showTitle: false,
        ),
      );
    }
    int colorIdx = 0;
    for (final entry in repCounts.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          color: sliceColors[colorIdx % sliceColors.length],
          radius: 14,
          showTitle: false,
        ),
      );
      colorIdx++;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inside Sales Allocation Breakdown',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$assignedCount of $total leads allocated ($assignedPct%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0 && sections.isNotEmpty) ...[
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _metricDot(AppColors.primary, 'Assigned: $assignedCount'),
                      _metricDot(AppColors.warning, 'Unassigned: $unassignedCount'),
                      ...repCounts.entries.take(4).map(
                        (entry) => _metricDot(
                          AppColors.info,
                          '${entry.key}: ${entry.value}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(CustomerStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case CustomerStatus.unassigned:
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        break;
      case CustomerStatus.assignedToInsideSales:
        bg = AppColors.primary.withAlpha(30);
        fg = AppColors.primary;
        break;
      case CustomerStatus.interested:
        bg = AppColors.info.withAlpha(30);
        fg = AppColors.info;
        break;
      case CustomerStatus.notInterested:
        bg = AppColors.danger.withAlpha(30);
        fg = AppColors.danger;
        break;
      case CustomerStatus.visitScheduled:
        bg = AppColors.secondary.withAlpha(30);
        fg = AppColors.secondary;
        break;
      case CustomerStatus.visitInProgress:
        bg = AppColors.info.withAlpha(30);
        fg = AppColors.info;
        break;
      case CustomerStatus.visitCompleted:
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  void _showQuickAssignDialog(Customer cust) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment_ind_rounded, color: AppColors.secondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Customer',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    cust.name,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: StreamBuilder<List<StaffDirectoryEntry>>(
            stream: DatabaseService.getStaffDirectoryStream(
              roleFilter: AppRole.insideSales,
              onlyActive: true,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                );
              }

              final staff = snapshot.data ?? [];
              if (staff.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No active inside sales personnel found in staff directory.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: staff.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceBorder, height: 1),
                  itemBuilder: (context, index) {
                    final s = staff[index];
                    final initials = s.name.trim().isNotEmpty
                        ? s.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                        : '?';

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.secondary.withAlpha(35),
                          child: Text(
                            initials,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          s.role.label,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        onTap: () async {
                          await DatabaseService.assignCustomerToInsideSales(
                            customerId: cust.id,
                            insideSalesId: s.id,
                            insideSalesName: s.name,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('${cust.name} assigned to ${s.name}!'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
