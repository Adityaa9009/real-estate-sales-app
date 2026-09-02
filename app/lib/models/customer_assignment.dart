import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAssignment {
  final String id;
  final String customerId;
  final String? insideSalesId;
  final String? outsideSalesId;
  final Timestamp? visitScheduledAt;
  final String status;

  CustomerAssignment({
    required this.id,
    required this.customerId,
    this.insideSalesId,
    this.outsideSalesId,
    this.visitScheduledAt,
    required this.status,
  });

  factory CustomerAssignment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerAssignment(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      insideSalesId: data['insideSalesId'],
      outsideSalesId: data['outsideSalesId'],
      visitScheduledAt: data['visitScheduledAt'],
      status: data['status'] ?? 'unassigned',
    );
  }
}