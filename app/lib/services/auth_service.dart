import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/office_location.dart';
import 'location_service.dart';
import 'attendance_service.dart';
import '../models/employee.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _employees = FirebaseFirestore.instance.collection('employees');

  static String? currentAttendanceId;

  static Future<Employee> login(String email, String password) async {
    final position = await LocationService.getCurrentPosition();
    final withinOffice =
        LocationService.distanceToOfficeMeters(position) <= OfficeLocation.allowedRadiusMeters;

    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final employeeDoc = await _employees.doc(uid).get();
    if (!employeeDoc.exists) {
      await _auth.signOut();
      throw Exception('No employee record found for this account');
    }

    final employee = Employee.fromDoc(employeeDoc);

    if (!employee.active) {
      await _auth.signOut();
      throw Exception('Your account has been disabled. Contact admin.');
    }
    if (employee.role != 'inside_sales') {
      await _auth.signOut();
      throw Exception('This login is not registered as an Inside Sales employee');
    }

    currentAttendanceId = await AttendanceService.logLogin(uid, position, withinOffice);

    if (!withinOffice) {
      await AuthService.logout();
      throw Exception('You must be within 200 meters of the office to log in');
    }

    return employee;
  }

  static Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    final attendanceId = currentAttendanceId ??
        (uid != null ? await AttendanceService.findOpenAttendanceId(uid) : null);
    if (attendanceId != null) {
      await AttendanceService.logLogout(attendanceId);
    }
    currentAttendanceId = null;
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
}
