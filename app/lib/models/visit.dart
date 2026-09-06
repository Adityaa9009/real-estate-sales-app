import 'package:cloud_firestore/cloud_firestore.dart';

class Visit {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String outsideSalesId;
  final String? outsideSalesName;
  final DateTime scheduledAt;
  final DateTime? reachedAt;
  final DateTime? completedAt;
  final String? recordingPath;
  final String? selfiePath;
  final String status; // scheduled, in_progress, completed
  final String? notes;

  const Visit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.outsideSalesId,
    this.outsideSalesName,
    required this.scheduledAt,
    this.reachedAt,
    this.completedAt,
    this.recordingPath,
    this.selfiePath,
    this.status = 'scheduled',
    this.notes,
  });

  String get maskedPhone {
    if (customerPhone.length <= 4) return customerPhone;
    final lastFour = customerPhone.substring(customerPhone.length - 4);
    final maskedPrefix = '*' * (customerPhone.length - 4);
    return '$maskedPrefix$lastFour';
  }

  factory Visit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Visit(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      customerPhone: data['customerPhone'] as String? ?? '',
      outsideSalesId: data['outsideSalesId'] as String? ?? '',
      outsideSalesName: data['outsideSalesName'] as String?,
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reachedAt: (data['reachedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      recordingPath: data['recordingPath'] as String?,
      selfiePath: data['selfiePath'] as String?,
      status: data['status'] as String? ?? 'scheduled',
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'outsideSalesId': outsideSalesId,
    'outsideSalesName': outsideSalesName,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'reachedAt': reachedAt != null ? Timestamp.fromDate(reachedAt!) : null,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'recordingPath': recordingPath,
    'selfiePath': selfiePath,
    'status': status,
    'notes': notes,
  };
}
