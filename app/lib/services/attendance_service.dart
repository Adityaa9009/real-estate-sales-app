import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceService {
  static final _attendance = FirebaseFirestore.instance.collection('attendance');

  static Future<String> logLogin(String employeeId, Position position, bool loginAllowed) async {
    final doc = await _attendance.add({
      'employeeId': employeeId,
      'loginAt': FieldValue.serverTimestamp(),
      'logoutAt': null,
      'loginLatitude': position.latitude,
      'loginLongitude': position.longitude,
      'loginAllowed': loginAllowed,
    });
    return doc.id;
  }

  static Future<void> logLogout(String attendanceId) async {
    await _attendance.doc(attendanceId).update({
      'logoutAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String?> findOpenAttendanceId(String employeeId) async {
    final snap = await _attendance
        .where('employeeId', isEqualTo: employeeId)
        .where('logoutAt', isNull: true)
        .orderBy('loginAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }
}
