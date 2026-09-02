import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../models/customer_assignment.dart';

class CustomerService {
  static final _customers = FirebaseFirestore.instance.collection('customers');
  static final _assignments = FirebaseFirestore.instance.collection('customer_assignments');
  static final _callUpdates = FirebaseFirestore.instance.collection('call_updates');
  static final _employees = FirebaseFirestore.instance.collection('employees');

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Stream<List<Customer>> assignedForCalling() {
    return _customers
        .where('assignedInsideSalesId', isEqualTo: _uid)
        .where('status', isEqualTo: 'assigned_to_inside_sales')
        .snapshots()
        .map((s) => s.docs.map((d) => Customer.fromDoc(d)).toList());
  }

  static Stream<List<Customer>> interestedCustomers() {
    return _customers
        .where('assignedInsideSalesId', isEqualTo: _uid)
        .where('status', whereIn: [
          'interested',
          'visit_scheduled',
          'visit_in_progress',
          'visit_completed',
        ])
        .snapshots()
        .map((s) => s.docs.map((d) => Customer.fromDoc(d)).toList());
  }

  static Stream<List<Customer>> notInterestedCustomers() {
    return _customers
        .where('assignedInsideSalesId', isEqualTo: _uid)
        .where('status', isEqualTo: 'not_interested')
        .snapshots()
        .map((s) => s.docs.map((d) => Customer.fromDoc(d)).toList());
  }

  static Future<void> markInterested(String customerId) async {
    await _customers.doc(customerId).update({'status': 'interested'});
    await _callUpdates.add({
      'customerId': customerId,
      'insideSalesId': _uid,
      'outcome': 'interested',
      'notes': null,
      'whatsappSentAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markNotInterested(String customerId) async {
    await _customers.doc(customerId).update({'status': 'not_interested'});
    await _callUpdates.add({
      'customerId': customerId,
      'insideSalesId': _uid,
      'outcome': 'not_interested',
      'notes': null,
      'whatsappSentAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markWhatsappSent(String customerId) async {
    final snap = await _callUpdates
        .where('customerId', isEqualTo: customerId)
        .where('insideSalesId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'whatsappSentAt': FieldValue.serverTimestamp()});
    }
  }

  static Future<List<Employee>> outsideSalesEmployees() async {
    final snap = await _employees
        .where('role', isEqualTo: 'outside_sales')
        .where('active', isEqualTo: true)
        .get();
    return snap.docs.map((d) => Employee.fromDoc(d)).toList();
  }

  static Future<void> assignToOutsideSales(
    String customerId,
    String outsideSalesId,
    DateTime visitTime,
  ) async {
    final snap = await _assignments
        .where('customerId', isEqualTo: customerId)
        .where('insideSalesId', isEqualTo: _uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception('No assignment record found for this customer');
    }

    await snap.docs.first.reference.update({
      'outsideSalesId': outsideSalesId,
      'visitScheduledAt': Timestamp.fromDate(visitTime),
      'status': 'visit_scheduled',
    });

    await _customers.doc(customerId).update({
      'assignedOutsideSalesId': outsideSalesId,
      'status': 'visit_scheduled',
    });
  }

  static Stream<List<CustomerAssignment>> myOutsideAssignments() {
    return _assignments
        .where('insideSalesId', isEqualTo: _uid)
        .where('outsideSalesId', isNull: false)
        .snapshots()
        .map((s) => s.docs.map((d) => CustomerAssignment.fromDoc(d)).toList());
  }

  static Future<Customer> getCustomer(String customerId) async {
    final doc = await _customers.doc(customerId).get();
    return Customer.fromDoc(doc);
  }

  static Future<Employee> getEmployee(String employeeId) async {
    final doc = await _employees.doc(employeeId).get();
    return Employee.fromDoc(doc);
  }

  static Future<Employee> getProfile() async {
    final doc = await _employees.doc(_uid).get();
    return Employee.fromDoc(doc);
  }
}
