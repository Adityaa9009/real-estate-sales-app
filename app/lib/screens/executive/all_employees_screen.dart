import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../repository/executive_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_header.dart';

class AllEmployeesScreen extends StatefulWidget {
  final ExecutiveRepository repository;

  const AllEmployeesScreen({super.key, required this.repository});

  @override
  State<AllEmployeesScreen> createState() => _AllEmployeesScreenState();
}

class _AllEmployeesScreenState extends State<AllEmployeesScreen> {
  List<Employee> _all = [];
  bool _loading = true;
  String _filter = 'all'; // all | inside_sales | outside_sales
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await widget.repository.getAllEmployees();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  List<Employee> get _filtered {
    var list = _all;
    if (_filter != 'all') {
      list = list.where((e) => e.role == _filter).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.email.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _delete(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Employee',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove ${employee.name}?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.repository.deleteEmployee(employee.id);
    _load();
  }

  void _showInfo(Employee employee) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(employee.name,
            style: const TextStyle(color: AppColors.accentOrange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Email', employee.email),
            _infoRow('Phone', employee.phone),
            _infoRow('Role', employee.roleLabel),
            _infoRow('Status', employee.active ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: AppColors.accentOrange)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String label, String value) {
    final bool active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accentOrange : AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppColors.textPrimary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardHeader(
          title: 'Employee Details',
          onAddPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Go to Add Employee to add a new employee')),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Employees...',
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.inputField,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterPill('All Employees', 'all'),
              const SizedBox(width: 8),
              _filterPill('Inside Sales', 'inside_sales'),
              const SizedBox(width: 8),
              _filterPill('Outside Sales', 'outside_sales'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentOrange))
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('No employees found',
                          style:
                              TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final emp = _filtered[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Name: ${emp.name}',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('Role: ${emp.roleLabel}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                onPressed: () => _delete(emp),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline,
                                    color: AppColors.accentOrange,
                                    size: 20),
                                onPressed: () => _showInfo(emp),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
