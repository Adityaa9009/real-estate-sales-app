import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitStatus {
  visitScheduled,
  visitInProgress,
  visitCompleted;

  String get firestoreValue => switch (this) {
    VisitStatus.visitScheduled => 'visit_scheduled',
    VisitStatus.visitInProgress => 'visit_in_progress',
    VisitStatus.visitCompleted => 'visit_completed',
  };

  String get label => switch (this) {
    VisitStatus.visitScheduled => 'Scheduled',
    VisitStatus.visitInProgress => 'In Progress',
    VisitStatus.visitCompleted => 'Completed',
  };

  static VisitStatus fromString(String? val) => switch (val) {
    'visit_scheduled' || 'scheduled' => VisitStatus.visitScheduled,
    'visit_in_progress' || 'in_progress' => VisitStatus.visitInProgress,
    'visit_completed' || 'completed' => VisitStatus.visitCompleted,
    _ => VisitStatus.visitScheduled,
  };
}

class Visit {
  final String id;
  final String customerId;
  final String customerName;
  final String maskedPhone;
  final String insideSalesId;
  final String? insideSalesName;
  final String outsideSalesId;
  final String? outsideSalesName;
  final DateTime scheduledAt;
  final DateTime? reachedAt;
  final DateTime? completedAt;
  final VisitStatus status;
  final String? notes;
  final DateTime? createdAt;

  const Visit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.maskedPhone,
    required this.insideSalesId,
    this.insideSalesName,
    required this.outsideSalesId,
    this.outsideSalesName,
    required this.scheduledAt,
    this.reachedAt,
    this.completedAt,
    this.status = VisitStatus.visitScheduled,
    this.notes,
    this.createdAt,
  });

  /// Deprecated convenience getter returning masked phone
  String get customerPhone => maskedPhone;

  static String maskPhoneNumber(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final cleaned = raw.trim();
    if (cleaned.length <= 4) return cleaned;
    final lastFour = cleaned.substring(cleaned.length - 4);
    final prefix = '*' * (cleaned.length - 4);
    return '$prefix$lastFour';
  }

  factory Visit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final existingMasked = data['maskedPhone'] as String?;
    final legacyPhone =
        data['customerPhone'] as String? ?? data['phone'] as String?;
    final masked = existingMasked ?? maskPhoneNumber(legacyPhone);

    return Visit(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      maskedPhone: masked,
      insideSalesId: data['insideSalesId'] as String? ?? '',
      insideSalesName: data['insideSalesName'] as String?,
      outsideSalesId: data['outsideSalesId'] as String? ?? '',
      outsideSalesName: data['outsideSalesName'] as String?,
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reachedAt: (data['reachedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      status: VisitStatus.fromString(data['status'] as String?),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'maskedPhone': maskedPhone,
    'insideSalesId': insideSalesId,
    if (insideSalesName != null) 'insideSalesName': insideSalesName,
    'outsideSalesId': outsideSalesId,
    if (outsideSalesName != null) 'outsideSalesName': outsideSalesName,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    if (reachedAt != null) 'reachedAt': Timestamp.fromDate(reachedAt!),
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    'status': status.firestoreValue,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
