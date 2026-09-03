import 'package:flutter/material.dart';
import '../repository/executive_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/executive_sidebar.dart';
import 'add_employee_screen.dart';
import 'add_customer_screen.dart';
import 'all_employees_screen.dart';
import 'assign_screen.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  final ExecutiveRepository repository;
  // In the real app this comes from the logged-in Firebase Auth user.
  final String currentExecutiveId;

  const ExecutiveDashboardScreen({
    super.key,
    required this.repository,
    this.currentExecutiveId = 'mock-executive-id',
  });

  @override
  State<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  ExecutiveNavItem _selected = ExecutiveNavItem.addEmployee;

  void _onSelect(ExecutiveNavItem item) {
    if (item == ExecutiveNavItem.logout) {
      // Real implementation: call FirebaseAuth.instance.signOut() and
      // navigate back to the shared login screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout will be wired to real auth')),
      );
      return;
    }
    if (item == ExecutiveNavItem.settings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings screen not in scope yet')),
      );
      return;
    }
    setState(() => _selected = item);
  }

  Widget _buildContent() {
    switch (_selected) {
      case ExecutiveNavItem.addEmployee:
        return AddEmployeeScreen(repository: widget.repository);
      case ExecutiveNavItem.addCustomer:
        return AddCustomerScreen(repository: widget.repository);
      case ExecutiveNavItem.allEmployees:
        return AllEmployeesScreen(repository: widget.repository);
      case ExecutiveNavItem.allCustomers:
        return AssignScreen(
          repository: widget.repository,
          currentExecutiveId: widget.currentExecutiveId,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            ExecutiveSidebar(selected: _selected, onSelect: _onSelect),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
