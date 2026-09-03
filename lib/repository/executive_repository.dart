import 'dart:math';
import '../models/employee.dart';
import '../models/customer.dart';
import '../models/customer_assignment.dart';

/// Abstract contract for everything the Executive screens need.
///
/// IMPORTANT FOR INTEGRATION:
/// When the team lead's Firebase/auth backend is ready, create a new class
/// `FirebaseExecutiveRepository implements ExecutiveRepository` that talks to
/// real Firestore collections using the exact field names in
/// docs/DATABASE_SCHEMA.md, then swap the single line in main.dart that
/// constructs the repository. No screen code needs to change.
abstract class ExecutiveRepository {
  Future<List<Employee>> getAllEmployees();
  Future<Employee> addEmployee({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required DateTime dob,
  });
  Future<void> deleteEmployee(String employeeId);

  Future<List<Customer>> getAllCustomers();
  Future<Customer> addCustomer({
    required String name,
    required String email,
    required String phone,
  });
  Future<List<Customer>> addCustomersBulk(List<Customer> customers);
  Future<void> deleteCustomer(String customerId);

  Future<void> assignCustomerToInsideSales({
    required String customerId,
    required String insideSalesId,
    required String assignedByExecutiveId,
  });
  Future<List<Customer>> getAssignedCustomers();
}

/// In-memory mock so the Executive module can be built, run, and demoed
/// before the real Firebase project is wired up.
class MockExecutiveRepository implements ExecutiveRepository {
  final List<Employee> _employees = [];
  final List<Customer> _customers = [];
  final List<CustomerAssignment> _assignments = [];
  final _random = Random();

  MockExecutiveRepository() {
    _seedData();
  }

  String _newId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      _random.nextInt(9999).toString();

  void _seedData() {
    _employees.addAll([
      Employee(
        id: _newId(),
        name: 'Sudheer',
        email: 'sudheer@demo.com',
        phone: '9000000001',
        role: 'inside_sales',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Employee(
        id: _newId(),
        name: 'Rayudu',
        email: 'rayudu@demo.com',
        phone: '9000000002',
        role: 'inside_sales',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Employee(
        id: _newId(),
        name: 'Usha',
        email: 'usha@demo.com',
        phone: '9000000003',
        role: 'outside_sales',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Employee(
        id: _newId(),
        name: 'Manch',
        email: 'manch@demo.com',
        phone: '9000000004',
        role: 'outside_sales',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    _customers.addAll([
      Customer(
        id: _newId(),
        name: 'Ajith',
        phone: '9876543210',
        status: 'unassigned',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Customer(
        id: _newId(),
        name: 'Stalin',
        phone: '9876543211',
        status: 'unassigned',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Customer(
        id: _newId(),
        name: 'Bala',
        phone: '9876543212',
        status: 'unassigned',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
  }

  Future<void> _fakeDelay() =>
      Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<Employee>> getAllEmployees() async {
    await _fakeDelay();
    return List.unmodifiable(_employees);
  }

  @override
  Future<Employee> addEmployee({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required DateTime dob,
  }) async {
    await _fakeDelay();
    // NOTE: real implementation must call Firebase Auth createUserWithEmailAndPassword
    // then write the resulting uid + fields below into `employees`.
    final employee = Employee(
      id: _newId(),
      name: name,
      email: email,
      phone: phone,
      role: role,
      active: true,
      createdAt: DateTime.now(),
    );
    _employees.add(employee);
    return employee;
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    await _fakeDelay();
    _employees.removeWhere((e) => e.id == employeeId);
  }

  @override
  Future<List<Customer>> getAllCustomers() async {
    await _fakeDelay();
    return List.unmodifiable(_customers);
  }

  @override
  Future<Customer> addCustomer({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _fakeDelay();
    final customer = Customer(
      id: _newId(),
      name: name,
      phone: phone,
      email: email,
      status: 'unassigned',
      createdAt: DateTime.now(),
    );
    _customers.add(customer);
    return customer;
  }

  @override
  Future<List<Customer>> addCustomersBulk(List<Customer> customers) async {
    await _fakeDelay();
    _customers.addAll(customers);
    return customers;
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    await _fakeDelay();
    _customers.removeWhere((c) => c.id == customerId);
  }

  @override
  Future<void> assignCustomerToInsideSales({
    required String customerId,
    required String insideSalesId,
    required String assignedByExecutiveId,
  }) async {
    await _fakeDelay();
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    _customers[index] = _customers[index].copyWith(
      status: 'assigned_to_inside_sales',
      assignedInsideSalesId: insideSalesId,
    );

    _assignments.add(CustomerAssignment(
      customerId: customerId,
      insideSalesId: insideSalesId,
      assignedBy: assignedByExecutiveId,
      status: 'assigned_to_inside_sales',
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<Customer>> getAssignedCustomers() async {
    await _fakeDelay();
    return _customers
        .where((c) => c.assignedInsideSalesId != null)
        .toList(growable: false);
  }
}
