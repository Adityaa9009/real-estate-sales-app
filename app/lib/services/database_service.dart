import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/employee.dart';
import '../models/customer.dart';
import '../models/visit.dart';
import '../models/attendance.dart';
import '../models/broadcast_message.dart';

class CustomerPhoneMigrationReport {
  final int totalCustomers;
  final int migratedCustomers;
  final int failedCustomers;
  final int totalVisits;
  final int migratedVisits;
  final int failedVisits;
  final List<String> errors;

  const CustomerPhoneMigrationReport({
    required this.totalCustomers,
    required this.migratedCustomers,
    required this.failedCustomers,
    required this.totalVisits,
    required this.migratedVisits,
    required this.failedVisits,
    required this.errors,
  });

  @override
  String toString() =>
      'MigrationReport(customers: $migratedCustomers/$totalCustomers migrated, $failedCustomers failed; '
      'visits: $migratedVisits/$totalVisits migrated, $failedVisits failed; errors: ${errors.length})';
}

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= EMPLOYEES =================

  /// Stream of employee profiles
  static Stream<List<Employee>> getEmployeesStream({
    AppRole? roleFilter,
    bool onlyActive = false,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('employees');
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter.firestoreValue);
    }
    if (onlyActive) {
      query = query.where('active', isEqualTo: true);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
    );
  }

  /// Adds an employee: creates Auth user and populates /employees
  static Future<void> registerNewEmployee({
    required String name,
    required String email,
    required String password,
    required String phone,
    required AppRole role,
    String? dob,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();
    if (trimmedPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters long.');
    }

    // 1. Attempt secondary auth registration
    FirebaseApp? secondaryApp;
    String employeeId;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'EmpReg_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: trimmedPassword,
      );
      employeeId = cred.user!.uid;
    } catch (e) {
      throw Exception('Failed to create login for this employee: ${e.toString()}');
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }

    // 2. Write to /employees
    await _firestore.collection('employees').doc(employeeId).set({
      'id': employeeId,
      'name': name.trim(),
      'email': cleanEmail,
      'phone': phone.trim(),
      'role': role.firestoreValue,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
    }, SetOptions(merge: true));
  }

  /// Deactivates an employee in /employees
  static Future<void> deactivateEmployee(String id) async {
    await _firestore.collection('employees').doc(id).update({'active': false});
  }

  /// Reactivates an employee in /employees
  static Future<void> reactivateEmployee(String id) async {
    await _firestore.collection('employees').doc(id).update({'active': true});
  }

  static Future<void> updateEmployee(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('employees').doc(id).update(data);
  }

  // ================= CUSTOMERS & CONTACT PRIVACY =================

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
      query = query.where(
        'assignedInsideSalesId',
        isEqualTo: assignedInsideSalesId,
      );
    }
    if (assignedOutsideSalesId != null) {
      query = query.where(
        'assignedOutsideSalesId',
        isEqualTo: assignedOutsideSalesId,
      );
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
    );
  }

  /// Adds a new customer with root maskedPhone and isolated private contact subcollection
  static Future<void> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? budget,
    String? propertyNotes,
    CustomerStatus status = CustomerStatus.unassigned,
  }) async {
    final custRef = _firestore.collection('customers').doc();
    final masked = Customer.maskPhoneNumber(phone);

    final batch = _firestore.batch();

    // 1. Root customer doc (masked phone only, id matching doc.id)
    batch.set(custRef, {
      'id': custRef.id,
      'name': name.trim(),
      'maskedPhone': masked,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (budget != null && budget.trim().isNotEmpty) 'budget': budget.trim(),
      if (propertyNotes != null && propertyNotes.trim().isNotEmpty)
        'propertyNotes': propertyNotes.trim(),
      'status': status.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Private contact subcollection (/customers/{id}/private/contact)
    final contactRef = custRef.collection('private').doc('contact');
    batch.set(contactRef, {
      'customerId': custRef.id,
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// On-demand fetch of customer's actual phone from restricted private subcollection
  static Future<String?> getCustomerPrivateContact(String customerId) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('private')
          .doc('contact')
          .get();
      if (!doc.exists) return null;
      return doc.data()?['phone'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> assignCustomerToInsideSales({
    required String customerId,
    required String insideSalesId,
    required String insideSalesName,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('customers').doc(customerId), {
      'assignedInsideSalesId': insideSalesId,
      'assignedInsideSalesName': insideSalesName,
      'status': CustomerStatus.assignedToInsideSales.firestoreValue,
    });

    final assignRef = _firestore.collection('customer_assignments').doc();
    batch.set(assignRef, {
      'customerId': customerId,
      'insideSalesId': insideSalesId,
      'assignedBy': FirebaseAuth.instance.currentUser?.uid ?? 'executive',
      'status': 'assigned_to_inside_sales',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> updateCustomerStatus({
    required String customerId,
    required CustomerStatus status,
  }) async {
    await _firestore.collection('customers').doc(customerId).update({
      'status': status.firestoreValue,
    });
  }

  static Future<void> recordCallUpdate({
    required String customerId,
    required String outcome,
    String? notes,
    bool whatsappSent = false,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final updateRef = _firestore.collection('call_updates').doc();
    await updateRef.set({
      'customerId': customerId,
      'insideSalesId': currentUid,
      'outcome': outcome,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (whatsappSent) 'whatsappSentAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= ATOMIC VISIT OPERATIONS =================

  /// Inside Sales schedules an Outside Sales visit: updates customer and creates visit atomically
  static Future<void> scheduleOutsideSalesVisit({
    required String customerId,
    required String customerName,
    required String maskedPhone,
    required String outsideSalesId,
    required String outsideSalesName,
    required DateTime visitDateTime,
    String? propertyNotes,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currentInsideSalesName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Inside Sales';
    final visitRef = _firestore.collection('visits').doc();
    final customerRef = _firestore.collection('customers').doc(customerId);

    final batch = _firestore.batch();

    // 1. Paired Customer update
    batch.update(customerRef, {
      'status': CustomerStatus.visitScheduled.firestoreValue,
      'assignedOutsideSalesId': outsideSalesId,
      'assignedOutsideSalesName': outsideSalesName,
      'activeVisitId': visitRef.id,
    });

    // 2. Paired Visit create
    batch.set(visitRef, {
      'id': visitRef.id,
      'customerId': customerId,
      'customerName': customerName,
      'maskedPhone': maskedPhone,
      'insideSalesId': currentUid,
      'insideSalesName': currentInsideSalesName,
      'outsideSalesId': outsideSalesId,
      'outsideSalesName': outsideSalesName,
      'scheduledAt': Timestamp.fromDate(visitDateTime),
      'status': VisitStatus.visitScheduled.firestoreValue,
      if (propertyNotes != null && propertyNotes.isNotEmpty)
        'notes': propertyNotes,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Outside Sales marks visit reached: atomically updates visit and customer to visit_in_progress
  static Future<void> reachVisit({
    required String visitId,
    required String customerId,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('visits').doc(visitId), {
      'status': VisitStatus.visitInProgress.firestoreValue,
      'reachedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('customers').doc(customerId), {
      'status': CustomerStatus.visitInProgress.firestoreValue,
    });

    await batch.commit();
  }

  /// Outside Sales marks visit completed: atomically updates visit and customer to visit_completed
  static Future<void> completeVisit({
    required String visitId,
    required String customerId,
    String? notes,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('visits').doc(visitId), {
      'status': VisitStatus.visitCompleted.firestoreValue,
      'completedAt': FieldValue.serverTimestamp(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    batch.update(_firestore.collection('customers').doc(customerId), {
      'status': CustomerStatus.visitCompleted.firestoreValue,
    });

    await batch.commit();
  }

  static Stream<List<Visit>> getVisitsStream({
    String? outsideSalesId,
    String? insideSalesId,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('visits');
    if (outsideSalesId != null) {
      query = query.where('outsideSalesId', isEqualTo: outsideSalesId);
    }
    if (insideSalesId != null) {
      query = query.where('insideSalesId', isEqualTo: insideSalesId);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Visit.fromFirestore(doc)).toList(),
    );
  }

  // ================= ATTENDANCE =================

  static Stream<List<Attendance>> getAttendanceStream() {
    return _firestore
        .collection('attendance')
        .orderBy('loginAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Attendance.fromFirestore(doc))
              .toList(),
        );
  }

  static Future<String> recordAttendanceLogin({
    required String employeeId,
    required String employeeName,
    required String employeeEmail,
    required bool loginAllowed,
    double? latitude,
    double? longitude,
    double? distanceMeters,
    String? failureReason,
  }) async {
    final ref = _firestore.collection('attendance').doc();
    await ref.set({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'loginAt': FieldValue.serverTimestamp(),
      'loginAllowed': loginAllowed,
      'loginLatitude': ?latitude,
      'loginLongitude': ?longitude,
      'distanceMeters': ?distanceMeters,
      'failureReason': ?failureReason,
    });
    return ref.id;
  }

  static Future<void> recordAttendanceLogout(String attendanceDocId) async {
    await _firestore.collection('attendance').doc(attendanceDocId).update({
      'logoutAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= BROADCAST MESSAGES =================

  static Stream<List<BroadcastMessage>> getBroadcastStream() {
    return _firestore
        .collection('broadcast_messages')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BroadcastMessage.fromFirestore(doc))
              .toList(),
        );
  }

  static Future<void> sendBroadcast({
    required String title,
    required String message,
    required String createdBy,
    List<String> targetRoles = const [
      'inside_sales',
      'outside_sales',
      'executive',
    ],
  }) async {
    await _firestore.collection('broadcast_messages').add({
      'title': title,
      'message': message,
      'createdBy': createdBy,
      'targetRoles': targetRoles,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= MIGRATION & BACKFILL =================

  /// Migrates legacy customers and visits:
  /// - Backfills `customers/{customerId}.id = customerId`
  /// - Backfills `visits/{visitId}.id = visitId`
  /// - Populates `/customers/{customerId}/private/contact` with `{customerId, phone, updatedAt}`
  /// - Replaces raw `phone` with `maskedPhone` on customers
  /// - Replaces raw `customerPhone` with `maskedPhone` on visits and strips legacy media fields
  /// Returns a detailed `CustomerPhoneMigrationReport`.
  static Future<CustomerPhoneMigrationReport>
  migrateCustomerPhonePrivacy() async {
    final List<String> errors = [];
    int totalCustomers = 0;
    int migratedCustomers = 0;
    int failedCustomers = 0;

    int totalVisits = 0;
    int migratedVisits = 0;
    int failedVisits = 0;

    // 1. Migrate customers
    try {
      final custSnapshots = await _firestore.collection('customers').get();
      totalCustomers = custSnapshots.docs.length;

      for (var doc in custSnapshots.docs) {
        try {
          final data = doc.data();
          final rawPhone =
              data['phone'] as String? ?? data['rawPhone'] as String? ?? '';
          final maskedPhone =
              data['maskedPhone'] as String? ??
              Customer.maskPhoneNumber(rawPhone);

          final batch = _firestore.batch();

          // Write private contact if rawPhone exists
          if (rawPhone.isNotEmpty) {
            final contactRef = doc.reference
                .collection('private')
                .doc('contact');
            batch.set(contactRef, {
              'customerId': doc.id,
              'phone': rawPhone,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          // Backfill id, set maskedPhone, remove raw phone fields
          batch.update(doc.reference, {
            'id': doc.id,
            'maskedPhone': maskedPhone,
            'phone': FieldValue.delete(),
            'rawPhone': FieldValue.delete(),
            'contactPhone': FieldValue.delete(),
            'customerPhone': FieldValue.delete(),
          });

          await batch.commit();
          migratedCustomers++;
        } catch (e) {
          failedCustomers++;
          errors.add('Customer ${doc.id} migration failed: $e');
        }
      }
    } catch (e) {
      errors.add('Failed to fetch customers for migration: $e');
    }

    // 2. Migrate visits
    try {
      final visitSnapshots = await _firestore.collection('visits').get();
      totalVisits = visitSnapshots.docs.length;

      for (var doc in visitSnapshots.docs) {
        try {
          final data = doc.data();
          final rawPhone =
              data['customerPhone'] as String? ??
              data['phone'] as String? ??
              '';
          final maskedPhone =
              data['maskedPhone'] as String? ?? Visit.maskPhoneNumber(rawPhone);

          final updateData = <String, dynamic>{
            'id': doc.id,
            'maskedPhone': maskedPhone,
            'customerPhone': FieldValue.delete(),
            'phone': FieldValue.delete(),
            'recordingPath': FieldValue.delete(),
            'selfiePath': FieldValue.delete(),
            'recordingUrl': FieldValue.delete(),
            'selfieUrl': FieldValue.delete(),
          };

          await doc.reference.update(updateData);
          migratedVisits++;
        } catch (e) {
          failedVisits++;
          errors.add('Visit ${doc.id} migration failed: $e');
        }
      }
    } catch (e) {
      errors.add('Failed to fetch visits for migration: $e');
    }

    return CustomerPhoneMigrationReport(
      totalCustomers: totalCustomers,
      migratedCustomers: migratedCustomers,
      failedCustomers: failedCustomers,
      totalVisits: totalVisits,
      migratedVisits: migratedVisits,
      failedVisits: failedVisits,
      errors: errors,
    );
  }
}
