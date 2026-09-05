import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAssignment {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? insideSalesId;
  final String? insideSalesName;
  final String? outsideSalesId;
  final String? outsideSalesName;
  final String assignedBy;
  final DateTime? visitScheduledAt;
  final String status;
  final DateTime? createdAt;

  const CustomerAssignment({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.insideSalesId,
    this.insideSalesName,
    this.outsideSalesId,
    this.outsideSalesName,
    required this.assignedBy,
    this.visitScheduledAt,
    this.status = 'active',
    this.createdAt,
  });

  factory CustomerAssignment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final scheduledTimestamp = data['visitScheduledAt'] as Timestamp?;
    final createdTimestamp = data['createdAt'] as Timestamp?;

    return CustomerAssignment(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      insideSalesId: data['insideSalesId'] as String?,
      insideSalesName: data['insideSalesName'] as String?,
      outsideSalesId: data['outsideSalesId'] as String?,
      outsideSalesName: data['outsideSalesName'] as String?,
      assignedBy: data['assignedBy'] as String? ?? 'system',
      visitScheduledAt: scheduledTimestamp?.toDate(),
      status: data['status'] as String? ?? 'active',
      createdAt: createdTimestamp?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'insideSalesId': insideSalesId,
    'insideSalesName': insideSalesName,
    'outsideSalesId': outsideSalesId,
    'outsideSalesName': outsideSalesName,
    'assignedBy': assignedBy,
    'visitScheduledAt': visitScheduledAt != null ? Timestamp.fromDate(visitScheduledAt!) : null,
    'status': status,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };
}
