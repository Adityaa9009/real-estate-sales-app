import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum CustomerStatus {
  unassigned,
  assignedToInsideSales,
  interested,
  notInterested,
  visitScheduled,
  visitInProgress,
  visitCompleted;

  String get firestoreValue => switch (this) {
    CustomerStatus.unassigned => 'unassigned',
    CustomerStatus.assignedToInsideSales => 'assigned_to_inside_sales',
    CustomerStatus.interested => 'interested',
    CustomerStatus.notInterested => 'not_interested',
    CustomerStatus.visitScheduled => 'visit_scheduled',
    CustomerStatus.visitInProgress => 'visit_in_progress',
    CustomerStatus.visitCompleted => 'visit_completed',
  };

  String get label => switch (this) {
    CustomerStatus.unassigned => 'Unassigned',
    CustomerStatus.assignedToInsideSales => 'Assigned',
    CustomerStatus.interested => 'Interested',
    CustomerStatus.notInterested => 'Not Interested',
    CustomerStatus.visitScheduled => 'Visit Scheduled',
    CustomerStatus.visitInProgress => 'In Progress',
    CustomerStatus.visitCompleted => 'Completed',
  };

  Color get color => switch (this) {
    CustomerStatus.unassigned => const Color(0xFF8A9099),
    CustomerStatus.assignedToInsideSales => const Color(0xFF3D8BFF),
    CustomerStatus.interested => const Color(0xFF1FA971),
    CustomerStatus.notInterested => const Color(0xFFE0294B),
    CustomerStatus.visitScheduled => const Color(0xFFFFC043),
    CustomerStatus.visitInProgress => const Color(0xFF7C5CFC),
    CustomerStatus.visitCompleted => const Color(0xFF1FA971),
  };

  static CustomerStatus fromString(String? value) => switch (value) {
    'unassigned' => CustomerStatus.unassigned,
    'assigned_to_inside_sales' => CustomerStatus.assignedToInsideSales,
    'interested' => CustomerStatus.interested,
    'not_interested' => CustomerStatus.notInterested,
    'visit_scheduled' => CustomerStatus.visitScheduled,
    'visit_in_progress' => CustomerStatus.visitInProgress,
    'visit_completed' => CustomerStatus.visitCompleted,
    _ => CustomerStatus.unassigned,
  };
}

class Customer {
  final String id;
  final String name;
  final String maskedPhone;
  final String? email;
  final CustomerStatus status;
  final String? assignedInsideSalesId;
  final String? assignedInsideSalesName;
  final String? assignedOutsideSalesId;
  final String? assignedOutsideSalesName;
  final String? activeVisitId;
  final DateTime? createdAt;
  final String? propertyNotes;
  final String? budget;

  const Customer({
    required this.id,
    required this.name,
    required this.maskedPhone,
    this.email,
    this.status = CustomerStatus.unassigned,
    this.assignedInsideSalesId,
    this.assignedInsideSalesName,
    this.assignedOutsideSalesId,
    this.assignedOutsideSalesName,
    this.activeVisitId,
    this.createdAt,
    this.propertyNotes,
    this.budget,
  });

  /// Deprecated convenience getter to avoid breaking views expecting .phone
  String get phone => maskedPhone;

  static String maskPhoneNumber(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final cleaned = raw.trim();
    if (cleaned.length <= 4) return cleaned;
    final lastFour = cleaned.substring(cleaned.length - 4);
    final prefix = '*' * (cleaned.length - 4);
    return '$prefix$lastFour';
  }

  factory Customer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdTimestamp = data['createdAt'] as Timestamp?;

    final existingMasked = data['maskedPhone'] as String?;
    final legacyPhone = data['phone'] as String?;
    final masked = existingMasked ?? maskPhoneNumber(legacyPhone);

    return Customer(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Customer',
      maskedPhone: masked,
      email: data['email'] as String?,
      status: CustomerStatus.fromString(data['status'] as String?),
      assignedInsideSalesId: data['assignedInsideSalesId'] as String?,
      assignedInsideSalesName: data['assignedInsideSalesName'] as String?,
      assignedOutsideSalesId: data['assignedOutsideSalesId'] as String?,
      assignedOutsideSalesName: data['assignedOutsideSalesName'] as String?,
      activeVisitId: data['activeVisitId'] as String?,
      createdAt: createdTimestamp?.toDate(),
      propertyNotes: data['propertyNotes'] as String?,
      budget: data['budget'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'maskedPhone': maskedPhone,
    if (email != null) 'email': email,
    'status': status.firestoreValue,
    if (assignedInsideSalesId != null)
      'assignedInsideSalesId': assignedInsideSalesId,
    if (assignedInsideSalesName != null)
      'assignedInsideSalesName': assignedInsideSalesName,
    if (assignedOutsideSalesId != null)
      'assignedOutsideSalesId': assignedOutsideSalesId,
    if (assignedOutsideSalesName != null)
      'assignedOutsideSalesName': assignedOutsideSalesName,
    if (activeVisitId != null) 'activeVisitId': activeVisitId,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    if (propertyNotes != null) 'propertyNotes': propertyNotes,
    if (budget != null) 'budget': budget,
  };
}
