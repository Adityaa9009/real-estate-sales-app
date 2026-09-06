import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/metric_card.dart';
import '../login_screen.dart';
import 'attendance_tab.dart';
import 'broadcast_dialog.dart';
import 'customers_tab.dart';
import 'employees_tab.dart';
import 'field_tracking_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTabIndex = 0;

  void _handleSignOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.danger,
              size: 24,
            ),
            SizedBox(width: 10),
            Text('Admin Dashboard'),
          ],
        ),
        actions: [
          // 1-Click Broadcast Button (PDF Page 1)
          IconButton.filledTonal(
            icon: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            tooltip: '1-Click Broadcast Update/Holidays',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withAlpha(40),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const BroadcastDialog(),
            ),
          ),
          const SizedBox(width: 8),

          // Sign Out
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Overview KPI Header Bar (PDF Page 2)
          _buildMetricsHeader(),

          // Main Tabs Content
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: const [
                EmployeesTab(),
                CustomersTab(),
                FieldTrackingTab(),
                AttendanceTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_rounded),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera_front_rounded),
            label: 'Field Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM yyyy').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Welcome Admin, Have a nice day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Top KPI Metric Cards (PDF Page 2: Total Employees, Today Customers, Interested)
          StreamBuilder<List<Employee>>(
            stream: DatabaseService.getEmployeesStream(),
            builder: (context, empSnapshot) {
              final totalEmployees = (empSnapshot.data ?? []).length;
              return StreamBuilder<List<Customer>>(
                stream: DatabaseService.getCustomersStream(),
                builder: (context, custSnapshot) {
                  final customers = custSnapshot.data ?? [];
                  final totalCustomers = customers.length;
                  final interested = customers
                      .where((c) => c.status == CustomerStatus.interested)
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Total Employees',
                          value: '$totalEmployees',
                          icon: Icons.badge_outlined,
                          accentColor: AppColors.primary,
                          onTap: () => setState(() => _currentTabIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          title: 'Today Customers',
                          value: '$totalCustomers',
                          icon: Icons.people_alt_outlined,
                          accentColor: AppColors.info,
                          onTap: () => setState(() => _currentTabIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          title: 'Interested',
                          value: '$interested',
                          icon: Icons.thumb_up_alt_outlined,
                          accentColor: AppColors.success,
                          onTap: () => setState(() => _currentTabIndex = 1),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
