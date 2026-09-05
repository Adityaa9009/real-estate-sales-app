import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../models/customer.dart';
import '../models/visit.dart';
import '../models/attendance.dart';
import '../models/broadcast_message.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= EMPLOYEES =================
  static Stream<List<Employee>> getEmployeesStream({AppRole? roleFilter}) {
    Query<Map<String, dynamic>> query = _firestore.collection('employees');
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter.firestoreValue);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
    );
  }

  static Future<void> addEmployee({
    required String id,
    required String name,
    required String email,
    required String phone,
    required AppRole role,
    String? dob,
  }) async {
    await _firestore.collection('employees').doc(id).set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.firestoreValue,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'dob': ?dob,
    });
  }

  static Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await _firestore.collection('employees').doc(id).update(data);
  }

  static Future<void> deleteEmployee(String id) async {
    await _firestore.collection('employees').doc(id).delete();
  }

  // ================= CUSTOMERS =================
  static Stream<List<Customer>> getCustomersStream({
    CustomerStatus? statusFilter,
    String? assignedInsideSalesId,
    String? assignedOutsideSalesId,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('customers');

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.firestoreValue);
    }
    if (assignedInsideSalesId != null) {
      query = query.where('assignedInsideSalesId', isEqualTo: assignedInsideSalesId);
    }
    if (assignedOutsideSalesId != null) {
      query = query.where('assignedOutsideSalesId', isEqualTo: assignedOutsideSalesId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
    );
  }

  static Future<void> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? budget,
    String? propertyNotes,
    CustomerStatus status = CustomerStatus.unassigned,
  }) async {
    await _firestore.collection('customers').add({
      'name': name,
      'phone': phone,
      'email': email,
      'budget': budget,
      'propertyNotes': propertyNotes,
      'status': status.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> assignCustomerToInsideSales({
    required String customerId,
    required String insideSalesId,
    required String insideSalesName,
  }) async {
    await _firestore.collection('customers').doc(customerId).update({
      'assignedInsideSalesId': insideSalesId,
      'assignedInsideSalesName': insideSalesName,
      'status': CustomerStatus.assignedToInsideSales.firestoreValue,
    });
  }

  static Future<void> updateCustomerStatus({
    required String customerId,
    required CustomerStatus status,
  }) async {
    await _firestore.collection('customers').doc(customerId).update({
      'status': status.firestoreValue,
    });
  }

  static Future<void> scheduleOutsideSalesVisit({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String outsideSalesId,
    required String outsideSalesName,
    required DateTime visitDateTime,
    String? propertyNotes,
  }) async {
    // 1. Update customer
    await _firestore.collection('customers').doc(customerId).update({
      'assignedOutsideSalesId': outsideSalesId,
      'assignedOutsideSalesName': outsideSalesName,
      'status': CustomerStatus.visitScheduled.firestoreValue,
    });

    // 2. Create entry in visits
    await _firestore.collection('visits').add({
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'outsideSalesId': outsideSalesId,
      'outsideSalesName': outsideSalesName,
      'scheduledAt': Timestamp.fromDate(visitDateTime),
      'status': 'scheduled',
      'notes': propertyNotes,
    });
  }

  // ================= VISITS =================
  static Stream<List<Visit>> getVisitsStream({String? outsideSalesId}) {
    Query<Map<String, dynamic>> query = _firestore.collection('visits');
    if (outsideSalesId != null) {
      query = query.where('outsideSalesId', isEqualTo: outsideSalesId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Visit.fromFirestore(doc)).toList(),
    );
  }

  static Future<void> updateVisitStatus(String visitId, {
    required String status,
    DateTime? reachedAt,
    DateTime? completedAt,
    String? recordingPath,
    String? selfiePath,
  }) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (reachedAt != null) updateData['reachedAt'] = Timestamp.fromDate(reachedAt);
    if (completedAt != null) updateData['completedAt'] = Timestamp.fromDate(completedAt);
    if (recordingPath != null) updateData['recordingPath'] = recordingPath;
    if (selfiePath != null) updateData['selfiePath'] = selfiePath;

    await _firestore.collection('visits').doc(visitId).update(updateData);
  }

  // ================= ATTENDANCE =================
  static Stream<List<Attendance>> getAttendanceStream() {
    return _firestore
        .collection('attendance')
        .orderBy('loginAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Attendance.fromFirestore(doc)).toList());
  }

  // ================= BROADCAST MESSAGES =================
  static Stream<List<BroadcastMessage>> getBroadcastStream() {
    return _firestore
        .collection('broadcast_messages')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BroadcastMessage.fromFirestore(doc)).toList());
  }

  static Future<void> sendBroadcast({
    required String title,
    required String message,
    required String createdBy,
    List<String> targetRoles = const ['inside_sales', 'outside_sales', 'executive'],
  }) async {
    await _firestore.collection('broadcast_messages').add({
      'title': title,
      'message': message,
      'createdBy': createdBy,
      'targetRoles': targetRoles,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= 1-CLICK DEMO SEEDER =================
  /// Populates realistic data in Firestore for complete internship demo
  static Future<void> seedDemoData() async {
    final batch = _firestore.batch();

    // 1. Demo Employees
    final employees = [
      {
        'id': 'demo_admin_id',
        'name': 'Aditya Duhan (Admin)',
        'email': 'admin@realestate.com',
        'phone': '9876543210',
        'role': 'admin',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'demo_exec_id',
        'name': 'Rajesh Sharma (Executive)',
        'email': 'executive@realestate.com',
        'phone': '9811223344',
        'role': 'executive',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'demo_inside_id',
        'name': 'Sudheer Kumar (Inside Sales)',
        'email': 'inside.sales@realestate.com',
        'phone': '9899001122',
        'role': 'inside_sales',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'demo_outside_id',
        'name': 'Venkatesh Rao (Outside Sales)',
        'email': 'outside.sales@realestate.com',
        'phone': '9844556677',
        'role': 'outside_sales',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'demo_outside_2',
        'name': 'Usha Patel (Outside Sales)',
        'email': 'usha.patel@realestate.com',
        'phone': '9822334455',
        'role': 'outside_sales',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var emp in employees) {
      final ref = _firestore.collection('employees').doc(emp['id'] as String);
      batch.set(ref, emp);
    }

    // 2. Demo Customers
    final customers = [
      {
        'name': 'Ajith Kumar',
        'phone': '9876544892',
        'email': 'ajith@gmail.com',
        'budget': '1.5 - 2.0 Cr',
        'status': 'assigned_to_inside_sales',
        'assignedInsideSalesId': 'demo_inside_id',
        'assignedInsideSalesName': 'Sudheer Kumar',
        'propertyNotes': 'Looking for 3BHK high-rise apartment with golf view',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Sanjay Khan',
        'phone': '9812343541',
        'email': 'sanjay.khan@yahoo.com',
        'budget': '80 Lakhs - 1.2 Cr',
        'status': 'interested',
        'assignedInsideSalesId': 'demo_inside_id',
        'assignedInsideSalesName': 'Sudheer Kumar',
        'propertyNotes': 'Ready to move 2BHK near metro station',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Sharath Reddy',
        'phone': '9722335985',
        'email': 'sharath.r@outlook.com',
        'budget': '2.5 - 3.5 Cr',
        'status': 'visit_scheduled',
        'assignedInsideSalesId': 'demo_inside_id',
        'assignedInsideSalesName': 'Sudheer Kumar',
        'assignedOutsideSalesId': 'demo_outside_id',
        'assignedOutsideSalesName': 'Venkatesh Rao',
        'propertyNotes': 'Luxury Villa on Dwarka Expressway',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Narendra Modi',
        'phone': '9899009459',
        'email': 'n.modi@company.in',
        'budget': '4.0 - 6.0 Cr',
        'status': 'visit_completed',
        'assignedInsideSalesId': 'demo_inside_id',
        'assignedInsideSalesName': 'Sudheer Kumar',
        'assignedOutsideSalesId': 'demo_outside_id',
        'assignedOutsideSalesName': 'Venkatesh Rao',
        'propertyNotes': 'Commercial Penthouse',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Rohan Sharma',
        'phone': '9811005678',
        'email': 'rohan.s@gmail.com',
        'budget': '60 - 75 Lakhs',
        'status': 'not_interested',
        'assignedInsideSalesId': 'demo_inside_id',
        'assignedInsideSalesName': 'Sudheer Kumar',
        'propertyNotes': 'Budget constraints, will review in 6 months',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Janardan Rao',
        'phone': '9822333541',
        'email': 'j.rao@tech.com',
        'budget': '1.8 Cr',
        'status': 'unassigned',
        'propertyNotes': 'Inquired through digital campaign',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Bala Subramanian',
        'phone': '9944558579',
        'email': 'bala.subra@live.com',
        'budget': '2.2 Cr',
        'status': 'unassigned',
        'propertyNotes': 'Seeking gated community duplex',
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var cust in customers) {
      final ref = _firestore.collection('customers').doc();
      batch.set(ref, cust);
    }

    // 3. Demo Visits
    final visits = [
      {
        'customerId': 'demo_cust_1',
        'customerName': 'Sharath Reddy',
        'customerPhone': '9722335985',
        'outsideSalesId': 'demo_outside_id',
        'outsideSalesName': 'Venkatesh Rao',
        'scheduledAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 3))),
        'status': 'scheduled',
        'notes': 'Site visit at Tower 4, Royal Palms DLF Phase 5',
      },
      {
        'customerId': 'demo_cust_2',
        'customerName': 'Narendra Modi',
        'customerPhone': '9899009459',
        'outsideSalesId': 'demo_outside_id',
        'outsideSalesName': 'Venkatesh Rao',
        'scheduledAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
        'reachedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3, minutes: 45))),
        'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        'recordingPath': 'audio_visit_narendra_modi_dlf.m4a',
        'selfiePath': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        'status': 'completed',
        'notes': 'Customer very happy with penthouse structure, token advance expected this Friday.',
      }
    ];

    for (var v in visits) {
      final ref = _firestore.collection('visits').doc();
      batch.set(ref, v);
    }

    // 4. Demo Attendance
    final attendanceLogs = [
      {
        'employeeId': 'demo_inside_id',
        'employeeName': 'Sudheer Kumar',
        'employeeEmail': 'inside.sales@realestate.com',
        'loginAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
        'logoutAt': null,
        'loginAllowed': true,
      },
      {
        'employeeId': 'demo_outside_id',
        'employeeName': 'Venkatesh Rao',
        'employeeEmail': 'outside.sales@realestate.com',
        'loginAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))),
        'logoutAt': null,
        'loginAllowed': true,
      }
    ];

    for (var a in attendanceLogs) {
      final ref = _firestore.collection('attendance').doc();
      batch.set(ref, a);
    }

    // 5. Broadcast message
    final broadcastRef = _firestore.collection('broadcast_messages').doc();
    batch.set(broadcastRef, {
      'title': 'Grand Festive Incentive Announcement 🎉',
      'message': 'All site visits scheduled this weekend are eligible for 2x sales bonus! Great job team!',
      'createdBy': 'Aditya Duhan (Admin)',
      'targetRoles': ['inside_sales', 'outside_sales', 'executive'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
