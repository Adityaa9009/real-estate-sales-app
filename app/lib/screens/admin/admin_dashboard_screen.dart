import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/skeleton_shimmer.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withAlpha(80)),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Admin Dashboard',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // 1-Click Broadcast Button (PDF Page 1)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const BroadcastDialog(),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Broadcast',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        ),
        child: BottomNavigationBar(
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
      ),
    );
  }

  Widget _buildMetricsHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM yyyy').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome Admin, Have a nice day',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Top KPI Metric Cards (PDF Page 2: Total Employees, Today Customers, Interested)
          StreamBuilder<List<Employee>>(
            stream: DatabaseService.getEmployeesStream(),
            builder: (context, empSnapshot) {
              return StreamBuilder<List<Customer>>(
                stream: DatabaseService.getCustomersStream(),
                builder: (context, custSnapshot) {
                  if (empSnapshot.connectionState == ConnectionState.waiting &&
                      !empSnapshot.hasData) {
                    return const SkeletonMetricGrid(count: 3);
                  }

                  final totalEmployees = (empSnapshot.data ?? []).length;
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
