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

  static Future<Employee> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('Sign in succeeded but no user ID returned.');
    }

    final doc = await _firestore.collection('employees').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError('No employee profile found in database for this account.');
    }

    final employee = Employee.fromFirestore(doc);
    if (!employee.active) {
      await _auth.signOut();
      throw StateError('Your employee account has been deactivated. Contact Admin.');
    }

    if (employee.role == AppRole.insideSales) {
      final geofence = await LocationService.checkOfficeGeofence();
      if (!geofence.isInside) {
        await _firestore.collection('attendance').add({
          'employeeId': employee.id,
          'employeeName': employee.name,
          'employeeEmail': employee.email,
          'loginAt': FieldValue.serverTimestamp(),
          'loginLatitude': geofence.position?.latitude,
          'loginLongitude': geofence.position?.longitude,
          'loginAllowed': false,
        });

        await _auth.signOut();
        throw StateError(
          'Geofence verification failed: You are ${geofence.distanceMeters.toStringAsFixed(0)}m away. Inside Sales must be within 200m of office.',
        );
      }
    }

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
        await _firestore.collection('attendance').doc(currentAttendanceId).update({
          'logoutAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}

    currentEmployee = null;
    currentAttendanceId = null;
    await _auth.signOut();
  }
}
