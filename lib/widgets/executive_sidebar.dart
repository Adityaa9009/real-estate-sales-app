import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExecutiveNavItem {
  addEmployee,
  addCustomer,
  allEmployees,
  allCustomers,
  settings,
  logout,
}

class ExecutiveSidebar extends StatelessWidget {
  final ExecutiveNavItem selected;
  final ValueChanged<ExecutiveNavItem> onSelect;

  const ExecutiveSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _navTile(
            icon: Icons.person_add_alt_1,
            label: 'Add Employee',
            item: ExecutiveNavItem.addEmployee,
          ),
          _navTile(
            icon: Icons.person_add,
            label: 'Add Customer',
            item: ExecutiveNavItem.addCustomer,
          ),
          _navTile(
            icon: Icons.list_alt,
            label: 'All Employees',
            item: ExecutiveNavItem.allEmployees,
          ),
          _navTile(
            icon: Icons.list_alt,
            label: 'All Customer',
            item: ExecutiveNavItem.allCustomers,
          ),
          const Spacer(),
          _navTile(
            icon: Icons.settings,
            label: 'Settings',
            item: ExecutiveNavItem.settings,
          ),
          _navTile(
            icon: Icons.logout,
            label: 'Logout',
            item: ExecutiveNavItem.logout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String label,
    required ExecutiveNavItem item,
  }) {
    final bool isActive = selected == item;
    return Material(
      color: isActive ? AppColors.accentOrange : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.black : AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : AppColors.textPrimary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
