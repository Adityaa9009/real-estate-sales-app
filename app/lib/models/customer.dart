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
    CustomerStatus.unassigned => const Color(0xFF94A3B8),
    CustomerStatus.assignedToInsideSales => const Color(0xFF3B82F6),
    CustomerStatus.interested => const Color(0xFF10B981),
    CustomerStatus.notInterested => const Color(0xFFEF4444),
    CustomerStatus.visitScheduled => const Color(0xFFF59E0B),
    CustomerStatus.visitInProgress => const Color(0xFF8B5CF6),
    CustomerStatus.visitCompleted => const Color(0xFF059669),
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
  final String phone;
  final String? email;
  final CustomerStatus status;
  final String? assignedInsideSalesId;
  final String? assignedInsideSalesName;
  final String? assignedOutsideSalesId;
  final String? assignedOutsideSalesName;
  final DateTime? createdAt;
  final String? propertyNotes;
  final String? budget;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.status = CustomerStatus.unassigned,
    this.assignedInsideSalesId,
    this.assignedInsideSalesName,
    this.assignedOutsideSalesId,
    this.assignedOutsideSalesName,
    this.createdAt,
    this.propertyNotes,
    this.budget,
  });

  /// Masks all digits except the last 4 (e.g. '******4285')
  String get maskedPhone {
    if (phone.length <= 4) return phone;
    final lastFour = phone.substring(phone.length - 4);
    final maskedPrefix = '*' * (phone.length - 4);
    return '$maskedPrefix$lastFour';
  }

  factory Customer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdTimestamp = data['createdAt'] as Timestamp?;

    return Customer(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Customer',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      status: CustomerStatus.fromString(data['status'] as String?),
      assignedInsideSalesId: data['assignedInsideSalesId'] as String?,
      assignedInsideSalesName: data['assignedInsideSalesName'] as String?,
      assignedOutsideSalesId: data['assignedOutsideSalesId'] as String?,
      assignedOutsideSalesName: data['assignedOutsideSalesName'] as String?,
      createdAt: createdTimestamp?.toDate(),
      propertyNotes: data['propertyNotes'] as String?,
      budget: data['budget'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phone': phone,
    'email': email,
    'status': status.firestoreValue,
    'assignedInsideSalesId': assignedInsideSalesId,
    'assignedInsideSalesName': assignedInsideSalesName,
    'assignedOutsideSalesId': assignedOutsideSalesId,
    'assignedOutsideSalesName': assignedOutsideSalesName,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    if (propertyNotes != null) 'propertyNotes': propertyNotes,
    if (budget != null) 'budget': budget,
  };
}
