/// Mirrors the `customer_assignments` collection in docs/DATABASE_SCHEMA.md
class CustomerAssignment {
  final String customerId;
  final String? insideSalesId;
  final String? outsideSalesId;
  final String assignedBy; // executive/admin employee id
  final DateTime? visitScheduledAt;
  final String status;
  final DateTime createdAt;

  CustomerAssignment({
    required this.customerId,
    this.insideSalesId,
    this.outsideSalesId,
    required this.assignedBy,
    this.visitScheduledAt,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'insideSalesId': insideSalesId,
      'outsideSalesId': outsideSalesId,
      'assignedBy': assignedBy,
      'visitScheduledAt': visitScheduledAt?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
