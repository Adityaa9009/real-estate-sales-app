import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/employee.dart';
import 'location_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Employee? currentEmployee;
  static String? currentAttendanceId;

  /// Authenticates user, creates account if first-time admin/demo, and verifies role + geofence
  static Future<Employee> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    UserCredential credential;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw 'Invalid email or password. Please verify your credentials.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address format is invalid.';
      } else if (e.code == 'user-disabled') {
        throw 'This employee account has been deactivated. Please contact your administrator.';
      } else {
        throw e.message ??
            'Authentication failed. Please check your credentials.';
      }
    }

    final uid = credential.user!.uid;

    // Fetch employee document
    final doc = await _firestore.collection('employees').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError(
        'Employee record not found in system directory. Please contact your administrator.',
      );
    }

    final employee = Employee.fromFirestore(doc);

    if (!employee.active) {
      await _auth.signOut();
      throw StateError(
        'This employee account has been deactivated. Please contact your administrator.',
      );
    }

    // Auto-detect Geofence for Inside Sales (200m office perimeter)
    if (employee.role == AppRole.insideSales) {
      final geofence = await LocationService.checkOfficeGeofence();
      if (!geofence.isInside) {
        // Record denied attendance attempt
        await _firestore.collection('attendance').add({
          'employeeId': employee.id,
          'employeeName': employee.name,
          'employeeEmail': employee.email,
          'loginAt': FieldValue.serverTimestamp(),
          if (geofence.position != null)
            'loginLatitude': geofence.position!.latitude,
          if (geofence.position != null)
            'loginLongitude': geofence.position!.longitude,
          'loginAllowed': false,
          'failureReason': geofence.message,
          'distanceMeters': geofence.distanceMeters,
        });

        await _auth.signOut();
        throw StateError(
          'Office Geofence Verification Failed: ${geofence.message}',
        );
      }
    }

    // Record verified attendance in database
    final attDoc = await _firestore.collection('attendance').add({
      'employeeId': employee.id,
      'employeeName': employee.name,
      'employeeEmail': employee.email,
      'loginAt': FieldValue.serverTimestamp(),
      'loginAllowed': true,
    });
    currentAttendanceId = attDoc.id;
    currentEmployee = employee;

    return employee;
  }

  static Future<void> signOut() async {
    try {
      if (currentAttendanceId != null) {
        await _firestore
            .collection('attendance')
            .doc(currentAttendanceId)
            .update({'logoutAt': FieldValue.serverTimestamp()});
      }
    } catch (_) {}

    currentEmployee = null;
    currentAttendanceId = null;
    await _auth.signOut();
  }
}
