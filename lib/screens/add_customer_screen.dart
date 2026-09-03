import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../repository/executive_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_header.dart';

class AddCustomerScreen extends StatefulWidget {
  final ExecutiveRepository repository;

  const AddCustomerScreen({super.key, required this.repository});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.repository.addCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully')),
      );
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add customer: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Expects an .xlsx file with header row: name | email | phone
  Future<void> _uploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final Uint8List bytes = result.files.single.bytes!;
      final excelFile = xls.Excel.decodeBytes(bytes);
      final sheet = excelFile.tables[excelFile.tables.keys.first]!;

      final customers = <Customer>[];
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty || row[0]?.value == null) continue;

        final name = row[0]?.value.toString() ?? '';
        final email = row.length > 1 ? row[1]?.value.toString() : null;
        final phone = row.length > 2 ? (row[2]?.value.toString() ?? '') : '';

        if (name.isEmpty) continue;

        customers.add(Customer(
          id: '', // repository assigns a real id when persisted
          name: name,
          email: email,
          phone: phone,
          status: 'unassigned',
          createdAt: DateTime.now(),
        ));
      }

      if (customers.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid rows found in the file')),
        );
        return;
      }

      await widget.repository.addCustomersBulk(customers);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${customers.length} customers imported')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import file: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardHeader(title: 'Add Customer'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Phone'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.accentOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              color: AppColors.accentOrange, width: 1),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentOrange),
                            )
                          : const Text('Submit'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadExcel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary),
                            )
                          : const Text('Upload Excel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
