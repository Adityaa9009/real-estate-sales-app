import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../services/customer_service.dart';

class AssignVisitScreen extends StatefulWidget {
  final Customer customer;
  const AssignVisitScreen({super.key, required this.customer});

  @override
  State<AssignVisitScreen> createState() => _AssignVisitScreenState();
}

class _AssignVisitScreenState extends State<AssignVisitScreen> {
  List<Employee> _outsideEmployees = [];
  String? _selectedEmployeeId;
  DateTime? _visitTime;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employees = await CustomerService.outsideSalesEmployees();
    setState(() {
      _outsideEmployees = employees;
      _loading = false;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _visitTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _confirm() async {
    if (_selectedEmployeeId == null || _visitTime == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CustomerService.assignToOutsideSales(
        widget.customer.id,
        _selectedEmployeeId!,
        _visitTime!,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F9BFF),
        title: Text('Assign ${widget.customer.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1A1F2E),
                    decoration: const InputDecoration(
                      labelText: 'Outside Sales Employee',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                    items: _outsideEmployees
                        .map((e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(e.name, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedEmployeeId = v),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: const Color(0xFF1A1F2E),
                    title: Text(
                      _visitTime == null ? 'Select visit time' : _visitTime.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _confirm,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F9BFF)),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm Assignment', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
