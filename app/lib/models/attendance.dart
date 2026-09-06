import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeEmail;
  final DateTime loginAt;
  final DateTime? logoutAt;
  final double? loginLatitude;
  final double? loginLongitude;
  final bool loginAllowed;

  const Attendance({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeEmail,
    required this.loginAt,
    this.logoutAt,
    this.loginLatitude,
    this.loginLongitude,
    this.loginAllowed = true,
  });

  Duration get workingDuration {
    final end = logoutAt ?? DateTime.now();
    return end.difference(loginAt);
  }

  factory Attendance.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Attendance(
      id: doc.id,
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String?,
      employeeEmail: data['employeeEmail'] as String?,
      loginAt: (data['loginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      logoutAt: (data['logoutAt'] as Timestamp?)?.toDate(),
      loginLatitude: (data['loginLatitude'] as num?)?.toDouble(),
      loginLongitude: (data['loginLongitude'] as num?)?.toDouble(),
      loginAllowed: data['loginAllowed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'employeeId': employeeId,
    'employeeName': employeeName,
    'employeeEmail': employeeEmail,
    'loginAt': Timestamp.fromDate(loginAt),
    'logoutAt': logoutAt != null ? Timestamp.fromDate(logoutAt!) : null,
    'loginLatitude': loginLatitude,
    'loginLongitude': loginLongitude,
    'loginAllowed': loginAllowed,
  };
}
